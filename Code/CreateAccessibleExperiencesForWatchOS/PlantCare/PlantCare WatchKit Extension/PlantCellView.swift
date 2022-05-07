/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant cell view.
*/

import SwiftUI

struct PlantCellView: View {
    @EnvironmentObject var plantData: PlantData
    @State var isShowingEditView = false
    var plant: Plant
    
    var plantIndex: Int {
        plantData.plants.firstIndex(where: { $0.id == plant.id })!
    }
    
    var body: some View {
        NavigationLink(destination: PlantEditView(plant: plant).environmentObject(plantData), isActive: $isShowingEditView) {
            PlantContainerView(plant: $plantData.plants[plantIndex])
                .padding()
                .accessibilityAction {
                    isShowingEditView.toggle()
                } label: {
                    Label("Edit", systemImage: "ellipsis.circle")
                }
        }
    }
}

// MARK: - Subviews

struct PlantContainerView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @Binding var plant: Plant
    
    var body: some View {
        if sizeCategory < .extraExtraLarge {
            PlantViewHorizontal(plant: $plant)
        } else {
            PlantViewVertical(plant: $plant)
        }
    }
}

struct PlantViewHorizontal: View {
    @Binding var plant: Plant
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(plant.name)
                .font(.title3)
            HStack() {
                PlantImage(imageName: plant.imageName, size: 65, alignment: .leading)
                    .padding(.trailing, 2)
                PlantTaskList(plant: $plant, alignment: .leading)
            }.padding(.bottom, 2)
            PlantTaskButtons(plant: $plant)
        }
    }
}

struct PlantViewVertical: View {
    @Binding var plant: Plant
    
    var body: some View {
        VStack(alignment: .center) {
            Text(plant.name)
                .font(.title3)
            PlantImage(imageName: plant.imageName, size: 80, alignment: .center)
            PlantTaskList(plant: $plant, alignment: .center)
            PlantTaskButtons(plant: $plant)
        }
    }
}

struct PlantImage: View {
    @Environment(\.sizeCategory) var sizeCategory
    let imageName: String
    let size: CGFloat
    let alignment: Alignment
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(width: size, height: size, alignment: alignment)
            .cornerRadius(16)
    }
}

struct PlantTaskLabel: View {
    let task: PlantTask
    @Binding var plant: Plant

    var body: some View {
        HStack {
            Image(systemName: task.systemImageName)
                .imageScale(.small)
            Text(plant.stringForTask(task: task))
                .accessibilityLabel(plant.accessibilityStringForTask(task: task))
        }
        .lineLimit(3)
        .font(.caption2)
    }
}

struct PlantButton: View {
    let task: PlantTask
    let action: () -> Void
    @State private var isTapped: Bool = false
    
    var body: some View {
        Button(action: {
            self.isTapped.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isTapped.toggle()
            }
            action()
        }) {
            Image(systemName: task.systemImageFillName)
                .foregroundColor(task.color)
                .scaleEffect(isTapped ? 1.5 : 1)
                .animation(nil, value: 0)
                .rotationEffect(.degrees(isTapped ? 360 : 0))
                .animation(.spring(), value: 0)
                .imageScale(.large)
        }
        .buttonStyle(BorderedButtonStyle())
        .accessibilityLabel("Log \(task.name)")
    }
}

struct PlantTaskList: View {
    @Binding var plant: Plant
    let alignment: HorizontalAlignment
    var body: some View {
        VStack(alignment: alignment) {
            PlantTaskLabel(task: .water, plant: $plant)
            PlantTaskLabel(task: .fertilize, plant: $plant)
            PlantTaskLabel(task: .sunlight, plant: $plant)
        }
    }
}

struct PlantTaskButtons: View {
    @Binding var plant: Plant
    var body: some View {
        HStack() {
            PlantButton(task: .water, action: {
                plant.lastWateredDate = Date()
            })
            PlantButton(task: .fertilize, action: {
                plant.lastFertilizedDate = Date()
            })
        }
    }
}

// MARK: - Previews

struct PlantCellView_Previews: PreviewProvider {
    static var plantData = PlantData.shared
    static var previews: some View {
        PlantCellView(plant: plantData.plants.first!)
            .environmentObject(plantData)
            .environment(\.sizeCategory, .extraSmall)
        PlantCellView(plant: plantData.plants.first!)
            .environmentObject(plantData)
        PlantCellView(plant: plantData.plants.first!)
            .environmentObject(plantData)
            .environment(\.sizeCategory, .extraExtraLarge)
    }
}
