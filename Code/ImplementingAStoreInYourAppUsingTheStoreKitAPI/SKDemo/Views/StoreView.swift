/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view for the Store.
*/

import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            Section(header: Text("Cars")) {
                ForEach(store.cars, id: \.id) { car in
                    ListCellView(product: car)
                }
            }
            .listStyle(GroupedListStyle())

            SubscriptionsView()
        }
        .navigationTitle("Shop")
    }
}
