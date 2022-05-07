/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top level view that allows users to find music they want to rediscover.
*/

import MusicKit
import SwiftUI

struct ContentView: View {
    
    // MARK: - View
    
    var body: some View {
        rootView
            .onAppear(perform: recentAlbumsStorage.beginObservingMusicAuthorizationStatus)
            .onChange(of: searchTerm, perform: requestUpdatedSearchResults)
            .onChange(of: detectedBarcode, perform: handleDetectedBarcode)
            .onChange(of: isDetectedAlbumDetailViewActive, perform: handleDetectedAlbumDetailViewActiveChange)
        
            // Display the barcode scanning view when appropriate.
            .sheet(isPresented: $isBarcodeScanningViewPresented) {
                BarcodeScanningView($detectedBarcode)
            }
        
            // Display the development settings view when appropriate.
            .sheet(isPresented: $isDevelopmentSettingsViewPresented) {
                DevelopmentSettingsView()
            }
        
            // Display the welcome view when appropriate.
            .welcomeSheet()
    }
    
    /// The various components of the main navigation view.
    private var navigationViewContents: some View {
        VStack {
            searchResultsList
                .animation(.default, value: albums)
            if isBarcodeScanningAvailable {
                if albums.isEmpty {
                    Button(action: { isBarcodeScanningViewPresented = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 60, weight: .semibold))
                    }
                }
                if let albumMatchingDetectedBarcode = detectedAlbum {
                    NavigationLink(destination: AlbumDetailView(albumMatchingDetectedBarcode), isActive: $isDetectedAlbumDetailViewActive) {
                        EmptyView()
                    }
                }
            }
        }
    }
    
    /// The top level content view.
    private var rootView: some View {
        NavigationView {
            navigationViewContents
                .navigationTitle("Music Albums")
        }
        .searchable("Albums", text: $searchTerm)
        .gesture(hiddenDevelopmentSettingsGesture)
    }
    
    // MARK: - Search results requesting
    
    /// The current search term entered by the user.
    @State private var searchTerm = ""
    
    /// Albums retrieved by MusicKit that match the current search term.
    @State private var albums: MusicItemCollection<Album> = []
    
    /// Recent albums retrieved by MusicKit for the current search term.
    @StateObject private var recentAlbumsStorage = RecentAlbumsStorage.shared
    
    /// A list of albums to be displayed below the search bar.
    private var searchResultsList: some View {
        List(albums.isEmpty ? recentAlbumsStorage.recentlyViewedAlbums : albums) { album in
            AlbumCell(album)
        }
    }
    
    /// Makes a new search request to MusicKit when the current search term changes.
    private func requestUpdatedSearchResults(for searchTerm: String) {
        detach {
            if searchTerm.isEmpty {
                await self.reset()
            } else {
                do {
                    // Issue a catalog search request for albums matching search term.
                    var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Album.self])
                    searchRequest.limit = 5
                    let searchResponse = try await searchRequest.response()
                    
                    // Update the user interface with search response.
                    await self.apply(searchResponse, for: searchTerm)
                } catch {
                    print("Search request failed with error: \(error).")
                    await self.reset()
                }
            }
        }
    }
    
    /// Safely updates the `albums` property on the main thread.
    @MainActor
    private func apply(_ searchResponse: MusicCatalogSearchResponse, for searchTerm: String) {
        if self.searchTerm == searchTerm {
            self.albums = searchResponse.albums
        }
    }
    
    /// Safely resets the `albums` property on the main thread.
    @MainActor
    private func reset() {
        self.albums = []
    }
    
    // MARK: - Barcode detection handling
    
    /// `true` if the barcode scanning functionality is available to the user.
    @AppStorage("barcode-scanning-available") private var isBarcodeScanningAvailable = true
    
    /// `true` if the barcode scanning view should be shown.
    @State private var isBarcodeScanningViewPresented = false
    
    /// A barcode scanned via the barcode scanning view.
    @State private var detectedBarcode = ""
    
    /// The album matching the scanned barcode, if any.
    @State private var detectedAlbum: Album?
    
    /// `true` if the album detail view should be shown.
    @State private var isDetectedAlbumDetailViewActive = false
    
    /// Searches for an album matching a scanned barcode.
    private func handleDetectedBarcode(_ detectedBarcode: String) {
        if detectedBarcode.isEmpty {
            self.detectedAlbum = nil
        } else {
            detach {
                do {
                    // DEMO: Request albums matching detectedBarcode.
                    
                    let albumsRequest = MusicCatalogResourceRequest<Album>(matching: \.upc, equalTo: detectedBarcode)
                    let albumsResponse = try await albumsRequest.response()
                    if let firstAlbum = albumsResponse.items.first {
                        await self.handleDetectedAlbum(firstAlbum)
                    }
                } catch {
                    print("Encountered error while trying to find albums with upc = \"\(detectedBarcode)\".")
                }
            }
        }
    }
    
    /// Safely updates state properties on the main thread.
    @MainActor
    private func handleDetectedAlbum(_ detectedAlbum: Album) {
        
        // Dismiss barcode scanning view.
        self.isBarcodeScanningViewPresented = false
        
        // Push album detail view for detected album.
        self.detectedAlbum = detectedAlbum
        withAnimation {
            self.isDetectedAlbumDetailViewActive = true
        }
        
    }
    
    /// Clears the scanned barcode when the album detail view is hidden or shown.
    private func handleDetectedAlbumDetailViewActiveChange(_ isDetectedAlbumDetailViewActive: Bool) {
        if !isDetectedAlbumDetailViewActive {
            self.detectedBarcode = ""
        }
    }
    
    // MARK: - Development settings
    
    /// `true` if the development settings view should be presented.
    @State var isDevelopmentSettingsViewPresented = false
    
    /// A custom gesture used to cause the development settings view to be presented.
    private var hiddenDevelopmentSettingsGesture: some Gesture {
        TapGesture(count: 3).onEnded {
            isDevelopmentSettingsViewPresented = true
        }
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
