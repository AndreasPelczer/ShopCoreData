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
    @ObservedObject var productViewModel: ProductViewModel
    @State private var showAddedFeedback = false

    private var isInCart: Bool {
        cartViewModel.cartItems.contains(where: { $0.product?.id == product.id })
    }

    private var canAddToCart: Bool {
        if product.quantity <= 0 { return false }
        if product.isUnique && isInCart { return false }
        return true
    }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Produktbilder-Galerie
                ProductImageGalleryView(product: product)

                VStack(alignment: .leading, spacing: 12) {
                    // Kategorie & Unikat-Badge
                    HStack(spacing: 8) {
                        if let categoryName = product.category?.name {
                            Text(categoryName.uppercased())
                                .font(.galleryCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gallerySecondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.galleryChipBackground)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.galleryDivider, lineWidth: 1)
                                )
                        }

                        if product.isUnique {
                            Text("UNIKAT")
                                .font(.galleryBadge)
                                .fontWeight(.bold)
                                .foregroundColor(.galleryBackground)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.mutedAmber)
                                .cornerRadius(4)
                        }
                    }

                    // Name und Preis
                    Text(product.name ?? "")
                        .font(.galleryTitle)
                        .foregroundColor(.softWhite)

                    Text(currencyFormatter.string(from: NSNumber(value: product.price)) ?? "")
                        .font(.gallerySubtitle)
                        .foregroundColor(.smokyQuartz)

                    // Verfügbarkeit
                    HStack {
                        Circle()
                            .fill(product.quantity > 0 ? Color.galleryAvailable : Color.gallerySold)
                            .frame(width: 8, height: 8)
                        Text(product.quantity > 0
                             ? "Verfügbar"
                             : "Verkauft")
                            .font(.gallerySubheadline)
                            .foregroundColor(.gallerySecondaryText)
                    }

                    Rectangle()
                        .fill(Color.galleryDivider)
                        .frame(height: 1)

                    // Hersteller & Details
                    Text("Details")
                        .font(.gallerySubtitle)
                        .foregroundColor(.softWhite)

                    VStack(spacing: 8) {
                        if let artist = product.artist, !artist.isEmpty {
                            HStack {
                                Image(systemName: "hammer")
                                    .foregroundColor(.oxidCopper)
                                    .frame(width: 24)
                                Text("Hersteller")
                                    .foregroundColor(.gallerySecondaryText)
                                Spacer()
                                Text(artist)
                                    .fontWeight(.medium)
                                    .foregroundColor(.softWhite)
                            }
                            .font(.galleryMono)
                        }

                        if let material = product.material, !material.isEmpty {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.oxidCopper)
                                    .frame(width: 24)
                                Text("Material")
                                    .foregroundColor(.gallerySecondaryText)
                                Spacer()
                                Text(material)
                                    .fontWeight(.medium)
                                    .foregroundColor(.softWhite)
                            }
                            .font(.galleryMono)
                        }

                        if product.height > 0 {
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(.oxidCopper)
                                    .frame(width: 24)
                                Text("Höhe")
                                    .foregroundColor(.gallerySecondaryText)
                                Spacer()
                                Text(String(format: "%.0f cm", product.height))
                                    .fontWeight(.medium)
                                    .foregroundColor(.softWhite)
                            }
                            .font(.galleryMono)
                        }
                    }

                    Rectangle()
                        .fill(Color.galleryDivider)
                        .frame(height: 1)

                    // Beschreibung
                    Text("Beschreibung")
                        .font(.gallerySubtitle)
                        .foregroundColor(.softWhite)

                    Text(product.productDescription ?? "Keine Beschreibung verfügbar.")
                        .font(.galleryBody)
                        .foregroundColor(.gallerySecondaryText)
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
                        Text(showAddedFeedback
                             ? "Hinzugefügt!"
                             : isInCart
                             ? "Bereits im Warenkorb"
                             : "In den Warenkorb")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canAddToCart ? Color.smokyQuartz : Color.gallerySecondaryText.opacity(0.3))
                    .foregroundColor(canAddToCart ? .galleryBackground : .gallerySecondaryText)
                    .cornerRadius(12)
                }
                .disabled(!canAddToCart)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.galleryBackground)
        .navigationTitle(product.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            productViewModel.toggleFavorite(product)
                        }
                    } label: {
                        Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(product.isFavorite ? .gallerySold : .gallerySecondaryText)
                    }

                    NavigationLink(destination: AdminImageUploadView(product: product, viewModel: productViewModel)) {
                        Image(systemName: "photo.badge.plus")
                            .foregroundColor(.smokyQuartz)
                    }
                }
            }
        }
    }
}
