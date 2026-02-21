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
                        .foregroundColor(.gallerySecondaryText)
                    Spacer()
                    Text(dateFormatter.string(from: order.date ?? Date()))
                        .foregroundColor(.softWhite)
                }
                .listRowBackground(Color.galleryPanel)

                HStack {
                    Text("Status")
                        .foregroundColor(.gallerySecondaryText)
                    Spacer()
                    Text(order.status ?? "Unbekannt")
                        .font(.galleryCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.oxidCopper.opacity(0.2))
                        .foregroundColor(.oxidCopper)
                        .cornerRadius(4)
                }
                .listRowBackground(Color.galleryPanel)

                if let paymentStatus = order.paymentStatus, !paymentStatus.isEmpty {
                    HStack {
                        Text("Zahlung")
                            .foregroundColor(.gallerySecondaryText)
                        Spacer()
                        Text(paymentStatus)
                            .font(.galleryCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(paymentStatus == "Bezahlt" ? Color.galleryAvailable.opacity(0.2) : Color.mutedAmber.opacity(0.2))
                            .foregroundColor(paymentStatus == "Bezahlt" ? .galleryAvailable : .mutedAmber)
                            .cornerRadius(4)
                    }
                    .listRowBackground(Color.galleryPanel)
                }
            }

            // Versandverfolgung
            if let trackingNumber = order.trackingNumber, !trackingNumber.isEmpty {
                Section("Versandverfolgung") {
                    HStack {
                        Text("Dienstleister")
                            .foregroundColor(.gallerySecondaryText)
                        Spacer()
                        Text(order.shippingCarrier ?? "")
                            .foregroundColor(.softWhite)
                    }
                    .listRowBackground(Color.galleryPanel)

                    HStack {
                        Text("Sendungsnummer")
                            .foregroundColor(.gallerySecondaryText)
                        Spacer()
                        Text(trackingNumber)
                            .font(.galleryMono)
                            .foregroundColor(.softWhite)
                    }
                    .listRowBackground(Color.galleryPanel)

                    if let url = orderViewModel.trackingURL(for: order) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "safari")
                                Text("Sendung verfolgen")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundColor(.smokyQuartz)
                        }
                        .listRowBackground(Color.galleryPanel)
                    }
                }
            }

            // Gutschein-Info
            if let couponCode = order.couponCode, !couponCode.isEmpty {
                Section("Gutschein") {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "ticket")
                            Text(couponCode)
                                .font(.galleryMono)
                        }
                        .foregroundColor(.galleryAvailable)
                        Spacer()
                        Text("- \(currencyFormatter.string(from: NSNumber(value: order.discountAmount)) ?? "")")
                            .foregroundColor(.galleryAvailable)
                    }
                    .listRowBackground(Color.galleryPanel)
                }
            }

            // Lieferadresse (nur anzeigen wenn vorhanden)
            if let firstName = order.firstName, !firstName.isEmpty {
                Section("Lieferadresse") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(firstName) \(order.lastName ?? "")")
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
            }

            Section("Produkte") {
                ForEach(orderViewModel.orderItems(for: order), id: \.id) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.productName ?? "")
                                .font(.galleryBody)
                                .foregroundColor(.softWhite)
                            if item.quantity == 1 {
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

                        let itemTotal = item.priceAtPurchase * Double(item.quantity)
                        VStack(alignment: .trailing) {
                            Text(currencyFormatter.string(from: NSNumber(value: itemTotal)) ?? "")
                                .fontWeight(.medium)
                                .foregroundColor(.softWhite)
                            if item.quantity > 1 {
                                Text("je \(currencyFormatter.string(from: NSNumber(value: item.priceAtPurchase)) ?? "")")
                                    .font(.galleryMonoSmall)
                                    .foregroundColor(.gallerySecondaryText)
                            }
                        }
                    }
                    .listRowBackground(Color.galleryPanel)
                }
            }

            Section {
                HStack {
                    Text("Gesamtbetrag")
                        .font(.gallerySubtitle)
                        .foregroundColor(.softWhite)
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: order.totalAmount)) ?? "")
                        .font(.gallerySubtitle)
                        .foregroundColor(.smokyQuartz)
                }
                .listRowBackground(Color.galleryPanel)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.galleryBackground)
        .navigationTitle("Bestellung")
        .navigationBarTitleDisplayMode(.inline)
    }
}
