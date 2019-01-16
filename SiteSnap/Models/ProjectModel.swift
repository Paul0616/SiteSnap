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
    var latitudeCenterPosition: Double
    var longitudeCenterPosition: Double
    var selected: Bool = false
    
    //MARK: - Initializare
    
    init?(id: String,
          projectName: String,
          latitudeCenterPosition: Double,
          longitudeCenterPosition: Double
        ) {
        
        //Initializeaza proprietatile
        self.id = id
        self.projectName = projectName
        self.latitudeCenterPosition = latitudeCenterPosition
        self.longitudeCenterPosition = longitudeCenterPosition
    }
}
