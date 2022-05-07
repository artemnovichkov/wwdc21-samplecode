/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A smattering of model objects and a type-erased form, `AnyModelObjects` to use when collections are required to be homogeneous.
*/

import Foundation
import CoreLocation

/// A data model protocol. Model objects must implement this protocol to be displayed in the app sidebar
protocol Model {
    var countries: [Country] { get }
    var rewardsPrograms: [RewardsProgram] { get }
}

protocol ItemIdentifierProviding {
    typealias ItemID = String
    var itemID: ItemID { get }
}

protocol ImageProviding {
    var imageName: String { get }
    var altText: String { get }
    var caption: String { get }
}

protocol LocationProviding {
    var location: CLLocation { get }
}

protocol IconNameProviding {
    var iconName: String { get }
}

typealias LocatedItem = ModelItem & ImageProviding & LocationProviding

struct Country: ModelItem, IconNameProviding {
    let itemID: ItemID
    let name: String
    let lodgings: [Lodging]
    let restaurants: [Restaurant]
    let sights: [Sight]
    let iconName: String
}

struct Lodging: LocatedItem, IconNameProviding {
    let itemID: ItemID
    let name: String
    let location: CLLocation
    let priceRange: PriceRange
    let iconName: String
    let imageName: String
    let altText: String
    let caption: String
}

struct Restaurant: LocatedItem, IconNameProviding {
    let itemID: ItemID
    let name: String
    let location: CLLocation
    let priceRange: PriceRange
    let iconName: String
    let imageName: String
    let altText: String
    let caption: String
}

struct PriceRange {
    let lower: Int
    let upper: Int
    let localeIdentifier: String
}

struct Sight: LocatedItem, IconNameProviding {
    let itemID: ItemID
    let name: String
    let location: CLLocation
    let iconName: String
    let imageName: String
    let altText: String
    let caption: String
}

struct RewardsProgram: ModelItem, IconNameProviding, ImageProviding {
    let itemID: ItemID
    let name: String
    let points: Int
    let iconName: String
    let imageName: String
    var altText: String = ""
    var caption: String = ""
}

protocol ModelItem: ItemIdentifierProviding {
    var name: String { get }
}

extension ModelItem {
    var userActivity: NSUserActivity {
       let userActivity = NSUserActivity(activityType: DetailSceneDelegate.activityType)
       userActivity.userInfo = ["itemID": itemID]
       userActivity.title = name
       return userActivity
    }
}

class AnyModelItem: NSObject, ModelItem {
    typealias ItemID = ItemIdentifierProviding.ItemID

    private let wrapped: ModelItem
    var itemID: ItemID { wrapped.itemID }
    var name: String { wrapped.name }

    var imageName: String? { (wrapped as? ImageProviding)?.imageName }

    var altText: String? { (wrapped as? ImageProviding)?.altText }

    var caption: String? { (wrapped as? ImageProviding)?.caption }

    var iconName: String? { (wrapped as? IconNameProviding)?.iconName }

    var location: CLLocation? { (wrapped as? LocationProviding)?.location }

    var country: Country? { wrapped as? Country }
    var lodging: Lodging? { wrapped as? Lodging }
    var restaurant: Restaurant? { wrapped as? Restaurant }
    var locatedItem: LocatedItem? { restaurant ?? lodging ?? sight }
    var sight: Sight? { wrapped as? Sight }
    var rewardsProgram: RewardsProgram? { wrapped as? RewardsProgram }

    var isFavorite = false

    init(_ modelItem: ModelItem) {
        wrapped = modelItem
    }

    override var hash: Int { wrapped.itemID.hash }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? AnyModelItem else { return false }
        return wrapped.itemID == object.itemID
    }
}

extension Model {
    func item(withID itemID: ItemIdentifierProviding.ItemID) -> AnyModelItem? {

        func findItem(in items: [ModelItem]) -> ModelItem? {
            for item in items {
                if item.itemID == itemID { return item }
                if let country = item as? Country {
                    if let found = findItem(in: country.lodgings) ?? findItem(in: country.restaurants) ?? findItem(in: country.sights) {
                        return found
                    }
                }
            }
            return nil

        }
        return (findItem(in: countries) ?? findItem(in: rewardsPrograms)).map(AnyModelItem.init)
    }
}
