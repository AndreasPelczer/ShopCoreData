//
//  ShopCoreDataTests.swift
//  ShopCoreDataTests
//
//  Created by Andreas Pelczer on 04.01.24.
//

import XCTest
import CoreData
@testable import ShopCoreData

final class ShopCoreDataTests: XCTestCase {

    var store: PersistentStore!

    override func setUpWithError() throws {
        store = PersistentStore(inMemory: true)
    }

    override func tearDownWithError() throws {
        store = nil
    }

    // MARK: - Helper

    private func createProduct(name: String = "Testprodukt", price: Double = 9.99, quantity: Int16 = 10) -> Product {
        let product = Product(context: store.context)
        product.id = UUID()
        product.name = name
        product.price = price
        product.quantity = quantity
        product.imageName = "shippingbox"
        product.productDescription = "Testbeschreibung"
        store.save()
        return product
    }

    private func createCategory(name: String = "Testkategorie") -> Category {
        let category = Category(context: store.context)
        category.id = UUID()
        category.name = name
        store.save()
        return category
    }

    // MARK: - PersistentStore Tests

    func testSaveWithNoChangesReturnsTrue() throws {
        XCTAssertTrue(store.save())
    }

    func testSaveWithChangesReturnsTrue() throws {
        _ = createProduct()
        XCTAssertTrue(store.save())
    }

    func testSeedDataIfNeeded() throws {
        store.seedDataIfNeeded()

        let request = NSFetchRequest<Product>(entityName: "Product")
        let count = try store.context.count(for: request)
        XCTAssertEqual(count, 12, "Seed data should create 12 products")

        let categoryRequest = NSFetchRequest<Category>(entityName: "Category")
        let categoryCount = try store.context.count(for: categoryRequest)
        XCTAssertEqual(categoryCount, 4, "Seed data should create 4 categories")
    }

    func testSeedDataIfNeededDoesNotDuplicate() throws {
        store.seedDataIfNeeded()
        store.seedDataIfNeeded()

        let request = NSFetchRequest<Product>(entityName: "Product")
        let count = try store.context.count(for: request)
        XCTAssertEqual(count, 12, "Calling seedDataIfNeeded twice should not duplicate products")
    }

    // MARK: - ProductViewModel Tests

    func testFetchProductsReturnsEmpty() throws {
        let vm = ProductViewModel(store: store)
        XCTAssertTrue(vm.products.isEmpty)
        XCTAssertNil(vm.errorMessage)
    }

    func testFetchProductsReturnsSortedProducts() throws {
        _ = createProduct(name: "Zebra")
        _ = createProduct(name: "Apfel")
        _ = createProduct(name: "Mango")

        let vm = ProductViewModel(store: store)
        XCTAssertEqual(vm.products.count, 3)
        XCTAssertEqual(vm.products[0].name, "Apfel")
        XCTAssertEqual(vm.products[1].name, "Mango")
        XCTAssertEqual(vm.products[2].name, "Zebra")
    }

    func testFetchCategories() throws {
        _ = createCategory(name: "Elektronik")
        _ = createCategory(name: "Sport")

        let vm = ProductViewModel(store: store)
        XCTAssertEqual(vm.categories.count, 2)
    }

    func testFilteredProductsByCategory() throws {
        let cat1 = createCategory(name: "Elektronik")
        let cat2 = createCategory(name: "Sport")

        let p1 = createProduct(name: "Kopfhörer")
        p1.category = cat1
        let p2 = createProduct(name: "Yoga Matte")
        p2.category = cat2
        store.save()

        let vm = ProductViewModel(store: store)
        XCTAssertEqual(vm.filteredProducts.count, 2)

        vm.selectedCategory = cat1
        XCTAssertEqual(vm.filteredProducts.count, 1)
        XCTAssertEqual(vm.filteredProducts.first?.name, "Kopfhörer")
    }

    func testFilteredProductsBySearchText() throws {
        _ = createProduct(name: "Bluetooth Kopfhörer")
        _ = createProduct(name: "USB Kabel")

        let vm = ProductViewModel(store: store)
        vm.searchText = "Bluetooth"
        XCTAssertEqual(vm.filteredProducts.count, 1)
        XCTAssertEqual(vm.filteredProducts.first?.name, "Bluetooth Kopfhörer")
    }

    // MARK: - CartViewModel Tests

    func testCartStartsEmpty() throws {
        let vm = CartViewModel(store: store)
        XCTAssertTrue(vm.isEmpty)
        XCTAssertEqual(vm.totalItemCount, 0)
        XCTAssertEqual(vm.totalPrice, 0)
    }

    func testAddToCart() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)

        XCTAssertEqual(vm.cartItems.count, 1)
        XCTAssertEqual(vm.cartItems.first?.quantity, 1)
        XCTAssertEqual(product.quantity, 4, "Product stock should decrease by 1")
        XCTAssertFalse(vm.isEmpty)
    }

    func testAddToCartIncreasesQuantityForExistingItem() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)
        vm.addToCart(product: product)

        XCTAssertEqual(vm.cartItems.count, 1, "Should not create a second cart item")
        XCTAssertEqual(vm.cartItems.first?.quantity, 2)
        XCTAssertEqual(product.quantity, 3)
    }

    func testAddToCartIgnoresOutOfStockProduct() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 0)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)

        XCTAssertTrue(vm.cartItems.isEmpty)
        XCTAssertEqual(product.quantity, 0)
    }

    func testTotalPrice() throws {
        let p1 = createProduct(name: "Produkt A", price: 10.0, quantity: 5)
        let p2 = createProduct(name: "Produkt B", price: 20.0, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: p1)
        vm.addToCart(product: p2)
        vm.addToCart(product: p2)

        // 1 x 10.0 + 2 x 20.0 = 50.0
        XCTAssertEqual(vm.totalPrice, 50.0, accuracy: 0.01)
    }

    func testTotalItemCount() throws {
        let p1 = createProduct(name: "Produkt A", price: 10.0, quantity: 5)
        let p2 = createProduct(name: "Produkt B", price: 20.0, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: p1)
        vm.addToCart(product: p2)
        vm.addToCart(product: p2)

        XCTAssertEqual(vm.totalItemCount, 3)
    }

    func testRemoveFromCart() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)
        XCTAssertEqual(product.quantity, 4)

        let cartItem = vm.cartItems.first!
        vm.removeFromCart(cartItem: cartItem)

        XCTAssertTrue(vm.cartItems.isEmpty)
        XCTAssertEqual(product.quantity, 5, "Stock should be restored when removing from cart")
    }

    func testIncreaseQuantity() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)
        let cartItem = vm.cartItems.first!
        vm.increaseQuantity(cartItem: cartItem)

        XCTAssertEqual(vm.cartItems.first?.quantity, 2)
        XCTAssertEqual(product.quantity, 3)
    }

    func testIncreaseQuantityIgnoredWhenOutOfStock() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 1)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)
        let cartItem = vm.cartItems.first!
        vm.increaseQuantity(cartItem: cartItem)

        XCTAssertEqual(vm.cartItems.first?.quantity, 1, "Should not increase when product is out of stock")
        XCTAssertEqual(product.quantity, 0)
    }

    func testDecreaseQuantity() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)
        vm.addToCart(product: product)
        let cartItem = vm.cartItems.first!
        vm.decreaseQuantity(cartItem: cartItem)

        XCTAssertEqual(vm.cartItems.first?.quantity, 1)
        XCTAssertEqual(product.quantity, 4)
    }

    func testDecreaseQuantityRemovesItemWhenOne() throws {
        let product = createProduct(name: "Testprodukt", price: 19.99, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: product)
        let cartItem = vm.cartItems.first!
        vm.decreaseQuantity(cartItem: cartItem)

        XCTAssertTrue(vm.cartItems.isEmpty, "Item should be removed when quantity reaches 0")
        XCTAssertEqual(product.quantity, 5, "Stock should be restored")
    }

    func testClearCart() throws {
        let p1 = createProduct(name: "Produkt A", price: 10.0, quantity: 5)
        let p2 = createProduct(name: "Produkt B", price: 20.0, quantity: 5)
        let vm = CartViewModel(store: store)

        vm.addToCart(product: p1)
        vm.addToCart(product: p2)

        let items = vm.clearCart()
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(vm.cartItems.isEmpty)
    }

    // MARK: - OrderViewModel Tests

    func testOrdersStartEmpty() throws {
        let vm = OrderViewModel(store: store)
        XCTAssertTrue(vm.orders.isEmpty)
    }

    func testPlaceOrder() throws {
        let product = createProduct(name: "Testprodukt", price: 29.99, quantity: 5)
        let cartVM = CartViewModel(store: store)
        cartVM.addToCart(product: product)
        cartVM.addToCart(product: product)

        let orderVM = OrderViewModel(store: store)
        orderVM.placeOrder(cartItems: cartVM.cartItems, totalAmount: cartVM.totalPrice)

        XCTAssertEqual(orderVM.orders.count, 1)

        let order = orderVM.orders.first!
        XCTAssertEqual(order.totalAmount, 59.98, accuracy: 0.01)
        XCTAssertEqual(order.status, "Bestellt")
        XCTAssertNotNil(order.date)
    }

    func testPlaceOrderCreatesOrderItems() throws {
        let p1 = createProduct(name: "Produkt A", price: 10.0, quantity: 5)
        let p2 = createProduct(name: "Produkt B", price: 20.0, quantity: 5)
        let cartVM = CartViewModel(store: store)
        cartVM.addToCart(product: p1)
        cartVM.addToCart(product: p2)

        let orderVM = OrderViewModel(store: store)
        orderVM.placeOrder(cartItems: cartVM.cartItems, totalAmount: cartVM.totalPrice)

        let order = orderVM.orders.first!
        let items = orderVM.orderItems(for: order)
        XCTAssertEqual(items.count, 2)

        let itemNames = items.map { $0.productName ?? "" }.sorted()
        XCTAssertEqual(itemNames, ["Produkt A", "Produkt B"])
    }

    func testOrderItemsPriceAtPurchase() throws {
        let product = createProduct(name: "Testprodukt", price: 49.99, quantity: 5)
        let cartVM = CartViewModel(store: store)
        cartVM.addToCart(product: product)

        let orderVM = OrderViewModel(store: store)
        orderVM.placeOrder(cartItems: cartVM.cartItems, totalAmount: cartVM.totalPrice)

        let order = orderVM.orders.first!
        let items = orderVM.orderItems(for: order)
        XCTAssertEqual(items.first?.priceAtPurchase ?? 0, 49.99, accuracy: 0.01)
    }

    func testMultipleOrders() throws {
        let orderVM = OrderViewModel(store: store)

        let p1 = createProduct(name: "Produkt A", price: 10.0, quantity: 5)
        let cartVM = CartViewModel(store: store)
        cartVM.addToCart(product: p1)
        orderVM.placeOrder(cartItems: cartVM.cartItems, totalAmount: cartVM.totalPrice)
        _ = cartVM.clearCart()

        let p2 = createProduct(name: "Produkt B", price: 20.0, quantity: 5)
        cartVM.addToCart(product: p2)
        orderVM.placeOrder(cartItems: cartVM.cartItems, totalAmount: cartVM.totalPrice)

        XCTAssertEqual(orderVM.orders.count, 2)
    }
}
