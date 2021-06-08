/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This test case covers the CoreDataStack and verifies the application's data model
*/

import XCTest
import CoreData
import CoreLocation
@testable import CoreDataCloudKitDemo

class TestCoreDataStack: CoreDataCloudKitDemoUnitTestCase {
    func testSecureLocationTransformer() {
        XCTAssertEqual("SecureCLLocationTransformer", SecureCLLocationTransformer.transformerName.rawValue)
        guard let transformer = ValueTransformer(forName: SecureCLLocationTransformer.transformerName) else {
            XCTFail("Unable to instantiate a value transformer for \(SecureCLLocationTransformer.transformerName)")
            return
        }

        guard let location = AppDelegate.sharedAppDelegate.locationManager.location else {
            XCTFail("This test requires location tracking to be effective.")
            return
        }

        let data = transformer.reverseTransformedValue(location)
        guard let resultLocation = transformer.transformedValue(data) as? CLLocation else {
            XCTFail("Failed to deserialize location from transformer.")
            return
        }

        XCTAssertEqual(location.coordinate.latitude, resultLocation.coordinate.latitude)
        XCTAssertEqual(location.coordinate.longitude, resultLocation.coordinate.longitude)
    }
    
    func testStoreAssignments() {
        XCTAssertNotNil(coreDataStack.privatePersistentStore)
        XCTAssertEqual("private.sqlite", coreDataStack.privatePersistentStore.url?.lastPathComponent)
        
        XCTAssertNotNil(coreDataStack.sharedPersistentStore)
        XCTAssertEqual("shared.sqlite", coreDataStack.sharedPersistentStore.url?.lastPathComponent)
    }
    
    func testModel() throws {
        for (entityName, entity) in coreDataStack.persistentContainer.managedObjectModel.entitiesByName {
            switch entityName {
            case "Post": verifyPost(entity)
            case "Attachment": verifyAttachment(entity)
            case "Tag": verifyTag(entity)
            case "ImageData": verifyImageData(entity)
            default: XCTFail("I don't know how to validate \(entityName), is it new?")
            }
        }
    }

    func testCoreDataStackRegistersForRemoteChangeNotifications() throws {
        let originalContainer = coreDataStack.persistentContainer
        let alternateContainer = NSPersistentContainer(name: "alternateContainer",
                                                       managedObjectModel: originalContainer.managedObjectModel)

        alternateContainer.persistentStoreDescriptions = originalContainer.persistentStoreDescriptions
        alternateContainer.loadPersistentStores(completionHandler: { (loadedStoreDescription, error) in
            if let loadError = error as NSError? {
                fatalError("###\(#function): Failed to load persistent stores:\(loadError)")
            }
        })

        let alternateContext = alternateContainer.viewContext
        alternateContext.transactionAuthor = "AlternateContextAuthor"
        alternateContext.performAndWait {
            let post = NSEntityDescription.insertNewObject(forEntityName: "Post",
                                                           into: alternateContext)
            post.setValue("Such title", forKey: "title")
            post.setValue("Very content.", forKey: "content")

            do {
                try alternateContext.save()
            } catch let error {
                XCTFail("Save failed: \(error)")
            }
        }

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))

        let context = originalContainer.viewContext
        context.performAndWait {
            let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
            let posts = try? context.fetch(fetchRequest)
            let numPosts = UInt32(posts?.count ?? 0)

            XCTAssertEqual(numPosts, 1)
        }
    }
    
    // MARK: Model Validation
    func verifyPost(_ entity: NSEntityDescription) {
        verifyAttribute(named: "title",
                             on: entity,
                             type: .string)
        verifyAttribute(named: "content",
                             on: entity,
                             type: .string)
        verifyAttribute(named: "location",
                             on: entity,
                             type: .transformable,
                             allowsEncryption: true,
                             valueTransformerName: SecureCLLocationTransformer.transformerName,
                             valueClassName: "CoreLocation.\(NSStringFromClass(CLLocation.self))")

        verifyRelationship(named: "attachments",
                                on: entity,
                                destination: "Attachment",
                                inverse: "post",
                                isToMany: true)
        verifyRelationship(named: "tags",
                                on: entity,
                                destination: "Tag",
                                inverse: "posts",
                                isToMany: true)
    }
    
    func verifyAttachment(_ entity: NSEntityDescription) {
        verifyAttribute(named: "thumbnail",
                             on: entity,
                             type: .transformable,
                             valueTransformerName: .secureUnarchiveFromDataTransformerName,
                             valueClassName: "UIKit.\(UIImage.self)")
        verifyAttribute(named: "uuid",
                             on: entity,
                             type: .uuid)
        verifyRelationship(named: "post",
                                on: entity,
                                destination: "Post",
                                inverse: "attachments")
        verifyRelationship(named: "imageData",
                                on: entity,
                                destination: "ImageData",
                                inverse: "attachment")
    }
    
    func verifyTag(_ entity: NSEntityDescription) {
        verifyAttribute(named: "name",
                             on: entity,
                             type: .string)
        verifyAttribute(named: "postCount",
                             on: entity,
                             type: .integer64)
        verifyAttribute(named: "color",
                             on: entity,
                             type: .transformable,
                             valueTransformerName: .secureUnarchiveFromDataTransformerName,
                             valueClassName: "UIKit.\(UIColor.self)")
        verifyAttribute(named: "uuid",
                             on: entity,
                             type: .uuid)
        verifyRelationship(named: "posts",
                                on: entity,
                                destination: "Post",
                                inverse: "tags",
                                isToMany: true)
    }
    
    func verifyImageData(_ entity: NSEntityDescription) {
        verifyAttribute(named: "data",
                             on: entity,
                             type: .binaryData)
        verifyRelationship(named: "attachment",
                                on: entity,
                                destination: "Attachment",
                                inverse: "imageData")
    }
    
    func verifyAttribute(named name: String,
                         on entity: NSEntityDescription,
                         type: NSAttributeDescription.AttributeType,
                         allowsEncryption: Bool? = false,
                         valueTransformerName: NSValueTransformerName? = nil,
                         valueClassName: String? = nil) {
        guard let attribute = entity.attributesByName[name] else {
            XCTFail("\(entity.name!) is missing expected attribute \(name)")
            return
        }
        
        XCTAssertEqual(type, attribute.type)
        XCTAssertEqual(allowsEncryption, attribute.allowsCloudEncryption)
        if .transformable == attribute.type, let expectedValueTransformerName = valueTransformerName {
            XCTAssertEqual(expectedValueTransformerName.rawValue, attribute.valueTransformerName)
            if let expectedValueClassName = valueClassName {
                XCTAssertEqual(expectedValueClassName, attribute.attributeValueClassName)
            } else {
                XCTAssertNil(attribute.attributeValueClassName)
            }
        }
    }
    
    func verifyRelationship(named name: String,
                            on entity: NSEntityDescription,
                            destination destinationEntityName: String,
                            inverse inverseRelationshipName: String,
                            isToMany: Bool? = false) {
        guard let relationship = entity.relationshipsByName[name] else {
            XCTFail("\(entity.name!) is missing expected relationship \(name)")
            return
        }
        
        guard let destinationEntity = relationship.destinationEntity else {
            XCTFail("Relationship \(entity.name!).\(name) is missing expected destination entity \(destinationEntityName)")
            return
        }
        
        XCTAssertEqual(destinationEntityName, destinationEntity.name)
        XCTAssertEqual(inverseRelationshipName, relationship.inverseRelationship?.name)
        XCTAssertNotNil(destinationEntity.relationshipsByName[inverseRelationshipName])
        XCTAssertEqual(isToMany, relationship.isToMany)
    }
}
