/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant edit view.
*/

import SwiftUI

struct PlantEditView: View {
    @EnvironmentObject var plantData: PlantData
    var plant: Plant
    
    var plantIndex: Int {
        plantData.plants.firstIndex(where: { $0.id == plant.id })!
    }
    
    var body: some View {
        List {
            PlantTaskFrequency(task: .water, plant: $plantData.plants[plantIndex], increment: {
                plantData.plants[plantIndex].wateringFrequency += 1
            }, decrement: {
                plantData.plants[plantIndex].wateringFrequency -= 1
            })
            PlantTaskFrequency(task: .fertilize, plant: $plantData.plants[plantIndex], increment: {
                plantData.plants[plantIndex].fertilizingFrequency += 1
            }, decrement: {
                plantData.plants[plantIndex].fertilizingFrequency -= 1
            })
        }
        .navigationBarTitle(plant.name)
        .listStyle(EllipticalListStyle())
    }
}

struct PlantTaskFrequency: View {
    let task: PlantTask
    @Binding var plant: Plant
    let increment: () -> Void
    let decrement: () -> Void
    
    var value: Int {
        switch task {
        case .water:
            return plant.wateringFrequency
        case .fertilize:
            return plant.fertilizingFrequency
        default:
            return 0
        }
    }
    
    var body: some View {
        Section(header: Text("\(task.name) frequency in days"), content: {
            CustomCounter(value: value, increment: increment, decrement: decrement)
                .accessibilityElement()
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        increment()
                    case .decrement:
                        decrement()
                    default:
                        break
                    }
                }
                .accessibilityLabel("\(task.name) frequency")
                .accessibilityValue("\(value) days")
        })
    }
}

struct CustomCounter: View {
    var value: Int
    let increment: () -> Void
    let decrement: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                decrement()
            }) {
                Image(systemName: "minus")
                    .resizable()
                    .symbolVariant(.circle)
                    .imageScale(.large)
                    .frame(width: 25, height: 25)
                    .padding(5)
            }.buttonStyle(PlainButtonStyle())
            
            Spacer()
            Text("\(value)").font(.title3)
            Spacer()
            
            Button(action: {
                increment()
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .symbolVariant(.circle)
                    .imageScale(.large)
                    .frame(width: 25, height: 25)
                    .padding(5)
            }.buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Previews

struct PlantEditView_Previews: PreviewProvider {
    static var plantData = PlantData.shared
    static var previews: some View {
        PlantEditView(plant: plantData.plants.first!)
            .environmentObject(plantData)
    }
}
