//
//  Project+CoreDataProperties.swift
//  
//
//  Created by Paul Oprea on 17/01/2019.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Project {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: "Project")
    }

    @NSManaged public var id: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var availableTags: NSSet?

}

// MARK: Generated accessors for availableTags
extension Project {

    @objc(addAvailableTagsObject:)
    @NSManaged public func addToAvailableTags(_ value: Tag)

    @objc(removeAvailableTagsObject:)
    @NSManaged public func removeFromAvailableTags(_ value: Tag)

    @objc(addAvailableTags:)
    @NSManaged public func addToAvailableTags(_ values: NSSet)

    @objc(removeAvailableTags:)
    @NSManaged public func removeFromAvailableTags(_ values: NSSet)

}
