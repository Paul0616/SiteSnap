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
    
    class func savePhotoInMyDatabase(localIdentifier: String, creationDate: Date, latitude: Double?, longitude: Double?, isHidden: Bool, comeFromSharing: Bool = false) -> Bool{
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
        managedObject.setValue(isHidden, forKey: "isHidden")
        managedObject.setValue(comeFromSharing, forKey: "comeFromSharing")
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
    
    class func identifierAlreadyUploaded(localIdentifier: String) -> Bool {
        let photos = fetchAllObjects()
        for photo in photos! {
            if photo.localIdentifierString == localIdentifier && photo.successfulUploaded == true {
                //this identifier already exist and successfully uploaded
                return true
            }
        }
        return false
    }
    
    class func photosDatabaseContainHidden(localIdentifiers: [String]!) -> [String] {
        var hiddenIdentifiers: [String] = [String]();
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString IN %@", localIdentifiers)
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                if object.isHidden {
                    hiddenIdentifiers.append(object.localIdentifierString!)
                }
            }
        } catch _ {
           print("Error on fetch photos")
        }
        return hiddenIdentifiers
    }
    
    //get filesize from localIdentifier image from gallery then call uptadeFileSize to save it in CoreData
    class func setFileSize(localIdentifiers: [String]!){

        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers! , options: nil)
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset {
                let asset = object as! PHAsset
                //asset.
                let resources = PHAssetResource.assetResources(for: asset) // your PHAsset
                
                var sizeOnDisk: Int64? = 0
                
                if let resource = resources.first {
                    let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
                    sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
                }
                updateFileSize(localIdentifier: String(object.localIdentifier), size: sizeOnDisk!)

            }
        }
    
    }
    class func updateFileSize(localIdentifier: String, size: Int64){
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchRequest)
            objects.first?.fileSize = size
            try context.save()
        } catch _ {
            print("Error on save filesize")
        }
    }
    
    class func fetchAllObjects(excludeUploaded: Bool? = nil) -> [Photo]? {
        let context = getContext()
        var photos: [Photo]? = nil
        do {
            if let _ = excludeUploaded, excludeUploaded == true {
                let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
                fetchRequest.predicate = NSPredicate.init(format: "successfulUploaded == false")
                photos = try context.fetch(fetchRequest)
            } else {
                photos = try context.fetch(Photo.fetchRequest())
            }
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
    
    class func updateSuccessfulyUploaded(localIdentifier: String, succsessfuly: Bool, failCode: Int16 = -1, lastProjectToUploadedFor: String?) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(localIdentifier)'")
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                object.successfulUploaded = succsessfuly
                object.failUploadedCode = failCode
                object.lastProjectToUploadedFor = lastProjectToUploadedFor
                object.lastUploadedDate = Date()
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
    
    class func photosDeleteBatch(identifiers: [String]) -> Bool {
        let context = getContext()
        
        // Create Batch Delete Request
        let fetchDeleteRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchDeleteRequest.predicate = NSPredicate.init(format: "localIdentifierString IN %@", identifiers)
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
    
    class func getFailedUploadPhotosNumber() -> Int {
        /*
         - This func is used for info in settings.
        */
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "successfulUploaded == false")
        do {
            let objects = try context.fetch(fetchRequest)
            
            
            return objects.count
        } catch _ {
            return 0
        }
    }
    
    class func getUploadedPhotosForDelete() -> [String]! {
        /*
         - This func is used for delete all upload history.
        */
        var identifiers = [String]()
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "successfulUploaded == true")
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                identifiers.append(object.localIdentifierString!)
            }
        
            return identifiers
        } catch _ {
            return nil
        }
    }
    
    class func getHiddenAndUploadedPhotosForDelelete() -> [String]! {
        /*
         - This func is used for delete uploaded photo from documents directory.
         Option from settings 'Automatically add image in gallery' is set to false.
         - isHidden means photo was saved temporary in document directory not in album 'My Site Snap images'
        */
        var identifiers = [String]()
        let context = getContext()
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate.init(format: "isHidden == true AND successfulUploaded == true")
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                identifiers.append(object.localIdentifierString!)
            }
            
            return identifiers
        } catch _ {
            return nil
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
        
        let photos = fetchAllObjects(excludeUploaded: true)
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
        
        let photos = fetchAllObjects(excludeUploaded: true)
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
