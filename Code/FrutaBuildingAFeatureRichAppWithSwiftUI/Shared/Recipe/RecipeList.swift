/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A list of unlocked smoothies' recipes, and a call to action to purchase all recipes.
*/

import SwiftUI

struct RecipeList: View {
    @State private var selection: Smoothie.ID?
    @EnvironmentObject private var model: Model
    
    var smoothies: [Smoothie] {
        Smoothie.all(includingPaid: model.allRecipesUnlocked)
            .filter { $0.matches(model.searchString) }
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
    }
    
    var body: some View {
        List {
            #if os(iOS)
            Section {
                unlockButton
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(EmptyView())
                    .listSectionSeparator(.hidden)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)
            #endif
            
            ForEach(smoothies) { smoothie in
                NavigationLink(tag: smoothie.id, selection: $selection) {
                    RecipeView(smoothie: smoothie)
                } label: {
                    SmoothieRow(smoothie: smoothie)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #elseif os(macOS)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            unlockButton
                .padding(8)
        }
        #endif
        .navigationTitle(Text("Recipes", comment: "Title of the 'recipes' app section showing the list of smoothie recipes"))
        .animation(.spring(response: 1, dampingFraction: 1), value: model.allRecipesUnlocked)
        .accessibilityRotor("Favorite Smoothies", entries: smoothies.filter { model.isFavorite(smoothie: $0) }, entryLabel: \.title)
        .accessibilityRotor("Smoothies", entries: smoothies, entryLabel: \.title)
        .searchable(text: $model.searchString) {
            ForEach(model.searchSuggestions) { suggestion in
                Text(suggestion.name).searchCompletion(suggestion.name)
            }
        }
    }
    
    @ViewBuilder
    var unlockButton: some View {
        Group {
            if !model.allRecipesUnlocked {
                if let product = model.unlockAllRecipesProduct {
                    RecipeUnlockButton(product: .init(for: product), purchaseAction: { model.purchaseProduct(product) })
                } else {
                    RecipeUnlockButton(
                        product: .init(title: "Unlock All Recipes", description: "Loading…", availability: .unavailable),
                        purchaseAction: {}
                    )
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

struct RecipeList_Previews: PreviewProvider {
    static let unlocked: Model = {
        let store = Model()
        store.allRecipesUnlocked = true
        return store
    }()
    static var previews: some View {
        Group {
            NavigationView {
                RecipeList()
            }
            .environmentObject(Model())
            .previewDisplayName("Locked")
            
            NavigationView {
                RecipeList()
            }
            .environmentObject(unlocked)
            .previewDisplayName("Unlocked")
        }
    }
}
