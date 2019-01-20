//
//  Media.swift
//  SiteSnap
//
//  Created by Paul Oprea on 18/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
struct Media {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String
    
    init?(withImage image: UIImage, forKey key: String ) {
        self.key = key
        self.mimeType = "image/jpeg"
        self.filename = "\(arc4random()).jpg"
        guard let data = image.jpegData(compressionQuality: 1.0) else {return nil}
        self.data = data
    }
}
