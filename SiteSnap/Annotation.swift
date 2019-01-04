//
//  Annotation.swift
//  SiteSnap
//
//  Created by Paul Oprea on 03/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class Annotation: UIView {
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var numberOfPhotos: UILabel!
    
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        numberOfPhotos.layer.cornerRadius = 20
        numberOfPhotos.layer.backgroundColor = UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0).cgColor
        numberOfPhotos.layer.borderColor = UIColor.white.cgColor
        numberOfPhotos.layer.borderWidth = 1
    }
    

}
