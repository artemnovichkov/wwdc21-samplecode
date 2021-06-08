/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the recipe for a smoothie.
*/

import SwiftUI

struct RecipeView: View {
    var smoothie: Smoothie
    
    @State private var smoothieCount = 1
    
    var backgroundColor: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color(nsColor: .textBackgroundColor)
        #endif
    }
    
    let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    var recipeToolbar: some View {
        StepperView(
            value: $smoothieCount,
            label: "\(smoothieCount) Smoothies",
            configuration: StepperView.Configuration(increment: 1, minValue: 1, maxValue: 9)
        )
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                smoothie.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    }
                    .overlay(alignment: .bottom) { recipeToolbar }
                    
                VStack(alignment: .leading) {
                    Text("Ingredients.recipe", tableName: "Ingredients",
                         comment: "Ingredients in a recipe. For languages that have different words for \"Ingredient\" based on semantic context.")
                        .font(Font.title).bold()
                        .foregroundStyle(.secondary)
                    
                    VStack {
                        ForEach(0 ..< smoothie.measuredIngredients.count) { index in
                            RecipeIngredientRow(measuredIngredient: smoothie.measuredIngredients[index].scaled(by: Double(smoothieCount)))
                                .padding(.horizontal)
                            if index < smoothie.measuredIngredients.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical)
                    .background()
                    .clipShape(shape)
                    .overlay {
                        shape.strokeBorder(.quaternary, lineWidth: 0.5)
                    }
                }
            }
            .padding()
            .frame(minWidth: 200, idealWidth: 400, maxWidth: 400)
            .frame(maxWidth: .infinity)
        }
        .background { backgroundColor.ignoresSafeArea() }
        .navigationTitle(smoothie.title)
        .toolbar {
            SmoothieFavoriteButton(smoothie: smoothie)
        }
    }
}

struct RecipeIngredientRow: View {
    var measuredIngredient: MeasuredIngredient

    @State private var checked = false
    
    var body: some View {
        Button(action: { checked.toggle() }) {
            HStack {
                measuredIngredient.ingredient.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(measuredIngredient.ingredient.thumbnailCrop.scale * 1.25)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(measuredIngredient.ingredient.name).font(.headline)
                    MeasurementView(measurement: measuredIngredient.measurement)
                }

                Spacer()

                Toggle(isOn: $checked) {
                    Text("Complete",
                         comment: "Label for toggle showing whether you have completed adding an ingredient that's part of a smoothie recipe")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .toggleStyle(.circle)
    }
}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeView(smoothie: .thatsBerryBananas)
            .environmentObject(Model())
    }
}
