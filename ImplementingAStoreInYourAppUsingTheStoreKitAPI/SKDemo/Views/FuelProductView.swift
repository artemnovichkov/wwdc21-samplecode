/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A product view for an individual fuel type.
*/

import SwiftUI
import StoreKit

struct FuelProductView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var store: Store
    @State private var errorTitle = ""
    @State private var isShowingError = false

    let fuel: Product
    let onPurchase: (Product) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(store.emoji(for: fuel.id))
                .font(.system(size: 120))
            Text(fuel.description)
                .bold()
                .foregroundColor(Color.black)
                .clipShape(Rectangle())
                .padding(10)
                .background(Color.yellow)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
                .padding(.bottom, 5)
            buyButton
                .buttonStyle(BuyButtonStyle())
        }
        .alert(isPresented: $isShowingError, content: {
            Alert(title: Text(errorTitle), message: nil, dismissButton: .default(Text("Okay")))
        })
    }

    var buyButton: some View {
        Button(action: {
            async {
                await purchase()
            }
        }) {
            Text(fuel.displayPrice)
                .foregroundColor(.white)
                .bold()
        }
    }

    @MainActor
    func purchase() async {
        do {
            if try await store.purchase(fuel) != nil {
                onPurchase(fuel)
            }
        } catch StoreError.failedVerification {
            errorTitle = "Your purchase could not be verified by the App Store."
            isShowingError = true
        } catch {
            print("Failed fuel purchase: \(error)")
        }
    }
}
