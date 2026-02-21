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
        } else {
            // Lightweight Migration aktivieren — nötig für Schema-Änderungen (z.B. neue ProductImage Entity)
            let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
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
        let dunkleSchoko = Category(context: context)
        dunkleSchoko.id = UUID()
        dunkleSchoko.name = "Dunkle Schokolade"

        let weisseSchoko = Category(context: context)
        weisseSchoko.id = UUID()
        weisseSchoko.name = "Weiße Schokolade"

        let marmorCat = Category(context: context)
        marmorCat.id = UUID()
        marmorCat.name = "Marmor"

        let granitCat = Category(context: context)
        granitCat.id = UUID()
        granitCat.name = "Granit"

        // Produkte anlegen — jedes Stück ein Unikat (quantity = 1)
        // Tuple: (name, price, imageName, description, category, artist, material, height)
        let products: [(String, Double, String, String, Category, String, String, Double)] = [
            // Dunkle Schokolade
            ("Midnight Temptation", 189.00, "flame",
             "Handgegossene Bong aus 72% Edelkakao-Schokolade. Samtige Oberfläche mit edlem Glanz. Jedes Stück wird in Handarbeit temperiert und geformt.",
             dunkleSchoko, "Pelczer Manufaktur", "72% Edelkakao", 30.0),

            ("Bitter Eclipse", 229.00, "flame",
             "Massive Bong aus 85% Zartbitterschokolade mit feinen Kakaonibs-Einschlüssen. Markantes Design mit mondförmigem Mundstück.",
             dunkleSchoko, "Pelczer Manufaktur", "85% Zartbitter", 35.0),

            ("Cocoa Serpent", 249.00, "flame",
             "Spiralförmige Bong aus dunkler Schokolade mit gewundener Schlangenstruktur. Aufwendig von Hand modelliert. Essbare Kunst.",
             dunkleSchoko, "Pelczer Manufaktur", "70% Grand Cru Kakao", 38.0),

            // Weiße Schokolade
            ("Ivory Tower", 199.00, "flame",
             "Elegante Bong aus belgischer weißer Schokolade. Cremig-glatte Oberfläche mit zartem Vanilleduft. Ein Blickfang in jedem Raum.",
             weisseSchoko, "Pelczer Manufaktur", "Belgische weiße Kuvertüre", 32.0),

            ("Vanilla Cloud", 169.00, "flame",
             "Weiche, organische Formen aus weißer Schokolade. Wolkenartiges Design mit Bourbon-Vanille-Aroma. Kompakt und sammelwürdig.",
             weisseSchoko, "Pelczer Manufaktur", "Weiße Schokolade & Vanille", 25.0),

            ("Snow Pearl", 219.00, "flame",
             "Perlenförmig aufgebaute Bong aus weißer Schokolade mit schimmernden Kakaobutter-Kristallen. Jede Perle einzeln aufgesetzt.",
             weisseSchoko, "Pelczer Manufaktur", "Kristallisierte Kakaobutter", 28.0),

            // Marmor
            ("Carrara Classic", 489.00, "mountain.2",
             "Aus einem Stück italienischem Carrara-Marmor gemeißelt. Klassisch weiß mit feiner grauer Maserung. Schwer und massiv — ein Lebensbegleiter.",
             marmorCat, "Pelczer Manufaktur", "Carrara-Marmor", 28.0),

            ("Nero Marquina", 549.00, "mountain.2",
             "Tiefschwarzer spanischer Marmor mit weißen Adern. Polierte Oberfläche, die wie ein Nachthimmel schimmert. Handgeschliffen.",
             marmorCat, "Pelczer Manufaktur", "Nero Marquina Marmor", 32.0),

            ("Calacatta Gold", 679.00, "mountain.2",
             "Aus dem edelsten Marmor Italiens — warmweiß mit goldenen Adern. Jedes Stück zeigt ein einzigartiges Naturmuster. Das Flaggschiff.",
             marmorCat, "Pelczer Manufaktur", "Calacatta Oro Marmor", 30.0),

            // Granit
            ("Baltic Grey", 389.00, "cube",
             "Skandinavischer Granit in kühlem Grau mit Glimmer-Einschlüssen. CNC-gefräst und von Hand poliert. Unverwüstlich und zeitlos.",
             granitCat, "Pelczer Manufaktur", "Skandinavischer Granit", 26.0),

            ("Black Galaxy", 449.00, "cube",
             "Indischer Granit mit goldenen Bronzit-Kristallen, die wie Sterne funkeln. Jede Oberfläche ein Miniatur-Universum.",
             granitCat, "Pelczer Manufaktur", "Black Galaxy Granit", 30.0),

            ("Rosa Beta", 419.00, "cube",
             "Sardischer Granit in warmem Rosa mit schwarzen und weißen Sprenkelungen. Mediterrane Eleganz trifft Funktionalität.",
             granitCat, "Pelczer Manufaktur", "Rosa Beta Granit", 28.0),
        ]

        for (name, price, imageName, desc, category, artist, material, height) in products {
            let product = Product(context: context)
            product.id = UUID()
            product.name = name
            product.price = price
            product.quantity = 1 // Unikat — nur 1 Stück
            product.imageName = imageName
            product.productDescription = desc
            product.category = category
            product.artist = artist
            product.material = material
            product.height = height
            product.isUnique = true
        }

        save()
    }
}
