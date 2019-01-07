//
//  SliderTestViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 05/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import Photos

class SliderTestViewController: UIViewController {

    var sliderContainer: Slider!
    var photoObjects: [Photo]?
    var firstTime: Bool = true
    
    @IBOutlet weak var backButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
//        let SB: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//        let VC = SB.instantiateViewController(withIdentifier: "mySlider")
//        if let _ = VC.view {
//            print("slider Instatiated")
//        }
    }
    
    @IBAction func onBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
         photoObjects = PhotoHandler.fetchAllObjects()
    }
    
    override func viewDidLayoutSubviews() {
        if firstTime {
            for view in view.subviews {
                if view is Slider {
                    sliderContainer = view as? Slider
                }
            }
            var identifiers = [String]()
            for photo in photoObjects! {
                identifiers.append(photo.localIdentifierString!)
            }
            firstTime = false
            sliderContainer.loadImages(identifiers: identifiers)
        }
      //  print("slider width = \(sliderContainer.frame.width) - slider height = \(sliderContainer.frame.height)")
        
    }
    
   
    
}
