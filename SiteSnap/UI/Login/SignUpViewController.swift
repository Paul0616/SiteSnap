//
//  SignUpViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 23.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    private var reCAPTCHAViewModel: ReCAPTCHAViewModel?
    private var vc: ReCAPTCHAViewController!

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var surNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userWantToSignUp = true
        cancelButton.layer.cornerRadius = 10
        signUpButton.layer.cornerRadius = 10
        firstNameTextField.delegate = self
        surNameTextField.delegate = self
        emailTextField.delegate = self
        signUpButton.isEnabled = false
        signUpButton.alpha = 0.5
        print(isEmailValid("aaa@bbro"))
    }
    
    @IBAction func dismissSignUp(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func signUpPressed(_ sender: Any) {
       
        print(isEmailValid(emailTextField.text!))
        callReCAPTCHA()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let viewModel = ReCAPTCHAViewModel(
            siteKey: "6Ld5XuoUAAAAAEkoXMJrQESQTsqErZae2Ze_Wekr",
            url: URL(string: "https://app.sitesnap.com.au")!
        )
        viewModel.delegate = self
        reCAPTCHAViewModel = viewModel
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userWantToSignUp = false
    }
    
    
    private func isEmailValid(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func callReCAPTCHA(){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: ReCAPTCHAViewController.identifier) as? ReCAPTCHAViewController
        vc!.viewModel = reCAPTCHAViewModel
        vc!.modalPresentationStyle = .overCurrentContext
        vc!.modalTransitionStyle = .crossDissolve
        if let vc = vc {
            self.vc = vc
            present(self.vc, animated: true)
        }
    }
    
    

    //MARK: - UItextfieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //hide keyboard
        if textField == firstNameTextField{
            surNameTextField.becomeFirstResponder()
        } else if textField == surNameTextField {
            emailTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            //attemptLogin()
        }
        return true
    }
    
   
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == firstNameTextField || textField == surNameTextField || textField == emailTextField {
            animateViewMoving(up: true, moveValue: 100)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == firstNameTextField || textField == surNameTextField || textField == emailTextField {
            animateViewMoving(up: false, moveValue: 100)
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == emailTextField{
            if(firstNameTextField.text != nil && surNameTextField.text != nil && isEmailValid(emailTextField.text!)){
                signUpButton.isEnabled = true
                signUpButton.alpha = 1
            } else {
                signUpButton.isEnabled = false
                signUpButton.alpha = 0.5
            }
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
    
    func callToSignUp(token: String){
        let request = makeUrlRequest(token: token)
        if let request = request {
            let task = URLSession.shared.dataTask(with: request as URLRequest) {(data, response, error) -> Void in
                guard error == nil else {
                    //self.treatErrors(error: error)
                   // self.delegate?.treatErrors(error)
                    return
                }
                guard let data = data else {
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    print(json)
                    self.treatErrors(json)
                    //self.setUpInternalTables(json: json)
                }
                catch let error as NSError
                {
                    print(error.localizedDescription)
                }
            }
            task.resume()
        }
    }
    
    func makeUrlRequest(token: String) -> URLRequest! {
        let url = URL(string: siteSnapBackendHost + "signup/signUpToSiteSnap")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "firstName": firstNameTextField.text!,
            "surname": surNameTextField.text!,
            "email": emailTextField.text!,
            "token": token,
            "isFromAndroid": false,
            "isFromiOS": true
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        return request
    }
    
    func treatErrors(_ json: NSDictionary?) {
        if json != nil {
            //print(error?.localizedDescription as Any)
            if let error = json!["error"] as? Int{
                //var errorMessage: String?
                switch error {
                case 0:
                    print("Successful")
                    DispatchQueue.main.async(execute: {
                    
                        let alert = UIAlertController(
                            title: "Success",
                            message: "A temporary password has been emailed to you.\n\nPress OK to return to the sign in screen and enter your password to continue.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            self.dismiss(animated: true, completion: nil)
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 1...3:
                    print("Malformed data")
                    
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Something went wrong when creating your account.\n\nThe server could not understand the request from your phone. Please try again later.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 4:
                    print("eMail already in system : and site snap pro user")
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "The email address provided is already associated with a Site Snap PRO user account. If you have forgotten your password please tap the CANCEL button and then the \"Forgot your password? TAP HERE\" box.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 5:
                    print("eMail already in system : and is site snap free user that has completed sign up")
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "The email address provided is already associated with another Site Snap user account. If you have forgotten your password please tap the CANCEL button and then the \"Forgot your password? TAP HERE\" box.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 6:
                    print("eMail already in system : and is site snap free user that hasn't completed sign up yet")
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Alert",
                            message: "The email address provided is already associated with another Site Snap user account. Your temporary password has been sent to your email account. Please use the password given to you in that email to sign in with.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 7:
                    print("cognito fail")
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Site Snap is experiencing an internal authorization error. If this issue persists, please contact Site Snap support.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 8:
                    print("database connection fail")
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Site Snap is experiencing an internal database access error. If this issue persists, please contact Site Snap support.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 9:
                    print("cognito init auth fail")
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Site Snap is experiencing an internal database save error. If this issue persists, please contact Site Snap support.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case 10:
                    print("captcha error")
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Captcha expired! Please try again.",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                default:
                    print("Default error")
                }
            }
        }
    }

}

extension SignUpViewController: ReCAPTCHAViewModelDelegate {
    func didSolveCAPTCHA(token: String) {
        print("Token: \(token)")
        self.vc.dismiss(animated: true, completion: nil)
        callToSignUp(token: token)
    }
}
