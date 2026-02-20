//
//  OrderDetailView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @ObservedObject var orderViewModel: OrderViewModel

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }

    var body: some View {
        List {
            Section("Bestelldetails") {
                HStack {
                    Text("Datum")
                    Spacer()
                    Text(dateFormatter.string(from: order.date ?? Date()))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Status")
                    Spacer()
                    Text(order.status ?? "Unbekannt")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }

            Section("Produkte") {
                ForEach(orderViewModel.orderItems(for: order), id: \.id) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.productName ?? "")
                                .font(.body)
                            if item.quantity == 1 {
                                Text("Unikat")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Menge: \(item.quantity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        let itemTotal = item.priceAtPurchase * Double(item.quantity)
                        VStack(alignment: .trailing) {
                            Text(currencyFormatter.string(from: NSNumber(value: itemTotal)) ?? "")
                                .fontWeight(.medium)
                            if item.quantity > 1 {
                                Text("je \(currencyFormatter.string(from: NSNumber(value: item.priceAtPurchase)) ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("Gesamtbetrag")
                        .font(.headline)
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: order.totalAmount)) ?? "")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .navigationTitle("Bestellung")
        .navigationBarTitleDisplayMode(.inline)
    }
}
