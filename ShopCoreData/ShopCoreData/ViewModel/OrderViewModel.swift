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

    func placeOrder(
        cartItems: [CartItem],
        totalAmount: Double,
        firstName: String = "",
        lastName: String = "",
        email: String = "",
        phone: String? = nil,
        street: String = "",
        zip: String = "",
        city: String = "",
        couponCode: String? = nil,
        discountAmount: Double = 0
    ) {
        let order = Order(context: store.context)
        order.id = UUID()
        order.date = Date()
        order.totalAmount = totalAmount
        order.status = "Bestellt"
        order.paymentStatus = StripeCheckoutManager.PaymentStatus.pending.rawValue

        // Kundendaten (Gastbestellung)
        order.firstName = firstName
        order.lastName = lastName
        order.email = email
        order.phone = phone
        order.street = street
        order.zip = zip
        order.city = city

        // Gutschein
        order.couponCode = couponCode
        order.discountAmount = discountAmount

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

    // MARK: - Versandverfolgung

    func updateTracking(for order: Order, carrier: String, trackingNumber: String) {
        order.shippingCarrier = carrier
        order.trackingNumber = trackingNumber
        if order.status == "Bestellt" {
            order.status = "Versendet"
        }
        if !store.save() {
            errorMessage = "Tracking konnte nicht gespeichert werden."
        }
        fetchOrders()
    }

    func trackingURL(for order: Order) -> URL? {
        guard let number = order.trackingNumber, !number.isEmpty,
              let carrier = order.shippingCarrier else { return nil }

        switch carrier.lowercased() {
        case "dhl":
            return URL(string: "https://www.dhl.de/de/privatkunden/pakete-empfangen/verfolgen.html?piececode=\(number)")
        case "dpd":
            return URL(string: "https://tracking.dpd.de/status/de_DE/parcel/\(number)")
        case "hermes":
            return URL(string: "https://www.myhermes.de/empfangen/sendungsverfolgung/sendungsinformation/#\(number)")
        case "gls":
            return URL(string: "https://gls-group.com/DE/de/paketverfolgung?match=\(number)")
        case "ups":
            return URL(string: "https://www.ups.com/track?tracknum=\(number)&loc=de_DE")
        default:
            return nil
        }
    }

    func orderItems(for order: Order) -> [OrderItem] {
        guard let items = order.items as? Set<OrderItem> else { return [] }
        return items.sorted { ($0.productName ?? "") < ($1.productName ?? "") }
    }
}
