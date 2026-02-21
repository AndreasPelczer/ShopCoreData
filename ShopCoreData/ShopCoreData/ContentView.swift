//
//  ContentView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var productViewModel = ProductViewModel()
    @StateObject var cartViewModel = CartViewModel()
    @StateObject var orderViewModel = OrderViewModel()

    var body: some View {
        TabView {
            ProductListView(viewModel: productViewModel, cartViewModel: cartViewModel)
                .tabItem {
                    Image(systemName: "flame")
                    Text("Galerie")
                }

            FavoritesView(viewModel: productViewModel, cartViewModel: cartViewModel)
                .tabItem {
                    Image(systemName: "heart")
                    Text("Wunschliste")
                }
                .badge(productViewModel.favoriteProducts.count)

            ShoppingCartView(cartViewModel: cartViewModel, orderViewModel: orderViewModel)
                .tabItem {
                    Image(systemName: "cart")
                    Text("Warenkorb")
                }
                .badge(cartViewModel.totalItemCount)

            OrderHistoryView(orderViewModel: orderViewModel)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Bestellungen")
                }

            ContactView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Kontakt")
                }

            AdminDashboardView(productViewModel: productViewModel, orderViewModel: orderViewModel)
                .tabItem {
                    Image(systemName: "paintbrush.pointed")
                    Text("Atelier")
                }
        }
        .tint(.smokyQuartz)
    }
}

#Preview {
    ContentView()
}
