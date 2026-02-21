//
//  ProductViewModel.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import Foundation
import CoreData
import Combine
import UIKit

class ProductViewModel: ObservableObject {

    @Published var products: [Product] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var searchText: String = ""
    @Published var errorMessage: String?

    let store: PersistentStore
    let imageManager: ImageStorageManager
    private var cancellable: AnyCancellable?

    init(store: PersistentStore = .shared) {
        self.store = store
        self.imageManager = ImageStorageManager(store: store)
        fetchCategories()
        fetchProducts()

        // Refresh products when Core Data context saves (e.g. after cart changes)
        cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: store.context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchProducts()
            }
    }

    var filteredProducts: [Product] {
        var result = products

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                ($0.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    func fetchProducts() {
        let request = NSFetchRequest<Product>(entityName: "Product")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            products = try store.context.fetch(request)
            errorMessage = nil
        } catch {
            errorMessage = "Produkte konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    func fetchCategories() {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            categories = try store.context.fetch(request)
        } catch {
            errorMessage = "Kategorien konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Bildverwaltung

    /// Fügt Bilder zu einem Produkt hinzu und aktualisiert die Ansicht.
    func addImages(_ images: [UIImage], to product: Product) {
        imageManager.addImages(images, to: product)
        fetchProducts()
    }

    /// Löscht ein einzelnes Bild und aktualisiert die Ansicht.
    func deleteImage(_ productImage: ProductImage) {
        imageManager.deleteImage(productImage)
        fetchProducts()
    }

    /// Gibt die sortierten Bilder eines Produkts zurück.
    func sortedImages(for product: Product) -> [ProductImage] {
        imageManager.sortedImages(for: product)
    }

    // MARK: - Nächstes Exemplar (Unikate)

    /// Bereitet ein Unikat für das nächste Exemplar vor:
    /// - Löscht alle aktuellen Produktbilder
    /// - Setzt die Menge auf 1 (wieder verfügbar)
    /// Der Künstler lädt danach neue Fotos des neuen Exemplars hoch.
    func prepareNextExemplar(for product: Product) {
        guard product.isUnique else { return }

        // Alle Bilder löschen
        let images = sortedImages(for: product)
        for image in images {
            imageManager.deleteImage(image)
        }

        // Wieder verfügbar machen
        product.quantity = 1
        store.save()
        fetchProducts()
    }

    // MARK: - Favoriten

    var favoriteProducts: [Product] {
        products.filter { $0.isFavorite }
    }

    func toggleFavorite(_ product: Product) {
        product.isFavorite.toggle()
        store.save()
        fetchProducts()
    }
}
