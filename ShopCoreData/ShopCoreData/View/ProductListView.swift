//
//  ProductListView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ProductListView: View {
    @ObservedObject var viewModel: ProductViewModel
    @ObservedObject var cartViewModel: CartViewModel

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Kategorie-Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(
                            name: "Alle",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(viewModel.categories, id: \.id) { category in
                            CategoryChip(
                                name: category.name ?? "",
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Produktliste
                List(viewModel.filteredProducts, id: \.id) { product in
                    NavigationLink(destination: ProductDetailView(product: product, cartViewModel: cartViewModel)) {
                        ProductRow(product: product, currencyFormatter: currencyFormatter)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Pelczer Bongs")
            .searchable(text: $viewModel.searchText, prompt: "Produkt suchen...")
            .onAppear {
                viewModel.fetchProducts()
            }
            .alert("Fehler", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Subviews

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ProductRow: View {
    let product: Product
    let currencyFormatter: NumberFormatter

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: product.imageName ?? "shippingbox")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(product.name ?? "")
                        .font(.body)
                        .fontWeight(.medium)

                    if product.isUnique {
                        Text("UNIKAT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(3)
                    }
                }

                HStack(spacing: 4) {
                    if let categoryName = product.category?.name {
                        Text(categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let artist = product.artist, !artist.isEmpty {
                        Text("· \(artist)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(currencyFormatter.string(from: NSNumber(value: product.price)) ?? "")
                    .fontWeight(.semibold)

                Text(product.quantity > 0 ? "Verfügbar" : "Verkauft")
                    .font(.caption)
                    .foregroundColor(product.quantity > 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}
