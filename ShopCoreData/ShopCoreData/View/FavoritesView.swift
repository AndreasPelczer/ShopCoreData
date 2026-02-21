//
//  FavoritesView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI

/// Zeigt die Wunschliste des Kunden — alle Produkte die als Favorit markiert sind.
struct FavoritesView: View {
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
            Group {
                if viewModel.favoriteProducts.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .background(Color.galleryBackground)
            .navigationTitle("Wunschliste")
        }
    }

    // MARK: - Leere Wunschliste

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(.gallerySecondaryText.opacity(0.5))

            Text("Noch keine Favoriten")
                .font(.gallerySubtitle)
                .foregroundColor(.gallerySecondaryText)

            Text("Tippe auf das Herz bei einem Produkt,\num es hier zu speichern.")
                .font(.galleryBody)
                .foregroundColor(.gallerySecondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.galleryBackground)
    }

    // MARK: - Favoritenliste

    private var favoritesList: some View {
        List {
            ForEach(viewModel.favoriteProducts, id: \.id) { product in
                NavigationLink(destination: ProductDetailView(product: product, cartViewModel: cartViewModel, productViewModel: viewModel)) {
                    HStack(spacing: 12) {
                        ProductThumbnailView(product: product, size: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name ?? "")
                                .font(.galleryBody)
                                .fontWeight(.medium)
                                .foregroundColor(.softWhite)

                            if let categoryName = product.category?.name {
                                Text(categoryName)
                                    .font(.galleryCaption)
                                    .foregroundColor(.gallerySecondaryText)
                            }

                            Text(currencyFormatter.string(from: NSNumber(value: product.price)) ?? "")
                                .font(.galleryBody)
                                .foregroundColor(.smokyQuartz)
                        }

                        Spacer()

                        // Verfügbarkeits-Status
                        VStack(spacing: 4) {
                            Button {
                                withAnimation {
                                    viewModel.toggleFavorite(product)
                                }
                            } label: {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.gallerySold)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)

                            Text(product.quantity > 0 ? "Verfügbar" : "Verkauft")
                                .font(.galleryBadge)
                                .foregroundColor(product.quantity > 0 ? .galleryAvailable : .gallerySold)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.galleryBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
