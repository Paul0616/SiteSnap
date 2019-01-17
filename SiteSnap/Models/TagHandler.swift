//
//  TagHandler.swift
//  SiteSnap
//
//  Created by Paul Oprea on 30/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import CoreData

class TagHandler: NSObject {
    private class func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    class func saveTag(id: String, text: String, tagColor: String?) -> Bool{
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "Tag", in: context)
        let managedObject = NSManagedObject(entity: entity!, insertInto: context)
        managedObject.setValue(text, forKey: "text")
        if let color = tagColor {
            if color.prefix(1) == "#" {
                managedObject.setValue(color, forKey: "tagColor")
            } else {
                managedObject.setValue("#"+color, forKey: "tagColor")
            }
        }
        do {
            try context.save()
            return true
        } catch  {
            return false
        }
    }
   
    class func getSpecificTag(text: String) -> Tag! {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate.init(format: "text=='\(text)'")
        do {
            let objects = try context.fetch(fetchRequest)
            
            return objects.first
        } catch _ {
            return nil
        }
    }
    
    class func fetchObject() -> [Tag]? {
        let context = getContext()
        var tags: [Tag]? = nil
        do {
            tags = try context.fetch(Tag.fetchRequest())
            return tags
        } catch  {
            return tags
        }
    }
    
    class func deleteAllTags() -> Bool {
        let context = getContext()
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest )
        
        do {
            try context.execute(batchDeleteRequest)
            return true
        } catch {
            return false
        }
    }
}
