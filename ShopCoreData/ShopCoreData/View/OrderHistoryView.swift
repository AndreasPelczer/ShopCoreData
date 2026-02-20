//
//  OrderHistoryView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct OrderHistoryView: View {
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
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        NavigationView {
            Group {
                if orderViewModel.orders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Noch keine Bestellungen")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Deine erworbenen Unikate erscheinen hier.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(orderViewModel.orders, id: \.id) { order in
                        NavigationLink(destination: OrderDetailView(order: order, orderViewModel: orderViewModel)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dateFormatter.string(from: order.date ?? Date()))
                                        .font(.body)
                                        .fontWeight(.medium)

                                    let itemCount = (order.items as? Set<OrderItem>)?.count ?? 0
                                    Text("\(itemCount) \(itemCount == 1 ? "Stück" : "Stücke")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(currencyFormatter.string(from: NSNumber(value: order.totalAmount)) ?? "")
                                        .fontWeight(.semibold)

                                    Text(order.status ?? "")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Bestellungen")
            .onAppear {
                orderViewModel.fetchOrders()
            }
            .alert("Fehler", isPresented: Binding(
                get: { orderViewModel.errorMessage != nil },
                set: { if !$0 { orderViewModel.errorMessage = nil } }
            )) {
                Button("OK") { orderViewModel.errorMessage = nil }
            } message: {
                Text(orderViewModel.errorMessage ?? "")
            }
        }
    }
}
