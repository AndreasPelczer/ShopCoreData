//
//  CheckoutView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct CheckoutView: View {
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var orderViewModel: OrderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var orderPlaced = false

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        NavigationView {
            if orderPlaced {
                // Bestellbestätigung
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.galleryAvailable)

                    Text("Bestellung aufgegeben!")
                        .font(.galleryTitle)
                        .foregroundColor(.softWhite)

                    Text("Deine Bestellung wurde aufgegeben. Dein Unikat wird sorgfältig verpackt.")
                        .font(.galleryBody)
                        .foregroundColor(.gallerySecondaryText)
                        .multilineTextAlignment(.center)

                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.smokyQuartz)
                    .foregroundColor(.galleryBackground)
                    .cornerRadius(10)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.galleryBackground)
            } else {
                // Bestellübersicht
                List {
                    Section("Produkte") {
                        ForEach(cartViewModel.cartItems, id: \.id) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.product?.name ?? "")
                                        .font(.galleryBody)
                                        .foregroundColor(.softWhite)
                                    if item.product?.isUnique == true {
                                        Text("Unikat")
                                            .font(.galleryCaption)
                                            .foregroundColor(.mutedAmber)
                                    } else {
                                        Text("Menge: \(item.quantity)")
                                            .font(.galleryCaption)
                                            .foregroundColor(.gallerySecondaryText)
                                    }
                                }

                                Spacer()

                                let itemTotal = (item.product?.price ?? 0) * Double(item.quantity)
                                Text(currencyFormatter.string(from: NSNumber(value: itemTotal)) ?? "")
                                    .fontWeight(.medium)
                                    .foregroundColor(.softWhite)
                            }
                            .listRowBackground(Color.galleryPanel)
                        }
                    }

                    Section {
                        HStack {
                            Text("Gesamt")
                                .font(.gallerySubtitle)
                                .foregroundColor(.softWhite)
                            Spacer()
                            Text(currencyFormatter.string(from: NSNumber(value: cartViewModel.totalPrice)) ?? "")
                                .font(.gallerySubtitle)
                                .foregroundColor(.smokyQuartz)
                        }
                        .listRowBackground(Color.galleryPanel)
                    }

                    Section {
                        Button(action: placeOrder) {
                            HStack {
                                Spacer()
                                Image(systemName: "creditcard")
                                Text("Jetzt bestellen")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .foregroundColor(.galleryBackground)
                        .listRowBackground(Color.smokyQuartz)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.galleryBackground)
                .navigationTitle("Bestellung")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(.smokyQuartz)
                    }
                }
            }
        }
    }

    private func placeOrder() {
        // Create order BEFORE clearing the cart to avoid accessing deleted managed objects
        orderViewModel.placeOrder(cartItems: cartViewModel.cartItems, totalAmount: cartViewModel.totalPrice)
        _ = cartViewModel.clearCart()
        orderPlaced = true
    }
}
