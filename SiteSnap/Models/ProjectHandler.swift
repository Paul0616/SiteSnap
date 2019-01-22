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
        let ctx = appDelegate.persistentContainer.viewContext
        //ctx.reset()
        return ctx
    }
    
    class func deleteAllProjects() -> Bool {
        let context = getContext()
        context.reset()
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Project")
        
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
    class func getCurrentProject() -> Project? {
        let context = getContext()
        let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String
        let fetchRequest = NSFetchRequest<Project>(entityName: "Project")
        fetchRequest.predicate = NSPredicate.init(format: "id=='\(currentProjectId!)'")
        do {
            let objects = try context.fetch(fetchRequest)
            
            return objects.first
        } catch _ {
            return nil
        }
        
    }
    class func fetchAllProjects() -> [Project]? {
        let context = getContext()
        var projects: [Project]? = nil
        do {
            projects = try context.fetch(Project.fetchRequest())
            return projects
        } catch  {
            return projects
        }
    }
}
