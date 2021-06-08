/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Detailed information about an album.
*/

import MusicKit
import SwiftUI

/// `AlbumDetailView` is a view that presents detailed information about a specific `Album`.
struct AlbumDetailView: View {
    
    // MARK: - Object lifecycle
    
    init(_ album: Album) {
        self.album = album
    }
    
    // MARK: - Properties
    
    /// The album described by this view.
    let album: Album
    
    /// The tracks belonging to this album.
    @State var tracks: MusicItemCollection<Track>?
    
    /// Albums reported by MusicKit as related to this album.
    @State var relatedAlbums: MusicItemCollection<Album>?
    
    // MARK: - View
    
    var body: some View {
        List {
            header
                .listRowBackground(Color.clear)
                .buttonStyle(PlainButtonStyle())
            
            // Add a list of tracks in the album.
            if let loadedTracks = tracks, !loadedTracks.isEmpty {
                Section(header: Text("Tracks")) {
                    ForEach(loadedTracks) { track in
                        TrackCell(track, from: album) {
                            handleTrackSelected(track, loadedTracks: loadedTracks)
                        }
                    }
                }
            }
            
            // Add a list of related albums.
            if let loadedRelatedAlbums = relatedAlbums, !loadedRelatedAlbums.isEmpty {
                Section(header: Text("Related Albums")) {
                    ForEach(loadedRelatedAlbums) { album in
                        AlbumCell(album)
                    }
                }
            }
        }
        .navigationTitle(album.title)
        
        // When the view appears, load tracks and related albums asynchronously.
        .task {
            RecentAlbumsStorage.shared.update(with: album)
            try? await loadTracksAndRelatedAlbums()
        }
        
        // Start observing changes to playback status.
        .task {
            for await playbackStatus in player.updates(for: \.playbackStatus) {
                isPlaying = (playbackStatus == .playing)
            }
        }
        
        // Start observing changes to music subscription.
        .task {
            for await subscription in MusicSubscription.subscriptionUpdates {
                musicSubscription = subscription
            }
        }
        
        // Display the subscription offer when appropriate.
        .musicSubscriptionOffer(isPresented: $isShowingSubscriptionOffer, options: subscriptionOfferOptions)
    }
    
    // The fixed part of this view's UI.
    private var header: some View {
        VStack {
            if let artwork = album.artwork {
                ArtworkImage(artwork, width: 320)
                    .cornerRadius(8)
            }
            Text(album.artistName)
                .font(.title2.bold())
            playButtonRow
        }
    }
    
    // MARK: - Loading tracks and related albums
    
    /// Loads tracks and related albums asynchronously.
    private func loadTracksAndRelatedAlbums() async throws {
        let detailedAlbum = try await album.with([.artists, .tracks])
        let artist = try await detailedAlbum.artists?.first?.with([.albums])
        await update(tracks: detailedAlbum.tracks, relatedAlbums: artist?.albums)
    }
    
    /// Safely updates `tracks` and `relatedAlbums` properties on the main thread.
    @MainActor
    private func update(tracks: MusicItemCollection<Track>?, relatedAlbums: MusicItemCollection<Album>?) {
        withAnimation {
            self.tracks = tracks
            self.relatedAlbums = relatedAlbums
        }
    }
    
    // MARK: - Playback
    
    /// The MusicKit player used for Apple Music playback.
    private let player = ApplicationMusicPlayer.shared
    
    /// `true` when a playback queue has been set on the player.
    @State var isPlaybackQueueSet = false
    
    /// `true` when the player is playing.
    @State var isPlaying = false
    
    /// The Apple Music subscription of the current user.
    @State var musicSubscription: MusicSubscription?
    
    /// `true` when the Play/Pause button should be disabled.
    private var isPlayButtonDisabled: Bool {
        let canPlayCatalogContent = musicSubscription?.canPlayCatalogContent ?? false
        return !canPlayCatalogContent
    }
    
    /// `true` when an Apple Music subscription should be offered to the user.
    private var shouldOfferSubscription: Bool {
        let canBecomeSubscriber = musicSubscription?.canBecomeSubscriber ?? false
        return canBecomeSubscriber
    }
    
    /// The Play/Pause button, and (if appropriate) the Join button, side by side.
    private var playButtonRow: some View {
        HStack {
            Button(action: handlePlayButtonSelected) {
                HStack {
                    Image(systemName: (isPlaying ? "pause.fill" : "play.fill"))
                    Text((isPlaying ? "Pause" : "Play"))
                }
                .frame(maxWidth: 200)
            }
            .buttonStyle(ProminentButtonStyle())
            .disabled(isPlayButtonDisabled)
            .animation(.easeInOut(duration: 0.1), value: isPlaying)
            
            if shouldOfferSubscription {
                subscriptionOfferButton
            }
        }
    }
    
    /// The action to perform when the Play/Pause button is tapped.
    private func handlePlayButtonSelected() {
        if !isPlaying {
            if !isPlaybackQueueSet {
                player.setQueue(with: album)
                isPlaybackQueueSet = true
            }
            player.play()
        } else {
            player.pause()
        }
    }
    
    /// The action to perform when a track item in a list is tapped.
    private func handleTrackSelected(_ track: Track, loadedTracks: MusicItemCollection<Track>) {
        player.setQueue(with: loadedTracks, startingAt: track)
        isPlaybackQueueSet = true
        player.play()
    }
    
    // MARK: - Subscription offer
    
    private var subscriptionOfferButton: some View {
        Button(action: handleSubscriptionOfferButtonSelected) {
            HStack {
                Image(systemName: "applelogo")
                Text("Join")
            }
            .frame(maxWidth: 200)
        }
        .buttonStyle(ProminentButtonStyle())
    }
    
    /// The state controlling whether a subscription offer is displayed.
    @State private var isShowingSubscriptionOffer = false
    
    /// The options for the Apple Music subscription offer.
    private var subscriptionOfferOptions: MusicSubscriptionOffer.Options {
        return MusicSubscriptionOffer.Options(
            messageIdentifier: .playMusic,
            itemID: album.id
        )
    }
    
    /// Computes the presentation state for a subscription offer.
    private func handleSubscriptionOfferButtonSelected() {
        isShowingSubscriptionOffer = true
    }
}
