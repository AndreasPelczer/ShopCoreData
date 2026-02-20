//
//  PersistentStore.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import Foundation
import CoreData

struct PersistentStore {
    private let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }
    static let shared = PersistentStore()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ShopData")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Error with Core Data: \(error), \(error.userInfo)")
            }
        }
    }

    @discardableResult
    func save() -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch let error as NSError {
            NSLog("Unresolved error saving context: \(error), \(error.userInfo)")
            return false
        }
    }

    func seedDataIfNeeded() {
        let fetchRequest = NSFetchRequest<Product>(entityName: "Product")
        let count = (try? context.count(for: fetchRequest)) ?? 0
        guard count == 0 else { return }

        // Kategorien anlegen
        let elektronik = Category(context: context)
        elektronik.id = UUID()
        elektronik.name = "Elektronik"

        let kleidung = Category(context: context)
        kleidung.id = UUID()
        kleidung.name = "Kleidung"

        let haushalt = Category(context: context)
        haushalt.id = UUID()
        haushalt.name = "Haushalt"

        let sport = Category(context: context)
        sport.id = UUID()
        sport.name = "Sport"

        // Produkte anlegen
        let products: [(String, Double, Int16, String, String, Category)] = [
            ("Bluetooth Kopfhörer", 49.99, 25, "headphones", "Kabellose Bluetooth 5.0 Kopfhörer mit Noise-Cancelling und 30h Akkulaufzeit.", elektronik),
            ("USB-C Ladekabel", 12.99, 50, "cable.coaxial", "Schnellladekabel USB-C auf USB-C, 2 Meter, geflochten.", elektronik),
            ("Smartphone Hülle", 14.99, 40, "iphone", "Stoßfeste Schutzhülle mit transparentem Design.", elektronik),
            ("LED Schreibtischlampe", 34.99, 15, "lamp.desk", "Dimmbare LED-Lampe mit 5 Helligkeitsstufen und USB-Anschluss.", elektronik),
            ("T-Shirt Basic", 19.99, 100, "tshirt", "Baumwoll-T-Shirt in verschiedenen Farben, Unisex.", kleidung),
            ("Winterjacke", 89.99, 20, "cloud.snow", "Warme Winterjacke mit Kapuze, wasserabweisend.", kleidung),
            ("Sneaker Classic", 59.99, 30, "shoe", "Bequeme Alltagssneaker mit Memory-Foam-Sohle.", kleidung),
            ("Trinkflasche Edelstahl", 24.99, 35, "waterbottle", "Isolierte Edelstahl-Trinkflasche, 750ml, BPA-frei.", haushalt),
            ("Küchenwaage Digital", 22.99, 20, "scalemass", "Digitale Küchenwaage mit LCD-Display, max. 5kg.", haushalt),
            ("Yoga Matte", 29.99, 25, "figure.yoga", "Rutschfeste Yogamatte, 6mm dick, mit Tragegurt.", sport),
            ("Fitness Tracker", 39.99, 30, "applewatch", "Fitness-Armband mit Herzfrequenzmessung und Schlaftracking.", sport),
            ("Springseil", 9.99, 45, "figure.jumprope", "Verstellbares Speed-Springseil mit Kugellagern.", sport),
        ]

        for (name, price, quantity, imageName, desc, category) in products {
            let product = Product(context: context)
            product.id = UUID()
            product.name = name
            product.price = price
            product.quantity = quantity
            product.imageName = imageName
            product.productDescription = desc
            product.category = category
        }

        save()
    }
}
