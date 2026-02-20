//
//  CartViewModel.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import Foundation
import CoreData

class CartViewModel: ObservableObject {

    @Published var cartItems: [CartItem] = []
    @Published var errorMessage: String?

    let store: PersistentStore

    init(store: PersistentStore = .shared) {
        self.store = store
        fetchCartItems()
    }

    var totalPrice: Double {
        cartItems.reduce(0) { sum, item in
            sum + (item.product?.price ?? 0) * Double(item.quantity)
        }
    }

    var totalItemCount: Int {
        cartItems.reduce(0) { $0 + Int($1.quantity) }
    }

    var isEmpty: Bool {
        cartItems.isEmpty
    }

    func fetchCartItems() {
        let request = NSFetchRequest<CartItem>(entityName: "CartItem")
        request.sortDescriptors = [NSSortDescriptor(key: "product.name", ascending: true)]

        do {
            cartItems = try store.context.fetch(request)
            errorMessage = nil
        } catch {
            errorMessage = "Warenkorb konnte nicht geladen werden: \(error.localizedDescription)"
        }
    }

    func addToCart(product: Product) {
        guard product.quantity > 0 else { return }

        // Bei Unikaten: nicht doppelt in den Warenkorb
        if product.isUnique {
            let alreadyInCart = cartItems.contains(where: { $0.product?.id == product.id })
            guard !alreadyInCart else { return }
        }

        // Prüfe ob das Produkt schon im Warenkorb ist
        if let existing = cartItems.first(where: { $0.product?.id == product.id }) {
            guard !product.isUnique else { return }
            existing.quantity += 1
        } else {
            let item = CartItem(context: store.context)
            item.id = UUID()
            item.quantity = 1
            item.product = product
        }

        // Lagerbestand reduzieren
        product.quantity -= 1

        if !store.save() {
            errorMessage = "Produkt konnte nicht zum Warenkorb hinzugefügt werden."
        }
        fetchCartItems()
    }

    func removeFromCart(cartItem: CartItem) {
        // Lagerbestand zurückgeben
        if let product = cartItem.product {
            product.quantity += cartItem.quantity
        }

        store.context.delete(cartItem)
        store.save()
        fetchCartItems()
    }

    func increaseQuantity(cartItem: CartItem) {
        guard let product = cartItem.product, product.quantity > 0 else { return }
        // Unikate können nicht mehrfach gekauft werden
        guard !product.isUnique else { return }

        cartItem.quantity += 1
        product.quantity -= 1

        store.save()
        fetchCartItems()
    }

    func decreaseQuantity(cartItem: CartItem) {
        if cartItem.quantity <= 1 {
            removeFromCart(cartItem: cartItem)
            return
        }

        cartItem.quantity -= 1
        cartItem.product?.quantity += 1

        store.save()
        fetchCartItems()
    }

    func clearCart() -> [CartItem] {
        let items = cartItems
        // Lösche alle CartItems (ohne Lagerbestand zurückzugeben, da bestellt)
        for item in cartItems {
            store.context.delete(item)
        }
        store.save()
        cartItems = []
        return items
    }
}
