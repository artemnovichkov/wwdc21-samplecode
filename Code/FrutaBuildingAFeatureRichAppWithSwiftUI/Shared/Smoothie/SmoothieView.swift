/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The smoothie detail view that offers the smoothie for sale and lists its ingredients.
*/

import SwiftUI

#if APPCLIP
import StoreKit
#endif

struct SmoothieView: View {
    var smoothie: Smoothie
    
    @State private var presentingOrderPlacedSheet = false
    @State private var presentingSecurityAlert = false
    @EnvironmentObject private var model: Model
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedIngredientID: Ingredient.ID?
    @State private var topmostIngredientID: Ingredient.ID?
    @Namespace private var namespace
    
    #if APPCLIP
    @State private var presentingAppStoreOverlay = false
    #endif
    
    var body: some View {
        container
            #if os(macOS)
            .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            #endif
            .background()
            .navigationTitle(smoothie.title)
            .toolbar {
                SmoothieFavoriteButton(smoothie: smoothie)
            }
            .sheet(isPresented: $presentingOrderPlacedSheet) {
                OrderPlacedView()
                    #if os(macOS)
                    .clipped()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: { presentingOrderPlacedSheet = false }) {
                                Text("Done", comment: "Button to dismiss the confirmation sheet after placing an order")
                            }
                        }
                    }
                    #else
                    .overlay(alignment: .topTrailing) {
                        Button {
                            presentingOrderPlacedSheet = false
                        } label: {
                            Text("Done", comment: "Button to dismiss the confirmation sheet after placing an order")
                        }
                        .font(.body.bold())
                        .buttonStyle(.capsule)
                        .keyboardShortcut(.defaultAction)
                        .padding()
                    }
                    #endif
            }
            .alert(isPresented: $presentingSecurityAlert) {
                Alert(
                    title: Text("Payments Disabled",
                                comment: "Title of alert dialog when payments are disabled"),
                    message: Text("The Fruta QR code was scanned too far from the shop, payments are disabled for your protection.",
                                  comment: "Explanatory text of alert dialog when payments are disabled"),
                    dismissButton: .default(Text("OK",
                                                 comment: "OK button of alert dialog when payments are disabled"))
                )
            }
    }
    
    var container: some View {
        ZStack {
            ScrollView {
                content
                    #if os(macOS)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    #endif
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            .accessibility(hidden: selectedIngredientID != nil)

            if selectedIngredientID != nil {
                Rectangle().fill(.regularMaterial).ignoresSafeArea()
            }
            
            ForEach(smoothie.menuIngredients) { measuredIngredient in
                let presenting = selectedIngredientID == measuredIngredient.id
                IngredientCard(ingredient: measuredIngredient.ingredient, presenting: presenting, closeAction: deselectIngredient)
                    .matchedGeometryEffect(id: measuredIngredient.id, in: namespace, isSource: presenting)
                    .aspectRatio(0.75, contentMode: .fit)
                    .shadow(color: Color.black.opacity(presenting ? 0.2 : 0), radius: 20, y: 10)
                    .padding(20)
                    .opacity(presenting ? 1 : 0)
                    .zIndex(topmostIngredientID == measuredIngredient.id ? 1 : 0)
                    .accessibilityElement(children: .contain)
                    .accessibility(sortPriority: presenting ? 1 : 0)
                    .accessibility(hidden: !presenting)
            }
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            SmoothieHeaderView(smoothie: smoothie)
                
            VStack(alignment: .leading) {
                Text("Ingredients.menu",
                     tableName: "Ingredients",
                     comment: "Ingredients in a smoothie. For languages that have different words for \"Ingredient\" based on semantic context.")
                    .font(Font.title).bold()
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16, alignment: .top)], alignment: .center, spacing: 16) {
                    ForEach(smoothie.menuIngredients) { measuredIngredient in
                        let ingredient = measuredIngredient.ingredient
                        let presenting = selectedIngredientID == measuredIngredient.id
                        Button(action: { select(ingredient: ingredient) }) {
                            IngredientGraphic(ingredient: measuredIngredient.ingredient, style: presenting ? .cardFront : .thumbnail)
                                .matchedGeometryEffect(
                                    id: measuredIngredient.id,
                                    in: namespace,
                                    isSource: !presenting
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.squishable(fadeOnPress: false))
                        .aspectRatio(1, contentMode: .fit)
                        .zIndex(topmostIngredientID == measuredIngredient.id ? 1 : 0)
                        .accessibility(label: Text("\(ingredient.name) Ingredient",
                                                   comment: "Accessibility label for collapsed ingredient card in smoothie overview"))
                    }
                }
            }
            .padding()
        }
    }
    
    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Group {
                if let account = model.account, account.canRedeemFreeSmoothie {
                    RedeemSmoothieButton(action: redeemSmoothie)
                } else {
                    PaymentButton(action: orderSmoothie)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
        }
        .background(.bar)
    }
    
    func orderSmoothie() {
        guard model.isApplePayEnabled else {
            presentingSecurityAlert = true
            return
        }
        model.orderSmoothie(smoothie)
        presentingOrderPlacedSheet = true
    }
    
    func redeemSmoothie() {
        model.redeemSmoothie(smoothie)
        presentingOrderPlacedSheet = true
    }
    
    func select(ingredient: Ingredient) {
        topmostIngredientID = ingredient.id
        withAnimation(.openCard) {
            selectedIngredientID = ingredient.id
        }
    }
    
    func deselectIngredient() {
        withAnimation(.closeCard) {
            selectedIngredientID = nil
        }
    }
}

struct SmoothieView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SmoothieView(smoothie: .berryBlue)
            }
            
            ForEach([Smoothie.thatsBerryBananas, .oneInAMelon, .berryBlue]) { smoothie in
                SmoothieView(smoothie: smoothie)
                    .previewLayout(.sizeThatFits)
                    .frame(height: 700)
            }
        }
        .environmentObject(Model())
    }
}
