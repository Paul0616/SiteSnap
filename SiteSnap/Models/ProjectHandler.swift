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
    
    class func saveProject(id: String, name: String, latitude: Double, longitude: Double, projectOwnerName: String) -> Bool{
        if let project = getSpecificProject(id: id) {
            if project.name != name || project.latitude != latitude || project.longitude != longitude || project.projectOwnerName != projectOwnerName {
                if updateProject(id: id, name: name, latitude: latitude, longitude: longitude, projectOwnerName: projectOwnerName) {
                    print("Project \(id) was updated")
                }
            }
            return false
        }
        
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "Project", in: context)
        let managedObject = NSManagedObject(entity: entity!, insertInto: context)
        managedObject.setValue(id, forKey: "id")
        managedObject.setValue(name, forKey: "name")
        managedObject.setValue(latitude, forKey: "latitude")
        managedObject.setValue(longitude, forKey: "longitude")
        managedObject.setValue(projectOwnerName, forKey: "projectOwnerName")
        do {
            try context.save()
            return true
        } catch  {
            return false
        }
    }
    
    class func updateProject(id: String, name: String, latitude: Double, longitude: Double, projectOwnerName: String) -> Bool {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Project>(entityName: "Project")
        fetchRequest.predicate = NSPredicate.init(format: "id=='\(id)'")
        do {
            let objects = try context.fetch(fetchRequest)
            objects.first?.name = name
            objects.first?.latitude = latitude
            objects.first?.longitude = longitude
            objects.first?.projectOwnerName = projectOwnerName
            try context.save()
            return true
        } catch _ {
            return false
        }
    }
    
    class func getSpecificProject(id: String) -> Project! {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Project>(entityName: "Project")
        fetchRequest.predicate = NSPredicate.init(format: "id=='\(id)'")
        do {
            let objects = try context.fetch(fetchRequest)
            
            return objects.first
        } catch _ {
            return nil
        }
    }
    class func getCurrentProject() -> Project? {
        let context = getContext()
        if let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String? {
            let fetchRequest = NSFetchRequest<Project>(entityName: "Project")
            fetchRequest.predicate = NSPredicate.init(format: "id=='\(currentProjectId)'")
            do {
                let objects = try context.fetch(fetchRequest)
                
                return objects.first
            } catch _ {
                return nil
            }
        } else {
            return nil
        }
    }
    
    class func getTagsForProject(projectId: String) -> [TagModel] {
        var tagModels = [TagModel]()
        if let currentProject = ProjectHandler.getSpecificProject(id: projectId) {
            for item in currentProject.availableTags! {
                let tag = item as! Tag
                tagModels.append(TagModel(tag: tag, selected: false)!)
            }
        }
        return tagModels
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
    class func deleteExtraProjects(projectsForVerification: [String]) -> Int {
        let context = getContext()
        let fetchRequest = NSFetchRequest<Project>(entityName: "Project")
        fetchRequest.predicate = NSPredicate.init(format: "NOT (id IN %@)", projectsForVerification)
        var projectsForDelete: [Project]!
        do {
            projectsForDelete = try context.fetch(fetchRequest)
        } catch _ {
            projectsForDelete = nil
        }
        if projectsForDelete == nil {
            return 0
        }
        if projectsForDelete.count == 0 {
            return 0
        }
        var ids = [String]()
        for project in projectsForDelete {
            ids.append(project.id!)
        }
        context.reset()
        let fetchDeleteRequest = NSFetchRequest<Project>(entityName: "Project")
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
}
