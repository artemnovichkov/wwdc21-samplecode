/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view showing all the user's purchased cars and subscriptions.
*/

import SwiftUI
import StoreKit

struct MyCarsView: View {
    @EnvironmentObject var store: Store

    @State var cars: [Product] = []
    @State var subscriptions: [Product] = []

    var body: some View {
        VStack {
            if cars.isEmpty && subscriptions.isEmpty {
                Text("You don't own any car products. Head over to the car shop to get started!")
                    .font(.headline)
                    .padding()
                    .multilineTextAlignment(.center)
                shopLink
            } else {
                List {
                    if !cars.isEmpty {
                        Section(header: Text("My Cars")) {
                            ForEach(cars, id: \.id) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ListCellView(product: product, purchasingEnabled: false)
                                }
                            }
                        }
                    }

                    if !subscriptions.isEmpty {
                        Section(header: Text("My Subscriptions")) {
                            ForEach(subscriptions, id: \.id) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ListCellView(product: product, purchasingEnabled: false)
                                }
                            }
                        }
                    }
                }
            }
            Button("Restore Purchases", action: {
                async {
                    //This call displays a system prompt that asks users to authenticate with their App Store credentials.
                    //Call this function only in response to an explicit user action, such as tapping a button.
                    try? await AppStore.sync()
                }
            })
        }
        .navigationTitle("My Cars")
        .onAppear {
            async {
                //When this view appears, get all the purchased products to display.
                await refreshPurchasedProducts()
            }
        }
    }

    var shopLink: some View {
        let shopView = StoreView()
        return NavigationLink(destination: shopView) {
            Text("\(Image(systemName: "cart")) Shop")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 50)
                .background(Color.blue)
                .cornerRadius(15.0)
        }
    }

    @MainActor
    fileprivate func refreshPurchasedProducts() async {
        var purchasedCars: [Product] = []
        var purchasedSubscriptions: [Product] = []

        //Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            //Don't operate on this transaction if it's not verified.
            if case .verified(let transaction) = result {
                //Check the `productType` of the transaction and get the corresponding product from the store.
                switch transaction.productType {
                case .nonConsumable:
                    if let car = store.cars.first(where: { $0.id == transaction.productID }) {
                        purchasedCars.append(car)
                    }
                case .autoRenewable:
                    if let subscription = store.subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    //This type of product isn't displayed in this view.
                    break
                }
            }
        }

        //Update the view.
        cars = purchasedCars
        subscriptions = purchasedSubscriptions
    }
}
