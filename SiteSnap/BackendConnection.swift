//
//  BackendConnection.swift
//  SiteSnap
//
//  Created by Paul Oprea on 02/03/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider
import CoreLocation

protocol BackendConnectionDelegate: class {
    func treatErrors(_ error: Error?)
    func displayMessageFromServer(_ message: String?)
    func noProjectAssigned()
    func databaseUpdateFinished()
    func userNeedToCreateFirstProject()
//    func getLocation(_ location: CLLocation)
//    func isLocationAvailable(_ isLocationAvailable: Bool, status: CLAuthorizationStatus?)
}

class BackendConnection: NSObject {
    

    
    var pool: AWSCognitoIdentityUserPool?
    weak var delegate: BackendConnectionDelegate?
    
    let projectWasSelected: Bool
    let lastLocation: CLLocation?
    //MARK: - Connect to SITESnap Backend API
    
    init(projectWasSelected: Bool, lastLocation: CLLocation!) {
        self.projectWasSelected = projectWasSelected
        self.lastLocation = lastLocation
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
    }
    
  
   
    
     func makeUrlRequest() -> URLRequest! {
        let url = URL(string: siteSnapBackendHost + "session/getPhoneSessionInfo")!
        var request = URLRequest(url: url)
        if (self.pool?.token().isCompleted)! {
            let tokenString = "Bearer " + (self.pool?.token().result as String?)!
            request.setValue(tokenString, forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            return request
        } else {
            return nil
        }
    }
  
    
    func attemptSignInToSiteSnapBackend()
    {
        let request = makeUrlRequest()
        if let request = request {
            let task = URLSession.shared.dataTask(with: request as URLRequest) {(data, response, error) -> Void in
                if error != nil {
                    self.delegate?.treatErrors(error)
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    self.setUpInternalTables(json: json)
                }
                catch let error as NSError
                {
                    print(error.localizedDescription)
                }
            }
            task.resume()
        }
    }
  
    
    func setCurrentProjectName(projects: NSArray, lastUsedProject: String){
        for item in projects {
            let project = item as! NSDictionary
            let pID = project["id"]! as! String
            if pID == lastUsedProject {
                UserDefaults.standard.set(project["name"]! as! String, forKey: "currentProjectName")
                break
            }
        }
    }
    func isProjectValidForSelection(projects: NSArray, projectId: String?) -> Bool{
        guard let projectId = projectId else {
            return false
        }
        for item in projects {
            let project = item as! NSDictionary
            let pID = project["id"]! as! String
            if pID == projectId {
                return true
            }
        }
        return false
    }
    func getCloserProject(projects: NSArray) -> String! {
        //let projects = ProjectHandler.fetchAllProjects()
        guard let lastlocation = lastLocation else {
            return nil
        }
        let firstItem = projects[0] as! NSDictionary
        var closestProject = firstItem["id"]! as! String
        let firstCoords = firstItem["projectCenterPosition"] as! NSArray
        let firstLocation = CLLocation(latitude: firstCoords[0] as! Double, longitude: firstCoords[1] as! Double)
        var closestDistance = firstLocation.distance(from: lastLocation!)
        for item in projects {
            let project = item as! NSDictionary
            let pID = project["id"]! as! String
            let coords = project["projectCenterPosition"] as! NSArray
            let location = CLLocation(latitude: coords[0] as! Double, longitude: coords[1] as! Double)
            let dist = location.distance(from: lastlocation)
            if dist < closestDistance {
                closestDistance = dist
                closestProject = pID
            }
        }
        return closestProject
    }
    func setUpInternalTables(json: NSDictionary){
        //if messageFromServer is not null then displayed
        if let messageFromServer = json["messageFromServer"] as? String {
            self.delegate?.displayMessageFromServer(messageFromServer)
        }
        //if user is free tier and have no projects assigned then return
        if let isRunningSiteSnapFree = json["isRunningSiteSnapFree"] as? Bool,
           let userProjects = json["projects"] as? NSArray,
           userProjects.count == 0,
           isRunningSiteSnapFree {
            self.delegate?.userNeedToCreateFirstProject()
            return
        }
       
        let projects = json["projects"] as! NSArray
        
        //check if user have projects
        if projects.count == 0 {
            let isAdmin = json["isAdmin"] as! Bool
            if isAdmin {
                delegate?.userNeedToCreateFirstProject()
            } else {
                delegate?.noProjectAssigned()
            }
            return
        }
        
        let projectId = json["lastUsedProjectId"] as? String
        
        
        let allTags = json["tags"] as! NSArray
        
        
        
        var projectValid: Bool = true
        if let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            projectValid = isProjectValidForSelection(projects: projects, projectId: currentProjectId)
        }
        if !projectWasSelected || !projectValid {
            if isProjectValidForSelection(projects: projects, projectId: projectId) {
                UserDefaults.standard.set(projectId, forKey: "currentProjectId")
                self.setCurrentProjectName(projects: projects, lastUsedProject: projectId!)
            } else { //else project was last used but no longer available
                let firstProject = projects[0] as! NSDictionary
                let firstProjectId = firstProject["id"]! as! String
                UserDefaults.standard.set(firstProjectId, forKey: "currentProjectId")
                self.setCurrentProjectName(projects: projects, lastUsedProject: firstProjectId)
            }
            //if locationWasUpdated {
            //if let location = lastLocation {
            if let closestProjectId = self.getCloserProject(projects: projects) {
                UserDefaults.standard.set(closestProjectId, forKey: "currentProjectId")
                self.setCurrentProjectName(projects: projects, lastUsedProject: closestProjectId)
            }
            //}
        }
        
        
        DispatchQueue.main.async {
            //self.checkDatabasePhotoIsStillInGallery()
//            let photos = PhotoHandler.fetchAllObjects()
//            print("-----BEFORE ---\(photos!.count) photos")
//            for photo in photos! {
//                let tags = photo.tags
//                for item in tags! {
//                    let tag = item as! Tag
//                    print("Tag: \(String(describing: tag.text))")
//                }
//            }
            
            //----------------------- add extra projects from server to CoreData (saveProject will add new project only if it not already exist)
           // if ProjectHandler.deleteAllProjects() {
            for item in projects {
                let project = item as! NSDictionary
                let pID = project["id"]! as! String
                let projectname = project["name"]! as! String
                let projectOwnerName = project["projectOwnerName"]! as! String
                let coord = project["projectCenterPosition"] as! NSArray
                if ProjectHandler.saveProject(id: pID, name: projectname, latitude: coord[0] as! Double, longitude: coord[1] as! Double, projectOwnerName: projectOwnerName) {
                    print("PROJECT: \(projectname) added")
                }
            }
            var allProjectsIds: [String] = [String]()
            for item in projects {
                let project = item as! NSDictionary
                let pID = project["id"]! as! String
                allProjectsIds.append(pID)
            }
            let deletedProjectsNumber = ProjectHandler.deleteExtraProjects(projectsForVerification: allProjectsIds)
            print("\(deletedProjectsNumber) projects was deleted")
        
            //}
            
            
//            let photos1 = PhotoHandler.fetchAllObjects()
//            print("-----AFTER ---\(photos1!.count) photos")
//            for photo in photos1! {
//                let tags = photo.tags
//                for item in tags! {
//                    let tag = item as! Tag
//                    print("Tag: \(String(describing: tag.text))")
//                }
//            }

            //------------------------
            //----------------------- add extra tags from server to CoreData (saveTag will add new tag only if it not already exist)
            var allTagIds: [String]!
            if allTags.count > 0 {
                allTagIds = [String]()
            }
            for item in allTags {
                let tag = item as! NSDictionary
                allTagIds.append(tag["id"] as! String)
                if TagHandler.saveTag(id: tag["id"] as! String, text: tag["name"] as! String, tagColor: tag["colour"] as! String?) {
                    print("TAG \(tag["name"] as! String) \(tag["id"] as! String) with was added")
                }
            }
            if let ids = allTagIds {
                let deletedTagsNumber = TagHandler.deleteExtraTags(tagsForVerification: ids)
                print("\(deletedTagsNumber) tags was deleted")
            }
            
            
            //------------------------ for each project from CoreData find the corespondent in projectModel
            //------------------------ and set each project from CoreData associated tags
            if let projectsRecords = ProjectHandler.fetchAllProjects() {
                for itemRecord in projectsRecords {
                    for item in projects {
                        let project = item as! NSDictionary
                        let pID = project["id"]! as! String
                        if pID == itemRecord.id {
                            let projectTagIds = project["tagIds"] as! NSArray
                            //add tags to every project
                            for tagId in projectTagIds {
                                let tagIdString = tagId as! String
                                if let tagRecord = TagHandler.getSpecificTag(id: tagIdString) {
                                    itemRecord.addToAvailableTags(tagRecord)
                                }
                            }
                            //delete tags from project if them not avilable anymore
                            var availableTagIdFromDatabase = [String]()
                            for tagitem in itemRecord.availableTags! {
                                let tag = tagitem as! Tag
                                availableTagIdFromDatabase.append(tag.id!)
                            }
                            var availableTagIdServer = [String]()
                            for tagId in projectTagIds {
                                let tagIdString = tagId as! String
                                availableTagIdServer.append(tagIdString)
                            }
                            for itemFromDatabase in availableTagIdFromDatabase {
                                if !availableTagIdServer.contains(itemFromDatabase) {
                                    if let tagRecord = TagHandler.getSpecificTag(id: itemFromDatabase) {
                                        itemRecord.removeFromAvailableTags(tagRecord)
                                        print("\(String(describing: tagRecord.text)) was removed from project \(String(describing: itemRecord.id))")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //-------------------- for each tag from CoreData set associated project
            for tagItem in TagHandler.fetchObjects()! {
                for projectItem in ProjectHandler.fetchAllProjects()! {
                    for associatedTag in projectItem.availableTags! {
                        let tag = associatedTag as! Tag
                        if tag.id == tagItem.id {
                            tagItem.addToProjects(projectItem)
                            
                        }
                    }
                }
            }
            //------------------ for each photo tags, search it in project available tags and if it no longer there removed from photo tag
            let photos = PhotoHandler.fetchAllObjects()
            for photo in photos! {
                //let tagModels = PhotoHandler.getTags(localIdentifier: photo.localIdentifierString!)
                
                let project = ProjectHandler.getCurrentProject()
                var currentProjectTagIds = [String]()
                for tg in (project?.availableTags)! {
                    let tag = tg as! Tag
                    currentProjectTagIds.append(tag.id!)
                     print("-----PROJECT TAGS-------\(String(describing: tag.text)) current project available tag")
                }
                for photoTag in photo.tags! {
                    let tag = photoTag as! Tag
                    print("-----PHOTO TAGS-------\(String(describing: tag.text))")
                    if !currentProjectTagIds.contains(String(describing: tag.id!)) {
                        photo.removeFromTags(tag)
                        print("\(String(describing: tag.text)) was removed from photo \(String(describing: photo.localIdentifierString))")
                    }
                }
            }
            
          // print(json)
            
            // get the current date and time
            let currentDateTime = Date()
            
            // initialize the date formatter and set the style
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .long
            
            // get the date time String from the date object
            print(formatter.string(from: currentDateTime)) // October 8, 2016 at 10:48:53 PM
            
            self.delegate?.databaseUpdateFinished()
            //self.loadingProjectIntoList()
        }
    }
}

