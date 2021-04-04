//
//  PhotoModel.swift
//  SiteSnap
//
//  Created by Paul Oprea on 04.04.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class PhotoModel: NSObject {

    //MARK: - Properties
        
    var allPhotosComment: String?
    var allTagsWasSet: Bool
    var createdDate: NSDate?
    var fileSize: Int64?
    var individualComment: String?
    var latitude: Double
    var localIdentifierForAllTags: String?
    var localIdentifierString: String
    var longitude: Double
    var successfulUploaded: Bool
    var isHidden: Bool
    var tags: [TagModel]?

    
    //MARK: - Initializing
    
    init?(localIdentifier: String,
          createdDate: NSDate?,
          latitude: Double,
          longitude: Double,
          isHidden: Bool,
          fileSize: Int64?,
          allPhotosComment: String?,
          allTagsWasSet: Bool,
          individualComment: String?,
          successfulUploaded: Bool,
          localIdentifierForAllTags: String?,
          tags: [TagModel]?
        ) {
        
        //Initializeaza proprietatile
        self.localIdentifierString = localIdentifier
        self.createdDate = createdDate
        self.latitude = latitude
        self.longitude = longitude
        self.isHidden = isHidden
        self.fileSize = fileSize
        self.individualComment = individualComment
        self.localIdentifierForAllTags = localIdentifierForAllTags
        self.successfulUploaded = successfulUploaded
        self.allPhotosComment = allPhotosComment
        self.allTagsWasSet = allTagsWasSet
        self.tags = tags
    }
}
