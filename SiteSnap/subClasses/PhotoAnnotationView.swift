//
//  PhotoAnnotationView.swift
//  SiteSnap
//
//  Created by Paul Oprea on 03/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import MapKit

class PhotoAnnotationView: MKAnnotationView {
    var customView: Annotation_V2!
    var width: Double = 100.0
    var height: Double = 120.0
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
   
    init(annotation: MKAnnotation?, reuseIdentifier: String?, isCluster: Bool, numberOfPhotos: Int, photoImage: UIImage?, width: Double, height: Double) {
        self.width = width
        self.height = height
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        resetProperties(newIsCluster: isCluster, newNumberOfPhotos: numberOfPhotos, newPhotoImage: photoImage)
    }
    
    func resetProperties(newIsCluster: Bool, newNumberOfPhotos: Int, newPhotoImage: UIImage?){
        customView = Bundle.main.loadNibNamed("Annotation_v2", owner: self, options: nil)?.first as? Annotation_V2
         
        self.frame = CGRect(x: 0, y: 0, width: width, height: height)//100/120
        customView.pinCircle.layer.cornerRadius = CGFloat(width * 0.3)
        self.addSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false
        customView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bottomAnchor, multiplier: 1).isActive = true
        customView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1).isActive = true
        customView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1).isActive = true
        customView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: 1).isActive = true
        
        //customView.photoImage.isHidden = newIsCluster
        
        customView.numberOfPhotos.text = String(newNumberOfPhotos)
 //       customView.numberOfPhotos.isHidden = !newIsCluster
//        if newPhotoImage != nil {
//            customView.photoImage.image = newPhotoImage
//        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
