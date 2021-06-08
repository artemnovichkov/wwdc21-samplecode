/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods that aren't part of the Model, but are used frequently interfacing with parts of the UI
*/

import Foundation
import UIKit
import LinkPresentation

// MARK: Images from Image Names -
/// Convenience accessors for looking up images
extension AnyModelItem {
    var iconImage: UIImage? {
        guard let emojiOrName = iconName else { return nil }
        if emojiOrName.isSingleEmoji {
            return emojiOrName.image()
        } else {
            return UIImage(named: emojiOrName) ?? UIImage(systemName: emojiOrName)
        }
    }

    var image: UIImage? {
        imageName.flatMap { UIImage(named: $0) ?? UIImage(systemName: $0) }
    }
}

extension IconNameProviding {
    var iconImage: UIImage? {
        if iconName.isSingleEmoji {
            return iconName.image()
        } else {
            return UIImage(named: iconName) ?? UIImage(systemName: iconName)
        }
    }
}

extension ImageProviding {
    var image: UIImage? { UIImage(named: imageName) ?? UIImage(systemName: imageName) }
}

extension UIActivity.ActivityType {
    static let toggleFavorite = UIActivity.ActivityType("toggleFavorite")
}

class ToggleFavoriteActivity: UIActivity {
    let modelItem: AnyModelItem
    let label: String

    init(modelItem: AnyModelItem) {
        self.label = modelItem.isFavorite ? "Remove from favorites" : "Add to favorites"
        self.modelItem = modelItem
        super.init()
    }

    override var activityTitle: String? { label }
    override var activityType: UIActivity.ActivityType? { .toggleFavorite }
    override var activityImage: UIImage? { UIImage(systemName: modelItem.isFavorite ? "star.fill" : "star") }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }

    override func perform() {
        modelItem.isFavorite.toggle()
    }
}

// MARK: - UIActivityItemsConfigurationReading

extension AnyModelItem: UIActivityItemsConfigurationReading {
    var itemProvidersForActivityItemsConfiguration: [NSItemProvider] {
        if let image = image {
            return [NSItemProvider(object: image)]
        } else {
            return [NSItemProvider(object: name as NSString)]
        }
    }

    func activityItemsConfigurationMetadata(key: UIActivityItemsConfigurationMetadataKey) -> Any? {
        if image != nil {
            switch key {
            case .title:
                return name as NSString
            case .messageBody:
                if let caption = caption { return caption as NSString }
            default:
                break
            }
        }
        return nil
    }

    func activityItemsConfigurationMetadataForItem(at: Int, key: UIActivityItemsConfigurationMetadataKey) -> Any? {
        var retval: LPLinkMetadata? = nil
        switch key {
        case UIActivityItemsConfigurationMetadataKey("linkPresentationMetadata"):
            if let image = image {
                let lpMetadata = LPLinkMetadata()
                lpMetadata.iconProvider = NSItemProvider(object: image)
                lpMetadata.title = name
                retval = lpMetadata
            }
        default:
            break
        }
        return retval
    }

    var applicationActivitiesForActivityItemsConfiguration: [UIActivity]? {
        return [ToggleFavoriteActivity(modelItem: self)]
    }
}
