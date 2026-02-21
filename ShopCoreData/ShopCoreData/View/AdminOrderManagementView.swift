//
//  AdminOrderManagementView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI

struct AdminOrderManagementView: View {
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
        List {
            if orderViewModel.orders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(.gallerySecondaryText)
                    Text("Keine Bestellungen vorhanden")
                        .font(.galleryBody)
                        .foregroundColor(.gallerySecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.galleryBackground)
            } else {
                ForEach(orderViewModel.orders, id: \.id) { order in
                    NavigationLink(destination: AdminOrderDetailView(order: order, orderViewModel: orderViewModel)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(order.firstName ?? "") \(order.lastName ?? "")")
                                    .font(.galleryBody)
                                    .fontWeight(.medium)
                                    .foregroundColor(.softWhite)

                                Text(dateFormatter.string(from: order.date ?? Date()))
                                    .font(.galleryCaption)
                                    .foregroundColor(.gallerySecondaryText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(currencyFormatter.string(from: NSNumber(value: order.totalAmount)) ?? "")
                                    .fontWeight(.medium)
                                    .foregroundColor(.softWhite)

                                statusBadge(for: order)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.galleryPanel)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.galleryBackground)
        .navigationTitle("Bestellungen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            orderViewModel.fetchOrders()
        }
    }

    @ViewBuilder
    private func statusBadge(for order: Order) -> some View {
        let status = order.status ?? "Bestellt"
        let hasTracking = order.trackingNumber != nil && !(order.trackingNumber?.isEmpty ?? true)

        Text(status)
            .font(.galleryCaption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(hasTracking ? Color.galleryAvailable.opacity(0.2) : Color.oxidCopper.opacity(0.2))
            .foregroundColor(hasTracking ? .galleryAvailable : .oxidCopper)
            .cornerRadius(4)
    }
}

// MARK: - Admin Bestelldetail mit Tracking-Eingabe

struct AdminOrderDetailView: View {
    let order: Order
    @ObservedObject var orderViewModel: OrderViewModel

    @State private var carrier = "DHL"
    @State private var trackingNumber = ""
    @State private var showSavedConfirmation = false

    private let carriers = ["DHL", "DPD", "Hermes", "GLS", "UPS"]

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
            // Kundendaten
            Section("Kunde") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(order.firstName ?? "") \(order.lastName ?? "")")
                        .fontWeight(.medium)
                        .foregroundColor(.softWhite)
                    if let street = order.street {
                        Text(street)
                            .foregroundColor(.gallerySecondaryText)
                    }
                    Text("\(order.zip ?? "") \(order.city ?? "")")
                        .foregroundColor(.gallerySecondaryText)
                    if let email = order.email {
                        Text(email)
                            .foregroundColor(.smokyQuartz)
                    }
                    if let phone = order.phone, !phone.isEmpty {
                        Text(phone)
                            .foregroundColor(.gallerySecondaryText)
                    }
                }
                .font(.galleryBody)
                .listRowBackground(Color.galleryPanel)
            }

            // Bestellinfo
            Section("Bestellung") {
                HStack {
                    Text("Datum")
                        .foregroundColor(.gallerySecondaryText)
                    Spacer()
                    Text(dateFormatter.string(from: order.date ?? Date()))
                        .foregroundColor(.softWhite)
                }
                .listRowBackground(Color.galleryPanel)

                HStack {
                    Text("Betrag")
                        .foregroundColor(.gallerySecondaryText)
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: order.totalAmount)) ?? "")
                        .fontWeight(.medium)
                        .foregroundColor(.smokyQuartz)
                }
                .listRowBackground(Color.galleryPanel)

                if let couponCode = order.couponCode, !couponCode.isEmpty {
                    HStack {
                        Text("Gutschein")
                            .foregroundColor(.gallerySecondaryText)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(couponCode)
                                .font(.galleryMono)
                                .foregroundColor(.galleryAvailable)
                            Text("(-\(currencyFormatter.string(from: NSNumber(value: order.discountAmount)) ?? ""))")
                                .foregroundColor(.galleryAvailable)
                        }
                    }
                    .listRowBackground(Color.galleryPanel)
                }

                HStack {
                    Text("Status")
                        .foregroundColor(.gallerySecondaryText)
                    Spacer()
                    Text(order.status ?? "Bestellt")
                        .foregroundColor(.oxidCopper)
                }
                .listRowBackground(Color.galleryPanel)
            }

            // Produkte
            Section("Produkte") {
                ForEach(orderViewModel.orderItems(for: order), id: \.id) { item in
                    HStack {
                        Text(item.productName ?? "")
                            .foregroundColor(.softWhite)
                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .foregroundColor(.gallerySecondaryText)
                        }
                        Spacer()
                        Text(currencyFormatter.string(from: NSNumber(value: item.priceAtPurchase * Double(item.quantity))) ?? "")
                            .foregroundColor(.softWhite)
                    }
                    .listRowBackground(Color.galleryPanel)
                }
            }

            // Versandverfolgung
            Section("Versandverfolgung") {
                Picker("Versanddienstleister", selection: $carrier) {
                    ForEach(carriers, id: \.self) { c in
                        Text(c).tag(c)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(.softWhite)
                .tint(.smokyQuartz)
                .listRowBackground(Color.galleryPanel)

                HStack {
                    Image(systemName: "barcode")
                        .foregroundColor(.gallerySecondaryText)
                    TextField("Sendungsnummer", text: $trackingNumber)
                        .foregroundColor(.softWhite)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }
                .listRowBackground(Color.galleryPanel)

                Button {
                    orderViewModel.updateTracking(for: order, carrier: carrier, trackingNumber: trackingNumber)
                    showSavedConfirmation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSavedConfirmation = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "shippingbox")
                        Text(showSavedConfirmation ? "Gespeichert!" : "Tracking speichern")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .foregroundColor(trackingNumber.isEmpty ? .gallerySecondaryText : (showSavedConfirmation ? .galleryAvailable : .smokyQuartz))
                }
                .disabled(trackingNumber.isEmpty)
                .listRowBackground(Color.galleryPanel)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.galleryBackground)
        .navigationTitle("Bestellung bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Bestehende Tracking-Daten laden
            if let existingCarrier = order.shippingCarrier, !existingCarrier.isEmpty {
                carrier = existingCarrier
            }
            if let existingTracking = order.trackingNumber {
                trackingNumber = existingTracking
            }
        }
    }
}
