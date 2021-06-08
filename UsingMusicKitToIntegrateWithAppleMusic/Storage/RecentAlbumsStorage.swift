/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Persistent information about recently viewed albums.
*/

import Combine
import Foundation
import MusicKit

/// `RecentAlbumsStorage` allows storing persistent information about recently viewed albums.
/// It also offers a convenient way to observe those recently viewed albums.
class RecentAlbumsStorage: ObservableObject {
    
    // MARK: - Object lifecycle
    
    /// The shared instance of `RecentAlbumsStorage`.
    static let shared = RecentAlbumsStorage()
    
    // MARK: - Properties
    
    /// A collection of recently viewed albums.
    @Published var recentlyViewedAlbums: MusicItemCollection<Album> = []
    
    /// The `UserDefaults` key for persisting recently viewed album identifiers.
    private let recentlyViewedAlbumIdentifiersKey = "recently-viewed-albums-identifiers"
    
    /// The maximum number of recently viewed albums that may be persisted to `UserDefaults`.
    private let maximumNumberOfRecentlyViewedAlbums = 10
    
    /// Retrieves recently viewed album identifiers from `UserDefaults`.
    private var recentlyViewedAlbumIDs: [MusicItemID] {
        get {
            let rawRecentlyViewedAlbumIdentifiers = UserDefaults.standard.array(forKey: recentlyViewedAlbumIdentifiersKey) ?? []
            let recentlyViewedAlbumIDs = rawRecentlyViewedAlbumIdentifiers.compactMap { identifier -> MusicItemID? in
                var itemID: MusicItemID?
                if let stringIdentifier = identifier as? String {
                    itemID = MusicItemID(stringIdentifier)
                }
                return itemID
            }
            return recentlyViewedAlbumIDs
        }
        set {
            UserDefaults.standard.set(newValue.map(\.rawValue), forKey: recentlyViewedAlbumIdentifiersKey)
            loadRecentlyViewedAlbums()
        }
    }
    
    /// Observer of changes to the current MusicKit authorization status.
    private var musicAuthorizationStatusObserver: AnyCancellable?
    
    // MARK: - Methods
    
    /// Begins observing MusicKit authorization status.
    func beginObservingMusicAuthorizationStatus() {
        musicAuthorizationStatusObserver = WelcomeView.PresentationCoordinator.shared.$musicAuthorizationStatus
            .filter { authorizationStatus in
                return (authorizationStatus == .authorized)
            }
            .sink { [weak self] _ in
                self?.loadRecentlyViewedAlbums()
            }
    }
    
    /// Clears recently viewed album identifiers from `UserDefaults`.
    func reset() {
        self.recentlyViewedAlbumIDs = []
    }
    
    /// Adds an album to the viewed album identifiers in `UserDefaults`.
    func update(with recentlyViewedAlbum: Album) {
        var recentlyViewedAlbumIDs = self.recentlyViewedAlbumIDs
        if let index = recentlyViewedAlbumIDs.firstIndex(of: recentlyViewedAlbum.id) {
            recentlyViewedAlbumIDs.remove(at: index)
        }
        recentlyViewedAlbumIDs.insert(recentlyViewedAlbum.id, at: 0)
        while recentlyViewedAlbumIDs.count > maximumNumberOfRecentlyViewedAlbums {
            recentlyViewedAlbumIDs.removeLast()
        }
        self.recentlyViewedAlbumIDs = recentlyViewedAlbumIDs
    }
    
    /// Updates the recently viewed albums when MusicKit authorization status changes.
    private func loadRecentlyViewedAlbums() {
        let recentlyViewedAlbumIDs = self.recentlyViewedAlbumIDs
        if recentlyViewedAlbumIDs.isEmpty {
            self.recentlyViewedAlbums = []
        } else {
            detach {
                do {
                    let albumsRequest = MusicCatalogResourceRequest<Album>(matching: \.id, memberOf: recentlyViewedAlbumIDs)
                    let albumsResponse = try await albumsRequest.response()
                    await self.updateRecentlyViewedAlbums(albumsResponse.items)
                } catch {
                    print("Failed to load albums for recently viewed album IDs: \(recentlyViewedAlbumIDs)")
                }
            }
        }
        
    }
    
    /// Safely changes `recentlyViewedAlbums` on the main thread.
    @MainActor
    private func updateRecentlyViewedAlbums(_ recentlyViewedAlbums: MusicItemCollection<Album>) {
        self.recentlyViewedAlbums = recentlyViewedAlbums
    }
}
