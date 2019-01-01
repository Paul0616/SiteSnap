//
//  PhotoHandler.swift
//  SiteSnap
//
//  Created by Paul Oprea on 30/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import CoreData

class PhotoHandler: NSObject {
    private class func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    class func savePhoto(localIdentifier: String, creationDate: Date, latitude: Double?, longitude: Double?) -> Bool{
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)
        let managedObject = NSManagedObject(entity: entity!, insertInto: context)
        managedObject.setValue(localIdentifier, forKey: "localIdentifierString")
        managedObject.setValue(creationDate, forKey: "createdDate")
        if let lat = latitude {
            managedObject.setValue(lat, forKey: "latitude")
        }
        if let long = longitude {
            managedObject.setValue(long, forKey: "longitude")
        }
        do {
            try context.save()
            return true
        } catch  {
            return false
        }
    }
    
    class func fetchAllObjects() -> [Photo]? {
        let context = getContext()
        var photos: [Photo]? = nil
        do {
            photos = try context.fetch(Photo.fetchRequest())
            return photos
        } catch  {
            return photos
        }
    }
    class func updateComment(localIdentifier: String, comment: String) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                object.individualComment = comment
            }
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    class func getSpecificPhoto(localIdentifier: String) -> Photo! {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchRequest)
            
            return objects.first
        } catch _ {
            return nil
        }
    }
    class func updateAllComments(comment: String) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                object.allPhotosComment = comment
            }
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    class func resetComments() -> Bool {
        let context = getContext()
        
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                object.allPhotosComment = nil
            }
            try context.save()
            return true
        } catch _ {
           return false
        }
    }
    class func removePhoto(localIdentifier: String) -> Bool {
        let context = getContext()
        let fetchDeleteRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchDeleteRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchDeleteRequest)
            for object in objects {
                context.delete(object)
            }
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    class func deleteAllPhotos() -> Bool {
        let context = getContext()
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest )
        
        do {
            try context.execute(batchDeleteRequest)
            return true
        } catch {
            return false
        }
    }
    class func getTags(localIdentifier: String) -> [TagModel]! {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchRequest)
            let photo = objects.first!
            var returnedTags = [TagModel]()
            var tagModel: TagModel
            for tag in TagHandler.fetchObject()! {
                if (tag.photos?.contains(photo))! {
                    tagModel = TagModel(tag: tag, selected: true)!
                } else {
                    tagModel = TagModel(tag: tag, selected: false)!
                }
                returnedTags.append(tagModel)
            }
            return returnedTags
        } catch _ {
            return nil
        }
    }
    class func getAllTagsPhotoIdentifier(localIdentifier: String) -> String! {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchRequest)
            let photo = objects.first!
            
            return photo.localIdentifierForAllTags
        } catch _ {
            return nil
        }
    }
    
    class func allTagsWasSet(localIdentifier: String) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchRequest)
            let photo = objects.first!
            
            return photo.allTagsWasSet
        } catch _ {
            return false
        }
    }
    
    class func addAllTags(currentLocalIdentifier: String) -> Bool {
        let context = getContext()
        
        let photos = fetchAllObjects()
        do {
            for photo in photos! {
                photo.allTagsWasSet = true
                photo.localIdentifierForAllTags = currentLocalIdentifier
            }
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    
    class func removeAllTags() -> Bool {
        let context = getContext()
        
        let photos = fetchAllObjects()
        do {
            for photo in photos! {
                photo.allTagsWasSet = false
                photo.localIdentifierForAllTags = nil
            }
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    
}
