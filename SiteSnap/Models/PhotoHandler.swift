//
//  PhotoHandler.swift
//  SiteSnap
//
//  Created by Paul Oprea on 30/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import Photos

class PhotoHandler: NSObject {
    private class func getContext() -> NSManagedObjectContext {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let ctx = appDelegate.persistentContainer.viewContext
            //ctx.reset()
            return ctx
    }
    
    class func savePhotoInMyDatabase(localIdentifier: String, creationDate: Date, latitude: Double?, longitude: Double?) -> Bool{
        let photos = fetchAllObjects()
        let context = getContext()
        for photo in photos! {
            if photo.localIdentifierString == localIdentifier { //this identifier already exist
                return false
            }
        }
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
    
    class func setFileSize(localIdentifiers: [String]!){
        let context = getContext()
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers! , options: nil)
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset {
                let asset = object as! PHAsset
                let resources = PHAssetResource.assetResources(for: asset) // your PHAsset
                
                var sizeOnDisk: Int64? = 0
                
                if let resource = resources.first {
                    let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
                    sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
                }
                
                let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
                fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(String(object.localIdentifier))'")
                do {
                    let objects = try context.fetch(fetchRequest)
                    objects.first?.fileSize = sizeOnDisk!
                    try context.save()
                } catch _ {
                   print("Error on save filesize")
                }
                //print(self.converByteToHumanReadable(sizeOnDisk!))
            }
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
    
    class func updateLocations(localIdentifiers: [String]!, location: CLLocationCoordinate2D) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo") //connectionType IN %@", yourIntArray
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString IN %@", localIdentifiers)
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                object.latitude = location.latitude as Double
                object.longitude = location.longitude as Double
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
        context.reset()
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult> )
        
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            return true
        } catch {
            print ("There is an error in deleting records")
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
            var tags = [Tag]()
            if let currentProject = ProjectHandler.getCurrentProject() {
                for item in currentProject.availableTags! {
                    let tag = item as! Tag
                    tags.append(tag)
                }
            }
            for tag in tags {
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
    class func getAvailableTagsForCurrentProject() -> Int {
        if let currentProject = ProjectHandler.getCurrentProject() {
            return (currentProject.availableTags?.count)!
        }
        return 0
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
