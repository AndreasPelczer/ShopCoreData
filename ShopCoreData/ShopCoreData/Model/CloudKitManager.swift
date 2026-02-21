//
//  CloudKitManager.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import Foundation
import CloudKit
import UIKit
import Combine

/// Verwaltet die CloudKit-Kommunikation für den Shop.
/// Nutzt die Public Database, damit Kunden Produkte sehen können,
/// die der Künstler hochgeladen hat.
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()

    // MARK: - Konfiguration

    /// CloudKit Container ID — muss im Apple Developer Portal eingerichtet werden.
    /// Setze hier deine echte Container-ID ein (Format: "iCloud.com.syntax.ShopCoreData").
    private let containerID = "iCloud.com.syntax.ShopCoreData"

    private lazy var container: CKContainer = {
        CKContainer(identifier: containerID)
    }()

    private var publicDatabase: CKDatabase {
        container.publicCloudDatabase
    }

    // MARK: - Record Types (CloudKit Schema)

    enum RecordType: String {
        case product = "ShopProduct"
        case category = "ShopCategory"
        case productImage = "ShopProductImage"
    }

    // MARK: - Status

    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    private let store: PersistentStore

    init(store: PersistentStore = .shared) {
        self.store = store
    }

    // MARK: - Account-Status prüfen

    /// Prüft ob der Benutzer bei iCloud angemeldet ist.
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.accountStatus = status
            }
        } catch {
            await MainActor.run {
                self.accountStatus = .couldNotDetermine
                self.lastSyncError = "iCloud-Status konnte nicht geprüft werden: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Upload (Künstler → CloudKit)

    /// Lädt eine Kategorie in CloudKit hoch.
    func uploadCategory(_ category: Category) async throws -> CKRecord {
        let record = CKRecord(recordType: RecordType.category.rawValue)
        record["name"] = category.name
        record["localID"] = category.id?.uuidString

        return try await publicDatabase.save(record)
    }

    /// Lädt ein Produkt mit allen Bildern in CloudKit hoch.
    func uploadProduct(_ product: Product, categoryRecordID: CKRecord.ID) async throws -> CKRecord {
        let record = CKRecord(recordType: RecordType.product.rawValue)
        record["name"] = product.name
        record["price"] = product.price
        record["productDescription"] = product.productDescription
        record["artist"] = product.artist
        record["material"] = product.material
        record["height"] = product.height
        record["imageName"] = product.imageName
        record["isUnique"] = product.isUnique ? 1 : 0
        record["quantity"] = Int64(product.quantity)
        record["localID"] = product.id?.uuidString
        record["category"] = CKRecord.Reference(recordID: categoryRecordID, action: .none)

        let savedRecord = try await publicDatabase.save(record)

        // Bilder hochladen
        let imageManager = ImageStorageManager(store: store)
        let images = imageManager.sortedImages(for: product)

        for productImage in images {
            try await uploadProductImage(productImage, productRecordID: savedRecord.recordID)
        }

        return savedRecord
    }

    /// Lädt ein einzelnes Produktbild als CKAsset in CloudKit hoch.
    func uploadProductImage(_ productImage: ProductImage, productRecordID: CKRecord.ID) async throws {
        guard let imageData = productImage.imageData else { return }

        // CKAsset benötigt eine temporäre Datei
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try imageData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let record = CKRecord(recordType: RecordType.productImage.rawValue)
        record["image"] = CKAsset(fileURL: tempURL)
        record["sortOrder"] = Int64(productImage.sortOrder)
        record["localID"] = productImage.id?.uuidString
        record["product"] = CKRecord.Reference(recordID: productRecordID, action: .deleteSelf)

        // Thumbnail separat hochladen
        if let thumbnailData = productImage.thumbnailData {
            let thumbURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            try thumbnailData.write(to: thumbURL)
            defer { try? FileManager.default.removeItem(at: thumbURL) }
            record["thumbnail"] = CKAsset(fileURL: thumbURL)
        }

        _ = try await publicDatabase.save(record)
    }

    /// Lädt den gesamten Shop-Katalog hoch (alle Kategorien + Produkte + Bilder).
    func uploadEntireCatalog() async {
        await MainActor.run {
            isSyncing = true
            lastSyncError = nil
        }

        do {
            // 1. Kategorien hochladen
            let categoryRequest = NSFetchRequest<Category>(entityName: "Category")
            let categories = try store.context.fetch(categoryRequest)

            var categoryRecordIDs: [UUID: CKRecord.ID] = [:]

            for category in categories {
                guard let id = category.id else { continue }
                let record = try await uploadCategory(category)
                categoryRecordIDs[id] = record.recordID
            }

            // 2. Produkte hochladen
            let productRequest = NSFetchRequest<Product>(entityName: "Product")
            let products = try store.context.fetch(productRequest)

            for product in products {
                guard let categoryID = product.category?.id,
                      let categoryRecordID = categoryRecordIDs[categoryID] else { continue }
                _ = try await uploadProduct(product, categoryRecordID: categoryRecordID)
            }

            await MainActor.run {
                self.isSyncing = false
            }
        } catch {
            await MainActor.run {
                self.isSyncing = false
                self.lastSyncError = "Upload fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Download (CloudKit → Kunde)

    /// Lädt alle Kategorien aus CloudKit herunter und speichert sie lokal.
    func fetchCategories() async throws -> [CKRecord] {
        let query = CKQuery(recordType: RecordType.category.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let (results, _) = try await publicDatabase.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    /// Lädt alle Produkte einer Kategorie aus CloudKit.
    func fetchProducts(forCategory categoryRecordID: CKRecord.ID? = nil) async throws -> [CKRecord] {
        let predicate: NSPredicate
        if let categoryRecordID = categoryRecordID {
            let reference = CKRecord.Reference(recordID: categoryRecordID, action: .none)
            predicate = NSPredicate(format: "category == %@", reference)
        } else {
            predicate = NSPredicate(value: true)
        }

        let query = CKQuery(recordType: RecordType.product.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let (results, _) = try await publicDatabase.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    /// Lädt die Bilder eines Produkts aus CloudKit.
    func fetchProductImages(forProduct productRecordID: CKRecord.ID) async throws -> [CKRecord] {
        let reference = CKRecord.Reference(recordID: productRecordID, action: .none)
        let predicate = NSPredicate(format: "product == %@", reference)
        let query = CKQuery(recordType: RecordType.productImage.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let (results, _) = try await publicDatabase.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    /// Synchronisiert den gesamten CloudKit-Katalog in die lokale Core Data Datenbank.
    func syncCatalogToLocal() async {
        await MainActor.run {
            isSyncing = true
            lastSyncError = nil
        }

        do {
            // 1. Kategorien laden
            let categoryRecords = try await fetchCategories()
            var localCategories: [CKRecord.ID: Category] = [:]

            for record in categoryRecords {
                let category = findOrCreateCategory(
                    localID: record["localID"] as? String,
                    name: record["name"] as? String ?? ""
                )
                localCategories[record.recordID] = category
            }

            // 2. Produkte laden
            let productRecords = try await fetchProducts()
            let imageManager = ImageStorageManager(store: store)

            for record in productRecords {
                guard let categoryRef = record["category"] as? CKRecord.Reference,
                      let category = localCategories[categoryRef.recordID] else { continue }

                let product = findOrCreateProduct(
                    localID: record["localID"] as? String,
                    record: record,
                    category: category
                )

                // 3. Bilder laden
                let imageRecords = try await fetchProductImages(forProduct: record.recordID)
                for imageRecord in imageRecords {
                    guard let asset = imageRecord["image"] as? CKAsset,
                          let fileURL = asset.fileURL,
                          let imageData = try? Data(contentsOf: fileURL),
                          let image = UIImage(data: imageData) else { continue }

                    let sortOrder = imageRecord["sortOrder"] as? Int64 ?? 0

                    // Prüfen ob Bild schon existiert
                    let existingLocalID = imageRecord["localID"] as? String
                    if let existingLocalID = existingLocalID,
                       let uuid = UUID(uuidString: existingLocalID),
                       imageAlreadyExists(id: uuid, for: product) {
                        continue
                    }

                    imageManager.addImage(image, to: product, sortOrder: Int16(sortOrder))
                }
            }

            store.save()

            await MainActor.run {
                self.isSyncing = false
            }
        } catch {
            await MainActor.run {
                self.isSyncing = false
                self.lastSyncError = "Sync fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Subscriptions (Push bei neuen Produkten)

    /// Registriert eine Subscription für neue Produkte, um Push-Notifications zu erhalten.
    func subscribeToNewProducts() async throws {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: RecordType.product.rawValue,
            predicate: predicate,
            options: [.firesOnRecordCreation]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.titleLocalizationKey = "Neues Produkt!"
        notificationInfo.alertLocalizationKey = "Ein neues Unikat wurde zur Galerie hinzugefügt."
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo

        _ = try await publicDatabase.save(subscription)
    }

    // MARK: - Hilfsfunktionen

    private func findOrCreateCategory(localID: String?, name: String) -> Category {
        if let localID = localID, let uuid = UUID(uuidString: localID) {
            let request = NSFetchRequest<Category>(entityName: "Category")
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            if let existing = try? store.context.fetch(request).first {
                existing.name = name
                return existing
            }
        }

        let category = Category(context: store.context)
        category.id = localID.flatMap { UUID(uuidString: $0) } ?? UUID()
        category.name = name
        return category
    }

    private func findOrCreateProduct(localID: String?, record: CKRecord, category: Category) -> Product {
        if let localID = localID, let uuid = UUID(uuidString: localID) {
            let request = NSFetchRequest<Product>(entityName: "Product")
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            if let existing = try? store.context.fetch(request).first {
                updateProduct(existing, from: record, category: category)
                return existing
            }
        }

        let product = Product(context: store.context)
        product.id = localID.flatMap { UUID(uuidString: $0) } ?? UUID()
        updateProduct(product, from: record, category: category)
        return product
    }

    private func updateProduct(_ product: Product, from record: CKRecord, category: Category) {
        product.name = record["name"] as? String
        product.price = record["price"] as? Double ?? 0
        product.productDescription = record["productDescription"] as? String
        product.artist = record["artist"] as? String
        product.material = record["material"] as? String
        product.height = record["height"] as? Double ?? 0
        product.imageName = record["imageName"] as? String
        product.isUnique = (record["isUnique"] as? Int64 ?? 1) == 1
        product.quantity = Int16(record["quantity"] as? Int64 ?? 1)
        product.category = category
    }

    private func imageAlreadyExists(id: UUID, for product: Product) -> Bool {
        guard let images = product.images as? Set<ProductImage> else { return false }
        return images.contains { $0.id == id }
    }
}
