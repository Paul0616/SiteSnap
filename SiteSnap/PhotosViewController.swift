//
//  PhotosViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 19/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import Photos

class PhotosViewController: UIViewController {

    var photosLocalIdentifiers: [String]?
    let stackView: UIStackView = UIStackView()
    
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var addFromGalleryButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var imagesDotsContainer: UIView!
    @IBOutlet weak var photoMainContainer: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        takePhotoButton.layer.cornerRadius = 6
        takePhotoButton.titleLabel?.lineBreakMode = .byWordWrapping
        takePhotoButton.titleLabel?.numberOfLines = 2
        takePhotoButton.titleLabel?.textAlignment = .center
        addFromGalleryButton.layer.cornerRadius = 6
        addFromGalleryButton.titleLabel?.lineBreakMode = .byWordWrapping
        addFromGalleryButton.titleLabel?.numberOfLines = 2
        addFromGalleryButton.titleLabel?.textAlignment = .center
        nextButton.layer.cornerRadius = 6
//        if (photosLocalIdentifiers?.count)! > 0 {
//            print("PHOTOS: \(String(describing: photosLocalIdentifiers?.count)) - \(String(describing: photosLocalIdentifiers))")
//            showImages(localIdentifier: [(photosLocalIdentifiers?.first)!])
//        }
        //Stack View
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = 20.0
        loadImageDots()
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func onBack(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onClickNext(_ sender: Any) {
        //addImageDot(selected: true)
    }
    
    
    func loadImageDots(){
        for localIdentifier in photosLocalIdentifiers! {
            if(localIdentifier == photosLocalIdentifiers!.last) {
                addImageDot(selected: true, localIdentifier: localIdentifier)
            } else {
                addImageDot(selected: false, localIdentifier: localIdentifier)
            }
        }
        
        for view in stackView.subviews {
            if let dot = view as? ImageDotButton, dot.selectedValue {
                showImages(sender: dot)
            }
        }
    }
    
    func addImageDot(selected: Bool, localIdentifier: String){
        let dot = ImageDotButton()
        dot.selectDot(selected: selected)
        dot.localIdentifier = localIdentifier
        dot.addTarget(self, action: #selector(showImages), for: .touchUpInside)
        stackView.removeFromSuperview()
        stackView.addArrangedSubview(dot)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.imagesDotsContainer.addSubview(stackView)
        stackView.centerXAnchor.constraint(equalToSystemSpacingAfter: self.imagesDotsContainer.centerXAnchor, multiplier: 1).isActive = true
        stackView.centerYAnchor.constraint(equalToSystemSpacingBelow: self.imagesDotsContainer.centerYAnchor, multiplier: 1).isActive = true
        
    }
    
    @objc func showImages(sender: ImageDotButton!) {
        //This will fetch all the assets in the collection
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [sender!.localIdentifier] , options: nil)
        print(assets)
        
        let imageManager = PHCachingImageManager()
        //Enumerating objects to get a chached image - This is to save loading time
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset {
                let asset = object as! PHAsset
                print(asset)
                
                let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = true
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    self.photoMainContainer.image = image!
                    /* The image is now available to us */
                    
                })
            }
        }
        for view in stackView.subviews {
            if let dot = view as? ImageDotButton {
                if dot == sender {
                    dot.selectDot(selected: true)
                } else {
                    dot.selectDot(selected: false)
                }
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
