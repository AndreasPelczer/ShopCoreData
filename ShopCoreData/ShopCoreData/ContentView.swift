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
        }
        .tint(.smokyQuartz)
    }
}

#Preview {
    ContentView()
}
