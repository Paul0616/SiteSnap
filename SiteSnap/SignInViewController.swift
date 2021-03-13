//
//  ViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 12/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var tapHereButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoText: UIImageView!
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var usernameText: String?
 
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        userNameTextField.delegate = self
        passwordTextField.delegate = self
        loginButton.layer.cornerRadius = 10
        self.logo.alpha = 0
        self.logoText.alpha = 0
        
//        for fontFamilyName in UIFont.familyNames {
//            for fontName in UIFont.fontNames(forFamilyName: fontFamilyName) {
//                print("Family: \(fontFamilyName)   Font: \(fontName)")
//            }
//        }
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
            if let username = (self.user?.username) {
                print("USER = CURRENT USER = \(username)")
            }
        
        }
        if let log1 = user?.isSignedIn {
            if log1 {
                print("CAMERAAAAAAAAAA...")
                dismiss(animated: true, completion: nil)
//                if let cameraVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "initController") as? CameraViewController {
//                    cameraVC.modalPresentationStyle = .fullScreen
//                    present(cameraVC, animated: true, completion: nil)
//                }
            }
        }
        if (self.usernameText == nil) {
            //self.usernameText = authenticationInput.lastKnownUsername
            self.usernameText = UserDefaults.standard.value(forKey: "email") as? String
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppDelegate.AppUtility.lockOrientation(.portrait)
        self.passwordTextField.text = nil
        self.userNameTextField.text = usernameText
        // Or to rotate and lock
        // AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 5, options: [.curveEaseOut], animations: {
            self.logo.transform = CGAffineTransform(translationX: -100, y: -180)
            self.logoText.transform = CGAffineTransform(translationX: 45, y: -180)
            self.logo.alpha = 1
        }, completion: {finished in
            UIView.animate(withDuration: 0.5, animations:{
                self.logoText.alpha = 1
            })
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Don't forget to reset when view is being removed
        AppDelegate.AppUtility.lockOrientation(.all)
    }
    
    @IBAction func signInPressed(_ sender: UIButton) {
        if (self.userNameTextField.text != nil && self.passwordTextField.text != nil) {
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: self.userNameTextField.text!, password: self.passwordTextField.text! )
            self.passwordAuthenticationCompletion?.set(result: authDetails)
            //pool?.currentUser()?.isSignedIn
        } else {
            let alertController = UIAlertController(title: "Missing information",
                                                    message: "Please enter a valid user name and password",
                                                    preferredStyle: .alert)
            let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
            alertController.addAction(retryAction)
        }
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == userNameTextField || textField == passwordTextField {
            animateViewMoving(up: true, moveValue: 100)
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == userNameTextField || textField == passwordTextField {
            animateViewMoving(up: false, moveValue: 100)
        }
    }
    
    func animateViewMoving (up:Bool, moveValue :CGFloat){
        let movementDuration:TimeInterval = 0.3
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        UIView.animate(withDuration: movementDuration, animations: {
            self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        })
//        UIView.beginAnimations("animateView", context: nil)
//        UIView.setAnimationBeginsFromCurrentState(true)
//        UIView.setAnimationDuration(movementDuration)
//        
//        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
//        UIView.commitAnimations()
    }
}
extension SignInViewController: AWSCognitoIdentityPasswordAuthentication {
    
    public func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource
        DispatchQueue.main.async {
            if (self.usernameText == nil) {
                //self.usernameText = authenticationInput.lastKnownUsername
                self.usernameText = UserDefaults.standard.value(forKey: "email") as? String
            }
        }
    }
    
    public func didCompleteStepWithError(_ error: Error?) {
        DispatchQueue.main.async {
            if let error = error as NSError? {
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { action in
                    self.passwordTextField.text = nil
                })
                alertController.addAction(retryAction)
                
                self.present(alertController, animated: true, completion:  nil)
            } else {
                self.userNameTextField.text = nil
               
                //let initialViewController = self.storyboard!.instantiateInitialViewController() as! CameraViewController
               // initialViewController.sessionQueue.resume()
                //initialViewController.userLogged = true
                self.dismiss(animated: true, completion: nil)
                
            }
        }
    }
    
    
}
