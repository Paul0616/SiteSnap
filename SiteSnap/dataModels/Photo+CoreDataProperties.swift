//
//  Photo+CoreDataProperties.swift
//  SiteSnap
//
//  Created by Paul Oprea on 22/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var allPhotosComment: String?
    @NSManaged public var allTagsWasSet: Bool
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var fileSize: Int64
    @NSManaged public var individualComment: String?
    @NSManaged public var latitude: Double
    @NSManaged public var localIdentifierForAllTags: String?
    @NSManaged public var localIdentifierString: String?
    @NSManaged public var longitude: Double
    @NSManaged public var successfulUploaded: Bool
    @NSManaged public var isHidden: Bool
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for tags
extension Photo {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}
