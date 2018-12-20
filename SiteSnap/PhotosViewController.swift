//
//  PhotosViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 19/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {

    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var addFromGalleryButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var imagesDotsContainer: UIView!
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
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onBack(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
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
