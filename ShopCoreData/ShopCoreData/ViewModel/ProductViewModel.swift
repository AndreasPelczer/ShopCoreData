//
//  ProductViewModel.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import Foundation
import UIKit
import CoreData

class ProductViewModel: ObservableObject {
    
    @Published var products: [Product] = []

    let container = PersistentStore.shared
    
    init () {
        
        fetchProducts()
        if products.isEmpty {
            addDummyProduct()
        }
    
    }
    // Veröffentlichte Eigenschaften, die von SwiftUI überwacht werden können
    func addDummyProduct(){
        let dummyProduct = [
            
            (1,name: "Produkt 1", price: 19.99, quantity: 10),
            (2,name: "Produkt 2", price: 29.99, quantity: 8),
            (3,name: "Produkt 3", price: 9.99, quantity: 15)
    ]
        for (_, name, price, quantity) in dummyProduct {
            
            let product = Product (context: container.context)
            
            product.id = UUID()
            product.name = name
            product.price = price
            product.quantity = Int16(quantity)
        }
        saveAndFetch()
    }
   
       

    @Published var cart: [Product] = []     // Liste der Produkte im Warenkorb

   
    
    private func saveAndFetch(){
        container.save()
        fetchProducts()
    }
     
    func fetchProducts() {
  
            // Erstellen Sie eine Fetch-Anfrage für die Entität "Product"
            let fetchRequest = NSFetchRequest<Product>(entityName: "Product")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            do {
                // Versuchen Sie, die Produkte aus Core Data abzurufen
                products = try container.context.fetch(fetchRequest)
                
            } catch {
                print("Fehler beim Laden der Produkte: \(error.localizedDescription)")
            }
        }
    
    // Funktion zum Hinzufügen eines Produkts zum Warenkorb
    func addToCart(product: Product) {
        // Suchen Sie das Produkt in der Liste aller Produkte
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            // Reduzieren Sie die Menge des Produkts in der Produktliste
            products[index].quantity -= 1

            // Überprüfen Sie, ob das Produkt bereits im Warenkorb ist
            if let cartIndex = cart.firstIndex(where: { $0.id == product.id }) {
                // Wenn ja, erhöhen Sie die Menge im Warenkorb
                cart[cartIndex].quantity += 1
            } else {
                // Wenn nicht, fügen Sie das Produkt zum Warenkorb hinzu
                let newProduct = product
                newProduct.quantity = 1
                cart.append(newProduct)
            }
        }
    }
}
