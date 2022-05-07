/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The asset store.
*/

import Foundation
import UIKit
import Combine
import UniformTypeIdentifiers

extension Publisher where Failure == Never {
    // Like `replaceNil` but allows for passing a fallback publisher.
    func flatMapIfNil<DS: Publisher>(_ downstream: @escaping () -> DS)
        -> Publishers.FlatMap<AnyPublisher<DS.Output, DS.Failure>, Publishers.SetFailureType<Self, DS.Failure>>
    where DS.Output? == Output {
        return self.flatMap { opt in
            if let wrapped = opt {
                return Just(wrapped).setFailureType(to: DS.Failure.self).eraseToAnyPublisher()
            } else {
                return downstream().eraseToAnyPublisher()
            }
        }
    }
}

extension Publisher {
    /// Calls a function and returns the same output as upstream.
    func withOutput(execute: @escaping (Output) -> Void) -> Publishers.Map<Self, Output> {
        self.map { output in
            execute(output)
            return output
        }
    }
}

class AssetStore: ModelStore {
    static let placeholderFallbackImage = UIImage(systemName: "airplane.circle.fill")!
    
    private let lock = UnfairLock()
    private let preparedImages = MemoryLimitedCache()
    
    private let localAssets: FileBasedCache
    public let placeholderStore: FileBasedCache
    private let placeholderQueue = DispatchQueue(label: "com.apple.DestinationUnlocked.placeholderGenerationQueue",
                                                 qos: .utility,
                                                 attributes: [],
                                                 autoreleaseFrequency: .workItem,
                                                 target: nil)
    
    init(fileManager: FileManager = .default) {
        let cachesDirectory = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("asset-images", isDirectory: true)
        let placeholdersDirectory = cachesDirectory.appendingPathComponent("placeholders", isDirectory: true)
        
        self.localAssets = FileBasedCache(directory: cachesDirectory, fileManager: fileManager)
        try! localAssets.createDirectoryIfNeeded()
        
        self.placeholderStore = PlaceholderStore(directory: placeholdersDirectory,
                                                 imageFormat: UTType.jpeg,
                                                 fileManager: fileManager)
        try! placeholderStore.createDirectoryIfNeeded()
        
    }
    
    func fetchByID(_ id: Asset.ID) -> Asset {
        if let image = preparedImages.fetchByID(id) {
            return image
        }
        
        return placeholderStore.fetchByID(id) ?? Asset(id: id, isPlaceholder: true, image: Self.placeholderFallbackImage)
    }
    
    func loadAssetByID(_ id: Asset.ID, completionHandler: (() -> Void)? = nil) -> AnyCancellable {
        if let assertion = preparedImages.takeAssertionForID(id) {
            completionHandler?()
            return assertion
        }
        
        var prepareImagesCancellation: AnyCancellable? = nil
        let downloadCancellation = prepareAssetIfNeeded(id: id)
            .sink { _ in
                // Take an assertion on the prepared image so that the cell
                // can easily access the image when it's reconfigured.
                prepareImagesCancellation = self.preparedImages.takeAssertionForID(id)
                completionHandler?()
            }
        
        return AnyCancellable {
            downloadCancellation.cancel()
            prepareImagesCancellation?.cancel()
        }
    }
    
    enum AssetError: Swift.Error {
        case preparingImageFailed
    }
    
    // Cache the current requests to ensure only one image is processing for
    // each asset at a time.
    private var requestsCache: [Asset.ID: Publishers.Share<AnyPublisher<Asset, Never>>] = [:]
    func prepareAssetIfNeeded(id: Asset.ID) -> Publishers.Share<AnyPublisher<Asset, Never>> {
        // Check the current requests for a match.
        if let request = requestsCache[id] {
            return request
        }
        
        // Start a new preparation if there is not a cached one.
        let publisher = self.prepareAsset(id: id)
            .subscribe(on: Self.networkingQueue)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] _ in
                // When the operation is complete, remove the current request.
                self?.requestsCache.removeValue(forKey: id)
            })
            .assertNoFailure("Downloading Asset (id: \(id)")
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .share()
        requestsCache[id] = publisher
        return publisher
    }
    
    func prepareAsset(id: Asset.ID) -> AnyPublisher<Asset, Error> {
        // First check the local cache for the image.
        return Just(self.localAssets.fetchByID(id))
            // If there is no local asset, then download it from the server.
            .flatMapIfNil { self.makeDownloadRequest(id: id) }
            .tryMap { (asset: Asset) -> Asset in
                // Begin preparing the image on this queue (see `subscribe(on: DispatchQueue)`)
                guard let preparedImage = asset.image.preparingForDisplay() else {
                    throw AssetError.preparingImageFailed
                }
                return asset.withImage(preparedImage)
            }
            // Cache the prepared image.
            .withOutput(execute: self.preparedImages.add(asset:))
            .eraseToAnyPublisher()
    }
    
    private func makeDownloadRequest(id: Asset.ID) -> AnyPublisher<Asset, Error> {
        let url = self.localAssets.url(forID: id)
        return Self.makeAssetDownload(for: id, to: url)
            .tryMap { () -> Asset in
                // After download completes, ensure the local cache has
                // the asset.
                guard let asset = self.localAssets.fetchByID(id) else {
                    throw CocoaError(.fileNoSuchFile)
                }
                self.placeholderQueue.async {
                    // Start generating a placeholder image to use in the future.
                    self.placeholderStore.addByMovingFromURL(url, forAsset: id)
                }
                return asset
            }.eraseToAnyPublisher()
    }
    
    // MARK: Sample Code Specific
    
    // Make a queue for fake network download to use.
    static let networkingQueue = DispatchQueue(label: "com.example.API.networking-queue",
                                                       qos: .userInitiated,
                                                       attributes: [],
                                                       autoreleaseFrequency: .workItem,
                                                       target: nil)
    // Start "downloading" the image.
    // For the sample code, pull the image from the main Bundle.
    // Replace this with an actual download from a server. For an example, see the `DownloadTaskPublisher` included with
    // this code.
    static func makeAssetDownload(for assetID: Asset.ID, to destinationURL: URL) -> AnyPublisher<Void, Error> {
        Just(assetID)
            .delay(for: .seconds(.random(in: 1..<6)), scheduler: self.networkingQueue)
            .share()
            .tryMap { assetID in
                guard let url = Bundle.main.url(forResource: assetID, withExtension: "jpg") else {
                    throw CocoaError(.fileNoSuchFile)
                }
                try? FileManager.default.copyItem(at: url, to: destinationURL)
            }
            .eraseToAnyPublisher()
    }
}
