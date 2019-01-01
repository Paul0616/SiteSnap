//
//  TagModel.swift
//  SiteSnap
//
//  Created by Paul Oprea on 30/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class TagModel: NSObject {
    var tag: Tag
    var selected: Bool
    //MARK: - Initializare
    
    init?(tag: Tag,
          selected: Bool
        ) {
        
        //Initializeaza proprietatile
        self.tag = tag
        self.selected = selected
    }
}
