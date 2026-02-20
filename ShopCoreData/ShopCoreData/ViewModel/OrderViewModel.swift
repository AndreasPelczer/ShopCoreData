//
//  OrderViewModel.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import Foundation
import CoreData

class OrderViewModel: ObservableObject {

    @Published var orders: [Order] = []
    @Published var errorMessage: String?

    let store: PersistentStore

    init(store: PersistentStore = .shared) {
        self.store = store
        fetchOrders()
    }

    func fetchOrders() {
        let request = NSFetchRequest<Order>(entityName: "Order")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            orders = try store.context.fetch(request)
            errorMessage = nil
        } catch {
            errorMessage = "Bestellungen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    func placeOrder(cartItems: [CartItem], totalAmount: Double) {
        let order = Order(context: store.context)
        order.id = UUID()
        order.date = Date()
        order.totalAmount = totalAmount
        order.status = "Bestellt"

        for cartItem in cartItems {
            let orderItem = OrderItem(context: store.context)
            orderItem.id = UUID()
            orderItem.quantity = cartItem.quantity
            orderItem.priceAtPurchase = cartItem.product?.price ?? 0
            orderItem.productName = cartItem.product?.name ?? "Unbekannt"
            orderItem.order = order
        }

        if !store.save() {
            errorMessage = "Bestellung konnte nicht gespeichert werden."
        }
        fetchOrders()
    }

    func orderItems(for order: Order) -> [OrderItem] {
        guard let items = order.items as? Set<OrderItem> else { return [] }
        return items.sorted { ($0.productName ?? "") < ($1.productName ?? "") }
    }
}
