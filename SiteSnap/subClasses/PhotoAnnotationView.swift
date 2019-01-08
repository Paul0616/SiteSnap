//
//  PhotoAnnotationView.swift
//  SiteSnap
//
//  Created by Paul Oprea on 03/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import MapKit

class PhotoAnnotationView: MKAnnotationView {
    var customView: Annotation!
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
   
    init(annotation: MKAnnotation?, reuseIdentifier: String?, isCluster: Bool, numberOfPhotos: Int, photoImage: UIImage?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        customView = Bundle.main.loadNibNamed("Annotation", owner: self, options: nil)?.first as? Annotation
//        self.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
//        //self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//
//        self.addSubview(customView)
//        customView.translatesAutoresizingMaskIntoConstraints = false
//        customView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bottomAnchor, multiplier: 1).isActive = true
//        customView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1).isActive = true
//        customView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1).isActive = true
//        customView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: 1).isActive = true
//
//        customView.photoImage.isHidden = isCluster
//
//        customView.numberOfPhotos.text = String(numberOfPhotos)
//        customView.numberOfPhotos.isHidden = !isCluster
//        if photoImage != nil {
//            customView.photoImage.image = photoImage
//        }
        resetProperties(newIsCluster: isCluster, newNumberOfPhotos: numberOfPhotos, newPhotoImage: photoImage)
    }
    
    func resetProperties(newIsCluster: Bool, newNumberOfPhotos: Int, newPhotoImage: UIImage?){
        customView = Bundle.main.loadNibNamed("Annotation", owner: self, options: nil)?.first as? Annotation
        self.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        //self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        self.addSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false
        customView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bottomAnchor, multiplier: 1).isActive = true
        customView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1).isActive = true
        customView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1).isActive = true
        customView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: 1).isActive = true
        
        customView.photoImage.isHidden = newIsCluster
        
        customView.numberOfPhotos.text = String(newNumberOfPhotos)
        customView.numberOfPhotos.isHidden = !newIsCluster
        if newPhotoImage != nil {
            customView.photoImage.image = newPhotoImage
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
