/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view presented to the user once they order a smoothie, and when it's ready to be picked up.
*/

import SwiftUI
import AuthenticationServices
import StoreKit

struct OrderPlacedView: View {
    @EnvironmentObject private var model: Model
    
    #if APPCLIP
    @State private var presentingAppStoreOverlay = false
    #endif
    
    var orderReady: Bool {
        guard let order = model.order else { return false }
        return order.isReady
    }
    
    var presentingBottomBanner: Bool {
        #if APPCLIP
        if presentingAppStoreOverlay { return true }
        #endif
        return !model.hasAccount
    }
    
/// - Tag: ActiveCompilationConditionTag
    var body: some View {

        VStack(spacing: 0) {
            Spacer()
            
            orderStatusCard
            
            Spacer()
            
            if presentingBottomBanner {
                bottomBanner
            }
            
            #if APPCLIP
            Text(verbatim: "App Store Overlay")
                .hidden()
                .appStoreOverlay(isPresented: $presentingAppStoreOverlay) {
                    SKOverlay.AppClipConfiguration(position: .bottom)
                }
            #endif
        }
        .onChange(of: model.hasAccount) { _ in
            #if APPCLIP
            if model.hasAccount {
                presentingAppStoreOverlay = true
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                if let order = model.order {
                    order.smoothie.image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color("order-placed-background")
                }
                
                if model.order?.isReady == false {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            }
            .ignoresSafeArea()
        }
        .animation(.spring(response: 0.25, dampingFraction: 1), value: orderReady)
        .animation(.spring(response: 0.25, dampingFraction: 1), value: model.hasAccount)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.model.orderReadyForPickup()
            }
            #if APPCLIP
            if model.hasAccount {
                presentingAppStoreOverlay = true
            }
            #endif
        }
    }
    
    var orderStatusCard: some View {
        FlipView(visibleSide: orderReady ? .back : .front) {
            Card(
                title: "Thank you for your order!",
                subtitle: "We will notify you when your order is ready."
            )
        } back: {
            let smoothieName = model.order?.smoothie.title ?? String(localized: "Smoothie", comment: "Fallback name for smoothie")
            Card(
                title: "Your smoothie is ready!",
                subtitle: "\(smoothieName) is ready to be picked up."
            )
        }
        .animation(.flipCard, value: orderReady)
        .padding()
    }
    
    var bottomBanner: some View {
        VStack {
            if !model.hasAccount {
                Text("Sign up to get rewards!")
                    .font(Font.headline.bold())
                
                SignInWithAppleButton(.signUp, onRequest: { _ in }, onCompletion: model.authorizeUser)
                    .frame(minWidth: 100, maxWidth: 400)
                    .padding(.horizontal, 20)
                    #if os(iOS)
                    .frame(height: 45)
                    #endif
            } else {
                #if APPCLIP
                if presentingAppStoreOverlay {
                    Text("Get the full smoothie experience!")
                        .font(Font.title2.bold())
                        .padding(.top, 15)
                        .padding(.bottom, 150)
                }
                #endif
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
    
    struct Card: View {
        var title: LocalizedStringKey
        var subtitle: LocalizedStringKey
        
        var body: some View {
            VStack(spacing: 16) {
                Text(title)
                    .font(Font.title.bold())
                    .textCase(.uppercase)
                    .layoutPriority(1)
                Text(subtitle)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .frame(width: 300, height: 300)
            .background(in: Circle())
        }
    }
}

struct OrderPlacedView_Previews: PreviewProvider {
    static let orderReady: Model = {
        let model = Model()
        model.orderSmoothie(Smoothie.berryBlue)
        model.orderReadyForPickup()
        return model
    }()
    static let orderNotReady: Model = {
        let model = Model()
        model.orderSmoothie(Smoothie.berryBlue)
        return model
    }()
    static var previews: some View {
        Group {
            #if !APPCLIP
            OrderPlacedView()
                .environmentObject(orderNotReady)
            
            OrderPlacedView()
                .environmentObject(orderReady)
            #endif
        }
    }
}
