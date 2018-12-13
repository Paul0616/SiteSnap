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
    @IBOutlet weak var tapHereButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loginButton.layer.cornerRadius = 6
        
        self.logo.alpha = 0
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 10, options: [.curveEaseOut], animations: {
            self.logo.transform = CGAffineTransform(translationX: 0, y: -180)
            self.logo.alpha = 1
        }, completion: nil)
    }


}

