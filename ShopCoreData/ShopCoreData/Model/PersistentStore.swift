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
        let bongs = Category(context: context)
        bongs.id = UUID()
        bongs.name = "Bongs"

        let pfeifen = Category(context: context)
        pfeifen.id = UUID()
        pfeifen.name = "Pfeifen"

        let dabRigs = Category(context: context)
        dabRigs.id = UUID()
        dabRigs.name = "Dab Rigs"

        let zubehoer = Category(context: context)
        zubehoer.id = UUID()
        zubehoer.name = "Zubehör"

        // Produkte anlegen — jedes Stück ein Unikat (quantity = 1)
        // Tuple: (name, price, imageName, description, category, artist, material, height)
        let products: [(String, Double, String, String, Category, String, String, Double)] = [
            // Bongs
            ("Nebula Dream", 289.00, "flame",
             "Handgeblasene Borosilikatglas-Bong mit kosmischem Nebel-Design in Blau- und Violetttönen. Diffusor-Downstem für seidenweichen Durchzug. Signiert vom Künstler.",
             bongs, "Glaskunst Müller", "Borosilikatglas", 35.0),

            ("Dragonscale", 349.00, "flame",
             "Massive Bong mit aufwendiger Schuppenstruktur in schimmerndem Grün-Gold. Jede Schuppe einzeln aufgesetzt. Ice-Catcher integriert.",
             bongs, "Glaskunst Müller", "Borosilikatglas", 42.0),

            ("Coral Reef", 219.00, "flame",
             "Filigrane Bong inspiriert von Korallenriffen. Organische Formen in Koralle, Türkis und Weiß. Kompaktes Format, ideal für Sammler.",
             bongs, "Glaskunst Müller", "Borosilikatglas", 28.0),

            ("Obsidian Tower", 399.00, "flame",
             "Mächtige schwarze Bong mit goldenen Einschlüssen. Dreifach-Perkolator für maximale Filtration. Das Flaggschiff der Kollektion.",
             bongs, "Glaskunst Müller", "Borosilikatglas", 48.0),

            ("Aurora Borealis", 269.00, "flame",
             "Farbwechselnde Fumed-Glass-Bong, die mit jedem Gebrauch intensivere Farben entwickelt. Nordlicht-Effekt durch Silber- und Gold-Fuming.",
             bongs, "Glaskunst Müller", "Fumed Glass", 32.0),

            // Pfeifen
            ("Salamander", 89.00, "leaf",
             "Handgeformte Glaspfeife in Form eines Salamanders. Detailreiche Arbeit mit Millefiori-Augen. Liegt perfekt in der Hand.",
             pfeifen, "Glaskunst Müller", "Borosilikatglas", 12.0),

            ("Moonstone Spoon", 69.00, "leaf",
             "Elegante Spoon-Pipe mit opakem Mondstein-Effekt. Farbspiel von Silber bis Hellblau. Jedes Stück ein Unikat durch die Fuming-Technik.",
             pfeifen, "Glaskunst Müller", "Fumed Glass", 10.5),

            ("Twisted Flame", 119.00, "leaf",
             "Spiralförmig gedrehte Pfeife mit flammenrotem Innenleben. Doppelwandig für kühlen Rauch. Aufwendige Inside-Out-Technik.",
             pfeifen, "Glaskunst Müller", "Borosilikatglas", 14.0),

            // Dab Rigs
            ("Micro Reactor", 199.00, "drop",
             "Kompaktes Dab Rig mit Recycler-Funktion. Wissenschaftlich inspiriertes Design. Optimaler Flavor durch kurze Luftwege.",
             dabRigs, "Glaskunst Müller", "Borosilikatglas", 18.0),

            ("Jellyfish", 259.00, "drop",
             "Dab Rig in Quallenform mit leuchtenden UV-reaktiven Tentakeln. Funktionaler Perkolator im Kopf der Qualle.",
             dabRigs, "Glaskunst Müller", "UV-reaktives Glas", 22.0),

            // Zubehör
            ("Volcano Bowl", 49.00, "circle.grid.cross",
             "Handgefertigter Kopf in Vulkanform mit integriertem Glassieb. Passt auf alle 18,8mm Schliffe. Jeder Krater individuell gestaltet.",
             zubehoer, "Glaskunst Müller", "Borosilikatglas", 5.0),

            ("Helix Downstem", 39.00, "circle.grid.cross",
             "Spiralförmiger Downstem mit 6-Schlitz-Diffusor. 18,8mm auf 14,5mm Adapter. Erzeugt einen hypnotischen Wirbeleffekt im Wasser.",
             zubehoer, "Glaskunst Müller", "Borosilikatglas", 13.0),
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
