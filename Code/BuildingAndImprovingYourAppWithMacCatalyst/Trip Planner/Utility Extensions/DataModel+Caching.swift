/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension to ImageProviding to cache the computed downsampled color and image, indexed by itemID.
            This extension helps to improve peformance.
*/

import UIKit
import Foundation

private struct ObjectCache<T: NSObject> {
    private let cache: NSCache<NSString, T>

    init(cacheCountLimit: Int = 20) {
        let cache = NSCache<NSString, T>()
        cache.countLimit = cacheCountLimit
        self.cache = cache
    }

    func retrieveCachedObject(item: ImageProviding, objectLoader: () -> T?) -> T? {
        var retval: T? = nil
        if let itemIdentifierProviding = item as? ItemIdentifierProviding {
            let itemID = itemIdentifierProviding.itemID as NSString
            if let cachedObject = cache.object(forKey: itemID) {
                retval = cachedObject
            } else {
                if let object = objectLoader() {
                    cache.setObject(object, forKey: itemID)
                    retval = object
                }
            }
        } else {
            retval = objectLoader()
        }
        return retval
    }
}

private let colorCache = ObjectCache<UIColor>()

extension ImageProviding {
    var downsampledColor: UIColor? {
        return colorCache.retrieveCachedObject(item: self) {
            image?.downsampledColor
        }
    }
}
