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
    
    var id: Int
    var projectName: String
    var selected: Bool = false
    
    //MARK: - Initializare
    
    init?(id: Int,
          projectName: String
        ) {
        
        //Initializeaza proprietatile
        self.id = id
        self.projectName = projectName
    }
}
