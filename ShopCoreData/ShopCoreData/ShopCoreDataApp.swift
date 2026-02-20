//
//  ShopCoreDataApp.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

@main
struct ShopCoreDataApp: App {
    init() {
        PersistentStore.shared.seedDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
