//
//  ContentView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ProductViewModel()

    var body: some View {
        TabView {
            ProductListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Produkte")
                }

            ShoppingCartView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "cart")
                    Text("Warenkorb")
                }
        }
    }
}


#Preview {
    ContentView()
}
