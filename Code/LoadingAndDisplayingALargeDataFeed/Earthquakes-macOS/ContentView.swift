/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The views of the app, which display details of the fetched earthquake data.
*/

import SwiftUI
import CoreData

struct ContentView: View {
    var quakesProvider: QuakesProvider = .shared

    @AppStorage("lastUpdated")
    private var lastUpdated = Date.distantFuture.timeIntervalSince1970

    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(keyPath: \Quake.time, ascending: false)
    ])
    private var quakes: FetchedResults<Quake>

    @State private var selection: Set<String> = []
    @State private var isLoading = false
    @State private var error: QuakeError?
    @State private var hasError = false

    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(quakes, id: \.code) { quake in
                    NavigationLink(destination: QuakeDetail(quake: quake)) {
                        QuakeRow(quake: quake)
                    }
                }
            }
            .frame(width: 320)
            .navigationTitle("Earthquakes")
            .toolbar(content: toolbarContent)
            
            EmptyView()
        }
        .alert(isPresented: $hasError, error: error) { }
    }
}

// MARK: Core Data

extension ContentView {
    private func deleteQuakes(for codes: Set<String>) async {
        do {
            let quakesToDelete = quakes.filter { codes.contains($0.code) }
            try await quakesProvider.deleteQuakes(quakesToDelete)
        } catch {
            self.error = error as? QuakeError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        selection.removeAll()
    }

    private func fetchQuakes() async {
        isLoading = true
        do {
            try await quakesProvider.fetchQuakes()
            lastUpdated = Date().timeIntervalSince1970
        } catch {
            self.error = error as? QuakeError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        isLoading = false
    }
}

// MARK: Toolbar Content

extension ContentView {
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .status) {
            HStack {
                VStack {
                    if isLoading {
                        Text("Checking for Earthquakes...")
                        Spacer()
                    } else if lastUpdated == Date.distantFuture.timeIntervalSince1970 {
                        Spacer()
                        Text("\(quakes.count) Earthquakes")
                            .foregroundStyle(Color.secondary)
                    } else {
                        let lastUpdatedDate = Date(timeIntervalSince1970: lastUpdated)
                        Text("Updated \(lastUpdatedDate.formatted(.relative(presentation: .named)))")
                        Text("\(quakes.count) Earthquakes")
                            .foregroundStyle(Color.secondary)
                    }
                }
                .font(.caption)
            }
        }
        ToolbarItemGroup(placement: .navigation) {
            Button {
                async {
                    await fetchQuakes()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r")
            .disabled(isLoading)

            Spacer()

            Button {
                async {
                    await deleteQuakes(for: selection)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(isLoading || selection.isEmpty)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let quakesProvider = QuakesProvider.preview
    static var previews: some View {
        ContentView(quakesProvider: quakesProvider)
            .environment(\.managedObjectContext,
                          quakesProvider.container.viewContext)
    }
}
