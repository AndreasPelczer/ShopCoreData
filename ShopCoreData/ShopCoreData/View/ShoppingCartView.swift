//
//  ShoppingCartView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ShoppingCartView: View {
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var orderViewModel: OrderViewModel
    @State private var showCheckout = false

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        NavigationView {
            Group {
                if cartViewModel.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gallerySecondaryText)
                        Text("Dein Warenkorb ist leer")
                            .font(.gallerySubtitle)
                            .foregroundColor(.gallerySecondaryText)
                        Text("Entdecke einzigartige Bongs in der Galerie.")
                            .font(.gallerySubheadline)
                            .foregroundColor(.gallerySecondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.galleryBackground)
                } else {
                    VStack(spacing: 0) {
                        List {
                            ForEach(cartViewModel.cartItems, id: \.id) { item in
                                CartItemRow(
                                    item: item,
                                    currencyFormatter: currencyFormatter,
                                    onIncrease: { cartViewModel.increaseQuantity(cartItem: item) },
                                    onDecrease: { cartViewModel.decreaseQuantity(cartItem: item) }
                                )
                                .listRowBackground(Color.galleryBackground)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    cartViewModel.removeFromCart(cartItem: cartViewModel.cartItems[index])
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.galleryBackground)

                        // Gesamtpreis und Bestellen
                        VStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.galleryDivider)
                                .frame(height: 1)

                            HStack {
                                Text("Gesamt (\(cartViewModel.totalItemCount) \(cartViewModel.totalItemCount == 1 ? "Stück" : "Stücke"))")
                                    .font(.galleryBody)
                                    .foregroundColor(.softWhite)
                                Spacer()
                                Text(currencyFormatter.string(from: NSNumber(value: cartViewModel.totalPrice)) ?? "")
                                    .font(.gallerySubtitle)
                                    .foregroundColor(.smokyQuartz)
                            }
                            .padding(.horizontal)

                            Button(action: { showCheckout = true }) {
                                HStack {
                                    Image(systemName: "creditcard")
                                    Text("Zur Kasse")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.smokyQuartz)
                                .foregroundColor(.galleryBackground)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .background(Color.galleryPanel)
                    }
                }
            }
            .background(Color.galleryBackground)
            .navigationTitle("Warenkorb")
            .sheet(isPresented: $showCheckout) {
                CheckoutView(cartViewModel: cartViewModel, orderViewModel: orderViewModel)
            }
            .onAppear {
                cartViewModel.fetchCartItems()
            }
            .alert("Fehler", isPresented: Binding(
                get: { cartViewModel.errorMessage != nil },
                set: { if !$0 { cartViewModel.errorMessage = nil } }
            )) {
                Button("OK") { cartViewModel.errorMessage = nil }
            } message: {
                Text(cartViewModel.errorMessage ?? "")
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    let currencyFormatter: NumberFormatter
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.product?.imageName ?? "shippingbox")
                .font(.title3)
                .foregroundColor(.smokyQuartz)
                .frame(width: 44, height: 44)
                .background(Color.galleryPanel)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.product?.name ?? "")
                        .font(.galleryBody)
                        .fontWeight(.medium)
                        .foregroundColor(.softWhite)

                    if item.product?.isUnique == true {
                        Text("UNIKAT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.galleryBackground)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.mutedAmber)
                            .cornerRadius(2)
                    }
                }

                let itemTotal = (item.product?.price ?? 0) * Double(item.quantity)
                Text(currencyFormatter.string(from: NSNumber(value: itemTotal)) ?? "")
                    .font(.gallerySubheadline)
                    .foregroundColor(.smokyQuartz)
            }

            Spacer()

            if item.product?.isUnique == true {
                // Unikate: nur Entfernen
                Button(action: onDecrease) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.gallerySold)
                }
            } else {
                // Mengensteuerung für Nicht-Unikate
                HStack(spacing: 12) {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle")
                            .font(.title3)
                    }

                    Text("\(item.quantity)")
                        .font(.galleryBody)
                        .fontWeight(.medium)
                        .foregroundColor(.softWhite)
                        .frame(minWidth: 24)

                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                    }
                    .disabled(item.product?.quantity ?? 0 <= 0)
                }
                .foregroundColor(.smokyQuartz)
            }
        }
        .padding(.vertical, 4)
    }
}
