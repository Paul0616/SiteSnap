//
//  PhotoInspectorViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 01/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import Photos

class PhotoInspectorViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backbutton: UIButton!
    var firstTime: Bool = true
    var imageView = UIImageView()
    var localIdentifier: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        backbutton.layer.cornerRadius = 20
        // Do any additional setup after loading the view.
        
    }
    override func viewDidLayoutSubviews() {
        if firstTime {
             loadImage(identifier: localIdentifier)
            firstTime = false
        } else {
            settingScale()
        }
    }
    
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        // Before rotation
//        // print(view.safeAreaLayoutGuide.layoutFrame.size)
//        
//        coordinator.animate(alongsideTransition: { (context) in
//            // During rotation
//        }) { (context) in
//            // After rotation
//            print(self.view.safeAreaLayoutGuide.layoutFrame.size)
//            self.settingScale()
//        }
//    }
    func centerScrollViewContents(){
        //print("bounds\(scrollView.bounds.size)")
        //print(imageView.frame.size)
        let boundsize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        if contentsFrame.size.width < boundsize.width {
            contentsFrame.origin.x = (boundsize.width - contentsFrame.size.width) / 2
        } else {
            contentsFrame.origin.x = 0
        }
        
        if contentsFrame.size.height < boundsize.height {
            contentsFrame.origin.y = (boundsize.height - contentsFrame.size.height) / 2
        } else {
            contentsFrame.origin.y = 0
        }
        imageView.frame = contentsFrame
    }
    
    func settingScrollView() {
       // print("\(imageView.image!.size)")
        //print("\(scrollView.frame.size)")
        imageView.contentMode = .center
        imageView.frame = CGRect(x: 0, y: 0, width: imageView.image!.size.width, height: imageView.image!.size.height)
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        //centerScrollViewContents()
        
        settingScale()
    }
    
    func settingScale(){
        scrollView.contentSize = imageView.image!.size
        let scrollViewFrame = scrollView.frame
        let scaleWidth = scrollViewFrame.size.width / scrollView.contentSize.width
        let scaleHeight = scrollViewFrame.size.height / scrollView.contentSize.height
        let minScale = min(scaleWidth, scaleHeight)
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = minScale
    }
    @IBAction func onBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents()
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    //MARK: - Loading image
    func loadImage(identifier: String!) {
        let hiddenIdentifiers = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: [identifier])
        if hiddenIdentifiers.count > 0 {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let imagePath: String = path.appending("/\(identifier!)")
            if FileManager.default.fileExists(atPath: imagePath),
                let imageData: Data = FileManager.default.contents(atPath: imagePath),  //try? Data(contentsOf: imageUrl),
                let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
                self.imageView.image = image
                self.settingScrollView()
            }
        } else {
            //This will fetch all the assets in the collection
            let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier!] , options: nil)
            //print(assets)
            
            let imageManager = PHCachingImageManager()
            //Enumerating objects to get a chached image - This is to save loading time
            
            assets.enumerateObjects{(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                print(count)
                if object is PHAsset {
                    let asset = object as! PHAsset
                    //                print(asset)
                    
                    let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    
                    
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .opportunistic
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    options.resizeMode = PHImageRequestOptionsResizeMode.exact
                    
                    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                        (image, info) -> Void in
                        //print(info!)
                        self.imageView.image = image
                        self.settingScrollView()
                        /* The image is now available to us */
                        
                    })
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
