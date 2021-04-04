//
//  imageForUpload.swift
//  SiteSnap
//
//  Created by Paul Oprea on 10/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class ImageForUpload: NSObject {
    //MARK: - Propietati
    
    var localIdentifier: String
    var projectName: String
    var estimatedTime: Int
    var fileSize: Int64
    var speed: Int
    var progress: CFloat
    var state: State = .waiting
    var date: Date!
    var failCode: Int!
    var showRemoveFlag: Bool = false
    var uploadingTaskIdentifier: Int?
    var startUploadingDate: Date!
    
    enum State {
        case waiting
        case done
        case fail
        case inProgress
        case unknown
    }
    //MARK: - Initializare
    
    init?(localIdentifier: String,
          projectName: String,
          estimatedTime: Int,
          fileSize: Int64,
          speed: Int,
          progress: CFloat,
          state: State
        ) {
        
        //Initializeaza proprietatile
        self.localIdentifier = localIdentifier
        self.projectName = projectName
        self.estimatedTime = estimatedTime
        self.fileSize = fileSize
        self.speed = speed
        self.progress = progress
        self.state = state
    }
    
    
}
