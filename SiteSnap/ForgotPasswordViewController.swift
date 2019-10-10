//
//  ForgotPasswordViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 20/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {

    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    @IBOutlet weak var emailAddressTextField: UITextField!
    @IBOutlet weak var resetButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        resetButton.layer.cornerRadius = 6
        emailAddressTextField.text = UserDefaults.standard.value(forKey: "email") as? String
        // Do any additional setup after loading the view.
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        emailAddressTextField.delegate = self
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userWantToResetPassword = true
    }
    
    
    //MARK: - UItextfieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //hide keyboard
        if textField == emailAddressTextField{
            textField.resignFirstResponder()
        }
        return true
    }

    @IBAction func onTapreset(_ sender: UIButton) {
        guard let username = self.emailAddressTextField.text, !username.isEmpty else {
            
            let alertController = UIAlertController(title: "Missing email address",
                                                    message: "Please enter a valid email address.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion:  nil)
            return
        }
        
        self.user = self.pool?.getUser(self.emailAddressTextField.text!)
        self.user?.forgotPassword().continueWith{[weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else {return nil}
            DispatchQueue.main.async(execute: {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    
                    self?.present(alertController, animated: true, completion:  nil)
                } else {
                    strongSelf.performSegue(withIdentifier: "confirmForgotPasswordSegue", sender: sender)
                }
            })
            return nil
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let newPasswordViewController = segue.destination as? ConfirmForgotPasswordViewController {
            newPasswordViewController.user = self.user
        }
    }
    

}
