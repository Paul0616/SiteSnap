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
    override func viewDidLoad() {
        super.viewDidLoad()
        takePhotoButton.layer.cornerRadius = 6
        takePhotoButton.titleLabel?.lineBreakMode = .byWordWrapping
        takePhotoButton.titleLabel?.numberOfLines = 2
        takePhotoButton.titleLabel?.textAlignment = .center
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onBack(_ sender: UIButton) {
        
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
