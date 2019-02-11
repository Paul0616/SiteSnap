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
        let ctx = appDelegate.persistentContainer.viewContext
        //ctx.reset()
        return ctx
    }
    
    class func saveTag(id: String, text: String, tagColor: String?) -> Bool{
        if let tag = getSpecificTag(id: id) {
            if tag.text != text {
                if updateTagText(id: id, text: text) {
                    print("Text for 1 tag was modified")
                }
            }
            if tag.tagColor != tagColor {
                if updateTagColor(id: id, tagColor: tagColor!) {
                    print("Colour for 1 tag was modified")
                }
            }
            return false
        }
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "Tag", in: context)
        let managedObject = NSManagedObject(entity: entity!, insertInto: context)
        managedObject.setValue(id, forKey: "id")
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
    
    class func updateTagText(id: String, text: String) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate.init(format: "id=='\(id)'")
        do {
            let objects = try context.fetch(fetchRequest)
            objects.first?.text = text
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    
    class func updateTagColor(id: String, tagColor: String?) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate.init(format: "id=='\(id)'")
        do {
            let objects = try context.fetch(fetchRequest)
            let colour = tagColor
            objects.first?.tagColor = colour
        
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    
    class func getSpecificTag(id: String) -> Tag! {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate.init(format: "id=='\(id)'")
        do {
            let objects = try context.fetch(fetchRequest)
            
            return objects.first
        } catch _ {
            return nil
        }
    }
    
    class func fetchObjects() -> [Tag]? {
        let context = getContext()
        var tags: [Tag]? = nil
        do {
            tags = try context.fetch(Tag.fetchRequest())
            return tags
        } catch  {
            return tags
        }
    }
    
    class func deleteExtraTags(tagsForVerification: [String]) -> Int {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate.init(format: "NOT (id IN %@)", tagsForVerification)
        var tagsForDelete: [Tag]!
        do {
            tagsForDelete = try context.fetch(fetchRequest)
        } catch _ {
            tagsForDelete = nil
        }
        if tagsForDelete == nil {
           return 0
        }
        if tagsForDelete.count == 0 {
            return 0
        }
        var ids = [String]()
        for tag in tagsForDelete {
            ids.append(tag.id!)
        }
        context.reset()
        let fetchDeleteRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchDeleteRequest.predicate = NSPredicate.init(format: "id IN %@", ids)
        do {
            let objects = try context.fetch(fetchDeleteRequest)
            for object in objects {
                context.delete(object)
            }
            try context.save()
            return objects.count
        } catch _ {
            return 0
        }
    }
    
    class func deleteAllTags() -> Bool {
        let context = getContext()
       context.reset()
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest )
        
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            return true
        } catch {
            return false
        }
    }
}
