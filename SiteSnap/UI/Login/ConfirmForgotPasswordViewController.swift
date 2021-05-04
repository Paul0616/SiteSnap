//
//  ConfirmForgotPasswordViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 20/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class ConfirmForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    var user: AWSCognitoIdentityUser?
    
    @IBOutlet weak var confirmationCode: UITextField!
    @IBOutlet weak var proposedPassword: UITextField!
    @IBOutlet weak var updatePasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePasswordButton.layer.cornerRadius = 6
        confirmationCode.delegate = self
        proposedPassword.delegate = self
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.userWantToResetPassword = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userWantToResetPassword = false
    }
    
    
    // MARK: - IBActions
    //MARK: - UItextfieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //hide keyboard
        if textField == confirmationCode {
            proposedPassword.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            //attemptLogin()
        }
        return true
    }
    
    @IBAction func updatePassword(_ sender: AnyObject) {
        guard let confirmationCodeValue = self.confirmationCode.text, !confirmationCodeValue.isEmpty else {
            let alertController = UIAlertController(title: "Password Field Empty",
                                                    message: "Please enter a password of your choice.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion:  nil)
            return
        }
        
        //confirm forgot password with input from ui.
        self.user?.confirmForgotPassword(confirmationCodeValue, password: self.proposedPassword.text!).continueOnSuccessWith{[weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async(execute: {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    
                    self?.present(alertController, animated: true, completion:  nil)
                } else {
                    let _ = strongSelf.view.window?.rootViewController!.dismiss(animated: false, completion: nil)//navigationController?.popToRootViewController(animated: true)
                }
            })
            return nil
        }
    }
}
