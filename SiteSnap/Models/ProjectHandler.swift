//
//  ProjectHandler.swift
//  SiteSnap
//
//  Created by Paul Oprea on 17/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import CoreData

class ProjectHandler: NSObject {
    private class func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    class func deleteAllProjects() -> Bool {
        let context = getContext()
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Project")
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest )
        
        do {
            try context.execute(batchDeleteRequest)
            return true
        } catch {
            return false
        }
    }
    
    class func saveProject(id: String, name: String, latitude: Double, longitude: Double) -> Bool{
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "Project", in: context)
        let managedObject = NSManagedObject(entity: entity!, insertInto: context)
        managedObject.setValue(id, forKey: "id")
        managedObject.setValue(name, forKey: "name")
        managedObject.setValue(latitude, forKey: "latitude")
        managedObject.setValue(longitude, forKey: "longitude")
        do {
            try context.save()
            return true
        } catch  {
            return false
        }
    }
}
