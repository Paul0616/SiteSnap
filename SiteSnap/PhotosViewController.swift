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
        if (photosLocalIdentifiers?.count)! > 0 {
            print("PHOTOS: \(String(describing: photosLocalIdentifiers?.count)) - \(String(describing: photosLocalIdentifiers))")
            showImages(localIdentifier: [(photosLocalIdentifiers?.first)!])
        }
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onBack(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }
    
    func showImages(localIdentifier: [String]) {
        //This will fetch all the assets in the collection
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifier , options: nil)
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
                options.deliveryMode = .fastFormat
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    self.photoMainContainer.image = image!
                    /* The image is now available to us */
                    
                })
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
