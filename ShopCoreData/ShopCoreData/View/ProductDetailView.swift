//
//  ProductDetailView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var cartViewModel: CartViewModel
    @State private var showAddedFeedback = false

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Produktbild (SF Symbol als Platzhalter)
                Image(systemName: product.imageName ?? "shippingbox")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    // Kategorie
                    if let categoryName = product.category?.name {
                        Text(categoryName.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }

                    // Name und Preis
                    Text(product.name ?? "")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(currencyFormatter.string(from: NSNumber(value: product.price)) ?? "")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)

                    // Verfügbarkeit
                    HStack {
                        Circle()
                            .fill(product.quantity > 0 ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(product.quantity > 0
                             ? "\(product.quantity) Stück verfügbar"
                             : "Nicht verfügbar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Beschreibung
                    Text("Beschreibung")
                        .font(.headline)

                    Text(product.productDescription ?? "Keine Beschreibung verfügbar.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)

                // In den Warenkorb Button
                Button(action: {
                    cartViewModel.addToCart(product: product)
                    showAddedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showAddedFeedback = false
                    }
                }) {
                    HStack {
                        Image(systemName: showAddedFeedback ? "checkmark" : "cart.badge.plus")
                        Text(showAddedFeedback ? "Hinzugefügt!" : "In den Warenkorb")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(product.quantity > 0 ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(product.quantity <= 0)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(product.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}
