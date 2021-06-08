/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's navigation with a configuration that offers a sidebar, content list, and detail pane.
*/

import SwiftUI

struct AppSidebarNavigation: View {

    enum NavigationItem {
        case menu
        case favorites
        case recipes
    }

    @EnvironmentObject private var model: Model
    @State private var presentingRewards: Bool = false
    @State private var selection: NavigationItem? = .menu
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(tag: NavigationItem.menu, selection: $selection) {
                    SmoothieMenu()
                } label: {
                    Label("Menu", systemImage: "list.bullet")
                }
                
                NavigationLink(tag: NavigationItem.favorites, selection: $selection) {
                    FavoriteSmoothies()
                } label: {
                    Label("Favorites", systemImage: "heart")
                }
            
                NavigationLink(tag: NavigationItem.recipes, selection: $selection) {
                    RecipeList()
                } label: {
                    Label("Recipes", systemImage: "book.closed")
                }
            }
            .navigationTitle("Fruta")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Pocket()
            }
            
            Text("Select a category")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background()
                .ignoresSafeArea()
            
            Text("Select a smoothie")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background()
                .ignoresSafeArea()
                .toolbar {
                    SmoothieFavoriteButton(smoothie: nil)
                        .disabled(true)
                }
        }
    }
    
    struct Pocket: View {
        @State private var presentingRewards: Bool = false
        @EnvironmentObject private var model: Model
        
        var body: some View {
            Button(action: { presentingRewards = true }) {
                Label("Rewards", systemImage: "seal")
            }
            .controlSize(.large)
            .buttonStyle(.capsule)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .sheet(isPresented: $presentingRewards) {
                RewardsView()
                    #if os(iOS)
                    .overlay(alignment: .topTrailing) {
                        Button(action: { presentingRewards = false }) {
                            Text("Done", comment: "Button title to dismiss rewards sheet")
                        }
                        .font(.body.bold())
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.capsule)
                        .padding()
                    }
                    #else
                    .frame(minWidth: 400, maxWidth: 600, minHeight: 400, maxHeight: 600)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: { presentingRewards = false }) {
                                Text("Done", comment: "Button title to dismiss rewards sheet")
                            }
                        }
                    }
                    #endif
            }
        }
    }
}

struct AppSidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppSidebarNavigation()
            .environmentObject(Model())
    }
}

struct AppSidebarNavigationPocket_Previews: PreviewProvider {
    static var previews: some View {
        AppSidebarNavigation.Pocket()
            .environmentObject(Model())
            .frame(width: 300)
    }
}
