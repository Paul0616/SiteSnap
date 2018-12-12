//
//  ViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 12/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var userNameTextField: UITextField!
    
    @IBOutlet weak var logo: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIView.animate(withDuration: 1, animations: {
             self.logo.transform = CGAffineTransform(translationX: 0, y: -180)
        }, completion: nil)
    }


}

