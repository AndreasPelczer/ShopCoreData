//
//  ProductImageGalleryView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI

/// Zeigt die Bilder eines Produkts als horizontales Karussell mit Seitenanzeige.
/// Fällt auf das SF Symbol zurück, wenn keine echten Bilder vorhanden sind.
struct ProductImageGalleryView: View {
    let product: Product
    @State private var currentPage = 0

    private let imageManager = ImageStorageManager.shared
    private var productImages: [ProductImage] {
        imageManager.sortedImages(for: product)
    }

    var body: some View {
        if productImages.isEmpty {
            // Fallback: SF Symbol wie bisher
            Image(systemName: product.imageName ?? "shippingbox")
                .font(.system(size: 80))
                .foregroundColor(.smokyQuartz)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .background(Color.galleryPanel)
                .cornerRadius(12)
        } else {
            VStack(spacing: 8) {
                // Bild-Karussell
                TabView(selection: $currentPage) {
                    ForEach(Array(productImages.enumerated()), id: \.element.id) { index, productImage in
                        if let image = imageManager.loadImage(from: productImage) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .clipped()
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 300)
                .cornerRadius(12)

                // Seitenanzeige (nur bei mehreren Bildern)
                if productImages.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<productImages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.smokyQuartz : Color.gallerySecondaryText.opacity(0.4))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

/// Kompakte Thumbnail-Ansicht für die Produktliste.
/// Zeigt das erste Bild als Thumbnail oder fällt auf SF Symbol zurück.
struct ProductThumbnailView: View {
    let product: Product
    let size: CGFloat

    private let imageManager = ImageStorageManager.shared

    var body: some View {
        Group {
            if let thumbnail = imageManager.primaryThumbnail(for: product) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Image(systemName: product.imageName ?? "shippingbox")
                    .font(.title2)
                    .foregroundColor(.smokyQuartz)
                    .frame(width: size, height: size)
            }
        }
        .background(Color.galleryPanel)
        .cornerRadius(8)
    }
}
