/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A detailed view of a product and any related products.
*/

import Foundation
import SwiftUI
import StoreKit

struct ProductDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var store: Store
    @State private var isFuelStoreShowing = false
    
    @State private var carOffsetX: CGFloat = 0
    @State private var isCarHidden = false
    @State private var showSpeed = false

    let product: Product
    
    var emoji: String {
        return store.emoji(for: product.id)
    }
    
    var body: some View {
        ZStack {
            Group {
                VStack {
                    Text(showSpeed ? "\(emoji)💨" : emoji)
                        .font(.system(size: 120))
                        .padding(.bottom, 20)
                        .offset(x: carOffsetX, y: 0)
                        .opacity(isCarHidden ? 0.0 : 1.0)
                    Text(product.description)
                        .padding()
                    Spacer()
                }
                if product.type == .nonConsumable, !store.fuel.isEmpty {
                    fuelView
                }
            }
            .blur(radius: isFuelStoreShowing ? 10 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isFuelStoreShowing = false
                }
            }
            if isFuelStoreShowing {
                VStack {
                    fuelPurchaseView
                    Spacer()
                }
            }
        }
        .navigationTitle(product.displayName)
    }
    
    var fuelPurchaseView: some View {
        FuelStoreView(fuels: store.fuel, onPurchase: { fuel in
            withAnimation {
                isFuelStoreShowing = false
            }
            storeConsumable(fuel)
        })
        .frame(minWidth: 200, maxWidth: sizeClass == .compact ? .infinity : 400)
        .frame(minHeight: 200, maxHeight: 400)
        .background(Color.gray)
        .cornerRadius(15)
        .padding()
    }
    
    var fuelStoreButton: some View {
        return Button(action: {
            isFuelStoreShowing = true
        }) {
            Image(systemName: "bolt.car")
                .font(.system(size: 50))
                .padding(5)
        }
    }
    
    var fuelView: some View {
        VStack {
            Spacer()
            HStack {
                FuelSupplyView(fuels: store.fuel, consumedFuel: { fuel in
                    driveVehicle()
                })
                .padding()
                Spacer()
                fuelStoreButton
                    .padding()
            }
        }
    }
    
    fileprivate func storeConsumable(_ purchasedFuel: Product) {
        let availableFuels = UserDefaults.standard.integer(forKey: purchasedFuel.id)
        UserDefaults.standard.set(availableFuels + 1, forKey: purchasedFuel.id)
    }
    
    fileprivate func driveVehicle() {
        showSpeed = true
        let animationDelay: CGFloat = 0.25
        withAnimation(.spring()) {
            carOffsetX = -UIScreen.main.bounds.size.width
            isCarHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                carOffsetX = UIScreen.main.bounds.size.width
                isCarHidden = false
                showSpeed = false
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation {
                        carOffsetX = 0
                    }
                }
            }
        }
    }
}

extension Date {
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: self)
    }
}
