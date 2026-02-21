//
//  ProductDetailView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ProductDetailView: View {
    @ObservedObject var product: Product
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var productViewModel: ProductViewModel
    @State private var showAddedFeedback = false
    @State private var showWriteReview = false

    private var isInCart: Bool {
        cartViewModel.cartItems.contains(where: { $0.product?.id == product.id })
    }

    private var canAddToCart: Bool {
        if product.quantity <= 0 { return false }
        if product.isUnique && isInCart { return false }
        return true
    }

    private var availabilityText: String {
        if product.quantity > 0 { return "Verfügbar" }
        if product.isUnique {
            let hasImages = (product.images as? Set<ProductImage>)?.isEmpty == false
            return hasImages ? "Verkauft" : "Nächstes Exemplar in Vorbereitung"
        }
        return "Verkauft"
    }

    private var availabilityColor: Color {
        if product.quantity > 0 { return .galleryAvailable }
        if product.isUnique {
            let hasImages = (product.images as? Set<ProductImage>)?.isEmpty == false
            return hasImages ? .gallerySold : .mutedAmber
        }
        return .gallerySold
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
                // Produktbilder-Galerie (nur Admin-Bilder)
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

                    // Bewertungs-Durchschnitt
                    ReviewSummaryBar(product: product)

                    // Verfügbarkeit
                    HStack {
                        Circle()
                            .fill(availabilityColor)
                            .frame(width: 8, height: 8)
                        Text(availabilityText)
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

                // Kundenbewertungen
                ReviewSection(product: product, showWriteReview: $showWriteReview)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.galleryBackground)
        .navigationTitle(product.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        productViewModel.toggleFavorite(product)
                    }
                } label: {
                    Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(product.isFavorite ? .gallerySold : .gallerySecondaryText)
                }
            }
        }
        .sheet(isPresented: $showWriteReview, onDismiss: {
            // Context refreshen damit die neue Bewertung sofort sichtbar ist
            product.managedObjectContext?.refresh(product, mergeChanges: true)
        }) {
            WriteReviewView(product: product)
        }
    }
}

// MARK: - Bewertungs-Zusammenfassung (Sterne-Leiste)

struct ReviewSummaryBar: View {
    @ObservedObject var product: Product

    private var reviews: [Review] {
        let set = product.reviews as? Set<Review> ?? []
        return Array(set)
    }

    private var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        let total = reviews.reduce(0) { $0 + Int($1.rating) }
        return Double(total) / Double(reviews.count)
    }

    var body: some View {
        if !reviews.isEmpty {
            HStack(spacing: 4) {
                StarRatingView(rating: averageRating, size: 14)

                Text(String(format: "%.1f", averageRating))
                    .font(.galleryCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.softWhite)

                Text("(\(reviews.count))")
                    .font(.galleryCaption)
                    .foregroundColor(.gallerySecondaryText)
            }
        }
    }
}

// MARK: - Sterne-Anzeige

struct StarRatingView: View {
    let rating: Double
    let size: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImageName(for: star))
                    .font(.system(size: size))
                    .foregroundColor(.mutedAmber)
            }
        }
    }

    private func starImageName(for star: Int) -> String {
        let diff = rating - Double(star - 1)
        if diff >= 1 {
            return "star.fill"
        } else if diff >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Kundenbewertungen Sektion

struct ReviewSection: View {
    @ObservedObject var product: Product
    @Binding var showWriteReview: Bool

    private var sortedReviews: [Review] {
        let set = product.reviews as? Set<Review> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.galleryDivider)
                .frame(height: 1)

            HStack {
                Text("Kundenbewertungen")
                    .font(.gallerySubtitle)
                    .foregroundColor(.softWhite)
                Spacer()
                Button {
                    showWriteReview = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                        Text("Bewerten")
                    }
                    .font(.galleryCaption)
                    .foregroundColor(.smokyQuartz)
                }
            }

            if sortedReviews.isEmpty {
                VStack(spacing: 8) {
                    Text("Noch keine Bewertungen")
                        .font(.galleryBody)
                        .foregroundColor(.gallerySecondaryText)
                    Text("Sei der Erste, der dieses Stück bewertet.")
                        .font(.galleryCaption)
                        .foregroundColor(.gallerySecondaryText.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(sortedReviews, id: \.id) { review in
                    ReviewCard(review: review)
                }
            }
        }
    }
}

// MARK: - Einzelne Bewertungskarte

struct ReviewCard: View {
    let review: Review

    private var dateString: String {
        guard let date = review.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Autor und Datum
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.authorName ?? "Anonym")
                        .font(.galleryBody)
                        .fontWeight(.medium)
                        .foregroundColor(.softWhite)
                    Text(dateString)
                        .font(.galleryCaption)
                        .foregroundColor(.gallerySecondaryText)
                }
                Spacer()
                StarRatingView(rating: Double(review.rating), size: 12)
            }

            // Bewertungstext
            if let text = review.text, !text.isEmpty {
                Text(text)
                    .font(.galleryBody)
                    .foregroundColor(.gallerySecondaryText)
            }

            // Kundenfoto
            if let photoData = review.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.galleryPanel)
        .cornerRadius(10)
    }
}
