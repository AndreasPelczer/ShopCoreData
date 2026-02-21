//
//  ImageStorageManager.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import UIKit
import CoreData

/// Verwaltet das Speichern, Laden und Löschen von Produktbildern in Core Data.
/// Bilder werden als JPEG komprimiert gespeichert, Thumbnails separat für schnelles Laden.
final class ImageStorageManager {
    static let shared = ImageStorageManager()

    private let store: PersistentStore
    private let maxImageDimension: CGFloat = 1200
    private let thumbnailDimension: CGFloat = 200
    private let jpegQuality: CGFloat = 0.8
    private let thumbnailJpegQuality: CGFloat = 0.6

    init(store: PersistentStore = .shared) {
        self.store = store
    }

    // MARK: - Bild hinzufügen

    /// Fügt ein Bild zu einem Produkt hinzu. Erzeugt automatisch ein Thumbnail.
    @discardableResult
    func addImage(_ image: UIImage, to product: Product, sortOrder: Int16? = nil) -> ProductImage? {
        guard let resizedImage = resizeImage(image, maxDimension: maxImageDimension),
              let imageData = resizedImage.jpegData(compressionQuality: jpegQuality) else {
            return nil
        }

        let thumbnail = resizeImage(image, maxDimension: thumbnailDimension)
        let thumbnailData = thumbnail?.jpegData(compressionQuality: thumbnailJpegQuality)

        let productImage = ProductImage(context: store.context)
        productImage.id = UUID()
        productImage.imageData = imageData
        productImage.thumbnailData = thumbnailData
        productImage.createdAt = Date()
        productImage.product = product

        if let sortOrder = sortOrder {
            productImage.sortOrder = sortOrder
        } else {
            // Nächste verfügbare Sortierposition
            let existingImages = sortedImages(for: product)
            productImage.sortOrder = Int16(existingImages.count)
        }

        store.save()
        return productImage
    }

    /// Fügt mehrere Bilder zu einem Produkt hinzu.
    func addImages(_ images: [UIImage], to product: Product) {
        let existingCount = sortedImages(for: product).count
        for (index, image) in images.enumerated() {
            addImage(image, to: product, sortOrder: Int16(existingCount + index))
        }
    }

    // MARK: - Bilder laden

    /// Gibt alle Bilder eines Produkts sortiert nach `sortOrder` zurück.
    func sortedImages(for product: Product) -> [ProductImage] {
        guard let images = product.images as? Set<ProductImage> else { return [] }
        return images.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Lädt das UIImage aus einer ProductImage Entity.
    func loadImage(from productImage: ProductImage) -> UIImage? {
        guard let data = productImage.imageData else { return nil }
        return UIImage(data: data)
    }

    /// Lädt das Thumbnail-UIImage aus einer ProductImage Entity.
    func loadThumbnail(from productImage: ProductImage) -> UIImage? {
        guard let data = productImage.thumbnailData else {
            // Fallback auf Hauptbild
            return loadImage(from: productImage)
        }
        return UIImage(data: data)
    }

    /// Gibt das erste Thumbnail für ein Produkt zurück (für Listenansicht).
    func primaryThumbnail(for product: Product) -> UIImage? {
        let images = sortedImages(for: product)
        guard let first = images.first else { return nil }
        return loadThumbnail(from: first)
    }

    // MARK: - Bilder verwalten

    /// Löscht ein einzelnes Produktbild.
    func deleteImage(_ productImage: ProductImage) {
        store.context.delete(productImage)
        store.save()
    }

    /// Löscht alle Bilder eines Produkts.
    func deleteAllImages(for product: Product) {
        let images = sortedImages(for: product)
        for image in images {
            store.context.delete(image)
        }
        store.save()
    }

    /// Aktualisiert die Sortierreihenfolge der Bilder.
    func reorderImages(_ images: [ProductImage]) {
        for (index, image) in images.enumerated() {
            image.sortOrder = Int16(index)
        }
        store.save()
    }

    /// Gibt die Anzahl der Bilder für ein Produkt zurück.
    func imageCount(for product: Product) -> Int {
        return (product.images as? Set<ProductImage>)?.count ?? 0
    }

    // MARK: - Hilfsfunktionen

    /// Skaliert ein Bild proportional auf eine maximale Dimension herunter.
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let maxSide = max(size.width, size.height)

        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
