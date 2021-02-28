//
//  ProjectModel.swift
//  SiteSnap
//
//  Created by Paul Oprea on 16/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class ProjectModel: NSObject {
    //MARK: - Propietati
    
    var id: String
    var projectName: String
    var projectOwnerName: String
    var latitudeCenterPosition: Double
    var longitudeCenterPosition: Double
    var tagIds: [String]
    //var selected: Bool = false
    
    //MARK: - Initializare
    
    init?(id: String,
          projectName: String,
          projectOwnerName: String,
          latitudeCenterPosition: Double,
          longitudeCenterPosition: Double,
          tagIds: [String]
        ) {
        
        //Initializeaza proprietatile
        self.id = id
        self.projectName = projectName
        self.latitudeCenterPosition = latitudeCenterPosition
        self.longitudeCenterPosition = longitudeCenterPosition
        self.tagIds = tagIds
        self.projectOwnerName = projectOwnerName
    }
}
