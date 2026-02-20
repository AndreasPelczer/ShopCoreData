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
                            .foregroundColor(.secondary)
                        Text("Dein Warenkorb ist leer")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Füge Produkte aus der Produktliste hinzu.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    cartViewModel.removeFromCart(cartItem: cartViewModel.cartItems[index])
                                }
                            }
                        }
                        .listStyle(.plain)

                        // Gesamtpreis und Bestellen
                        VStack(spacing: 12) {
                            Divider()

                            HStack {
                                Text("Gesamt (\(cartViewModel.totalItemCount) Artikel)")
                                    .font(.body)
                                Spacer()
                                Text(currencyFormatter.string(from: NSNumber(value: cartViewModel.totalPrice)) ?? "")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
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
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .background(Color(.systemBackground))
                    }
                }
            }
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
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.product?.name ?? "")
                    .font(.body)
                    .fontWeight(.medium)

                let itemTotal = (item.product?.price ?? 0) * Double(item.quantity)
                Text(currencyFormatter.string(from: NSNumber(value: itemTotal)) ?? "")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }

            Spacer()

            // Mengensteuerung
            HStack(spacing: 12) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                }

                Text("\(item.quantity)")
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(minWidth: 24)

                Button(action: onIncrease) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
                .disabled(item.product?.quantity ?? 0 <= 0)
            }
            .foregroundColor(.accentColor)
        }
        .padding(.vertical, 4)
    }
}
