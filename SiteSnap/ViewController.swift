//
//  ViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 12/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var tapHereButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        userNameTextField.delegate = self
        passwordTextField.delegate = self
        loginButton.layer.cornerRadius = 6
        
        self.logo.alpha = 0
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 5, options: [.curveEaseOut], animations: {
            self.logo.transform = CGAffineTransform(translationX: 0, y: -180)
            self.logo.alpha = 1
        }, completion: nil)
//        for fontFamilyName in UIFont.familyNames {
//            for fontName in UIFont.fontNames(forFamilyName: fontFamilyName) {
//                print("Family: \(fontFamilyName)   Font: \(fontName)")
//            }
//        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppDelegate.AppUtility.lockOrientation(.portrait)
        // Or to rotate and lock
        // AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Don't forget to reset when view is being removed
        AppDelegate.AppUtility.lockOrientation(.all)
    }
    
    //MARK: - UItextfieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //hide keyboard
        if textField == userNameTextField{
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            //attemptLogin()
        }
        return true
    }
}

