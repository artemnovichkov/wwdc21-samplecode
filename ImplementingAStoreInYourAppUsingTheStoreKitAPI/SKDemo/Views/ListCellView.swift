/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view for an individual Car or Subscription product that shows a buy button when displayed
    within the store, but not when displayed in the MyCars view.
*/

import SwiftUI
import StoreKit

struct ListCellView: View {
    @EnvironmentObject var store: Store
    @State var isPurchased: Bool = false
    @State var errorTitle = ""
    @State var isShowingError: Bool = false

    let product: Product
    let purchasingEnabled: Bool

    var emoji: String {
        store.emoji(for: product.id)
    }

    init(product: Product, purchasingEnabled: Bool = true) {
        self.product = product
        self.purchasingEnabled = purchasingEnabled
    }

    var body: some View {
        HStack {
            Text(emoji)
                .font(.system(size: 50))
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .padding(.trailing, 20)
            if purchasingEnabled {
                productDetail
                Spacer()
                buyButton
                    .buttonStyle(BuyButtonStyle(isPurchased: isPurchased))
                    .disabled(isPurchased)
            } else {
                productDetail
            }
        }
        .alert(isPresented: $isShowingError, content: {
            Alert(title: Text(errorTitle), message: nil, dismissButton: .default(Text("Okay")))
        })
    }

    @ViewBuilder
    var productDetail: some View {
        if product.type == .autoRenewable {
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .bold()
                Text(product.description)
            }
        } else {
            Text(product.description)
                .frame(alignment: .leading)
        }
    }

    func subscribeButton(_ subscription: Product.SubscriptionInfo) -> some View {
        let unit: String
        let plural = 1 < subscription.subscriptionPeriod.value
            switch subscription.subscriptionPeriod.unit {
        case .day:
            unit = plural ? "\(subscription.subscriptionPeriod.value) days" : "day"
        case .week:
            unit = plural ? "\(subscription.subscriptionPeriod.value) weeks" : "week"
        case .month:
            unit = plural ? "\(subscription.subscriptionPeriod.value) months" : "month"
        case .year:
            unit = plural ? "\(subscription.subscriptionPeriod.value) years" : "year"
        @unknown default:
            unit = "period"
        }

        return VStack {
            Text(product.displayPrice)
                .foregroundColor(.white)
                .bold()
                .padding(EdgeInsets(top: -4.0, leading: 0.0, bottom: -8.0, trailing: 0.0))
            Divider()
                .background(Color.white)
            Text(unit)
                .foregroundColor(.white)
                .font(.system(size: 12))
                .padding(EdgeInsets(top: -8.0, leading: 0.0, bottom: -4.0, trailing: 0.0))
        }
    }

    var buyButton: some View {
        Button(action: {
            async {
                await buy()
            }
        }) {
            if isPurchased {
                Text(Image(systemName: "checkmark"))
                    .bold()
                    .foregroundColor(.white)
            } else {
                if let subscription = product.subscription {
                    subscribeButton(subscription)
                } else {
                    Text(product.displayPrice)
                        .foregroundColor(.white)
                        .bold()
                }
            }
        }
        .onAppear {
            async {
                isPurchased = (try? await store.isPurchased(product.id)) ?? false
            }
        }
        .onChange(of: store.purchasedIdentifiers) { identifiers in
            async {
                isPurchased = identifiers.contains(product.id)
            }
        }
    }

    func buy() async {
        do {
            if try await store.purchase(product) != nil {
                withAnimation {
                    isPurchased = true
                }
            }
        } catch StoreError.failedVerification {
            errorTitle = "Your purchase could not be verified by the App Store."
            isShowingError = true
        } catch {
            print("Failed purchase for \(product.id): \(error)")
        }
    }
}
