//
//  Photo+CoreDataProperties.swift
//  SiteSnap
//
//  Created by Paul Oprea on 25/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var localIdentifierString: String?
    @NSManaged public var latitude: Float
    @NSManaged public var longitude: Float
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var comment: Comment?
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