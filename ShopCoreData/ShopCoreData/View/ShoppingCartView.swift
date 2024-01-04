//
//  ShoppingCartView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct ShoppingCartView: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        NavigationView {
            List(viewModel.cart) { product in
                Text("\(product.name ?? "") - Menge: \(product.quantity)")
            }
            .navigationBarTitle("Warenkorb")
        }
    }
}

struct ShoppingCartView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingCartView(viewModel: ProductViewModel())
    }
}
