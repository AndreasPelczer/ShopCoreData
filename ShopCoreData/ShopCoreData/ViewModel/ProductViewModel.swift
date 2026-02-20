//
//  ProductViewModel.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import Foundation
import CoreData

class ProductViewModel: ObservableObject {

    @Published var products: [Product] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var searchText: String = ""

    let store = PersistentStore.shared

    init() {
        fetchCategories()
        fetchProducts()
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
        } catch {
            print("Fehler beim Laden der Produkte: \(error.localizedDescription)")
        }
    }

    func fetchCategories() {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            categories = try store.context.fetch(request)
        } catch {
            print("Fehler beim Laden der Kategorien: \(error.localizedDescription)")
        }
    }
}
