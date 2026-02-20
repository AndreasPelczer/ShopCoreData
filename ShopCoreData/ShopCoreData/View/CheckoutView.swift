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
                        .foregroundColor(.green)

                    Text("Bestellung aufgegeben!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Deine Bestellung wurde erfolgreich aufgegeben.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Fertig") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                // Bestellübersicht
                List {
                    Section("Artikel") {
                        ForEach(cartViewModel.cartItems, id: \.id) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.product?.name ?? "")
                                        .font(.body)
                                    Text("Menge: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                let itemTotal = (item.product?.price ?? 0) * Double(item.quantity)
                                Text(currencyFormatter.string(from: NSNumber(value: itemTotal)) ?? "")
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    Section {
                        HStack {
                            Text("Gesamt")
                                .font(.headline)
                            Spacer()
                            Text(currencyFormatter.string(from: NSNumber(value: cartViewModel.totalPrice)) ?? "")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
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
                        .foregroundColor(.white)
                        .listRowBackground(Color.accentColor)
                    }
                }
                .navigationTitle("Bestellung")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
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
