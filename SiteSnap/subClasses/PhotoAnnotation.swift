//
//  PhotoAnnotation.swift
//  SiteSnap
//
//  Created by Paul Oprea on 02/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import MapKit


class PhotoAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var isCluster: Bool?
    var numberOfPhotos: Int?
    var photo: UIImage?
    
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, isCluster: Bool, numberOfPhotos: Int, photoImage: UIImage?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.isCluster = isCluster
        self.numberOfPhotos = numberOfPhotos
        self.photo = photoImage
       
        super.init()
    }
}
