//
//  ProductListView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ProductListView: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        NavigationView {
            List(viewModel.products) { product in
                VStack(alignment: .leading) {
                    Text(product.name ?? "")
                    Text("Preis: \(product.price)")
                    Text("Verfügbar: \(product.quantity)")
                }
                .onTapGesture {
                    viewModel.addToCart(product: product)
                }
            }
            .navigationBarTitle("Produktliste")
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView(viewModel: ProductViewModel())
    }
}

