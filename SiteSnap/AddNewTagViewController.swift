//
//  AddNewTagViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 15.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

protocol AddNewTagViewControllerDelegate {
    func tagWasAdded()
}

class AddNewTagViewController: UIViewController, CircleCheckBoxDelegate, UITextFieldDelegate {
    //MARK: - properties
    let buttonColors: [String] = [
        "#be3436",
        "#bc145c",
        "#7d00a1",
        "#5912a7",
        "#3f339e",
        "#406dd0",
        "#3a82d0",
        "#2e96a6",
        "#1c796b",
        "#3b913d",
        "#67a23b",
        "#aab832",
        "#f4c538",
        "#f7a51e",
        "#ed801a",
        "#de4e24",
        "#5b4138",
        "#616161",
        "#485964"
    ]
    var tagButtonsList: [CircleCheckBox] = []
    var selectedColorString: String?
    var selectedTagName: String?
    var progressVC: ProcessingViewController?
    var pool: AWSCognitoIdentityUserPool?
    var delegate: AddNewTagViewControllerDelegate?
   
    
    @IBOutlet weak var tagNameTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    
    @IBOutlet weak var stack1: UIStackView!
    @IBOutlet weak var stack2: UIStackView!
    @IBOutlet weak var stack3: UIStackView!
    @IBOutlet weak var stack4: UIStackView!
    
    //MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButtonsToList()
        tagNameTextField.delegate = self
        createButton.isEnabled = false
        createButton.alpha = 0.5
        self.hideKeyboardWhenTappedAround()
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
    
    }
    
    //MARK: - PRIVATE FUNCTIONS
    fileprivate func buttonValidation(){
        if let _ = selectedTagName, !selectedTagName!.isEmpty, let _ = selectedColorString {
            createButton.isEnabled = true
            createButton.alpha = 1
        } else {
            createButton.isEnabled = false
            createButton.alpha = 0.5
        }
    }
   
    fileprivate func addButtonsToList() {
        stack1.arrangedSubviews.forEach { (view) in
            if let view = view as? CircleCheckBox{
                tagButtonsList.append(view)
            }
        }
        stack2.arrangedSubviews.forEach { (view) in
            if let view = view as? CircleCheckBox{
                tagButtonsList.append(view)
            }
        }
        stack3.arrangedSubviews.forEach { (view) in
            if let view = view as? CircleCheckBox{
                tagButtonsList.append(view)
            }
        }
        stack4.arrangedSubviews.forEach { (view) in
            if let view = view as? CircleCheckBox{
                tagButtonsList.append(view)
            }
        }
        
        for (index, button) in tagButtonsList.enumerated() {
            button.delegate = self
            button.tag = index
            button.hexColor = buttonColors[index]
        }
        print(tagButtonsList.count)
    }
    
    fileprivate func instantiateProgressVC(){
        progressVC = self.storyboard?.instantiateViewController(withIdentifier: ProcessingViewController.identifier) as? ProcessingViewController
        if let progressVC = progressVC {
            progressVC.modalPresentationStyle = .overCurrentContext
            progressVC.modalTransitionStyle = .crossDissolve
            present(progressVC, animated: true, completion: nil)
        }
    }
    
    fileprivate func dismissProgressVC(completion: (() -> Void)?) {
        // then remove the spinner view controller
        DispatchQueue.main.async(execute: {
            if let progressVC = self.progressVC{
                progressVC.dismiss(animated: true, completion: completion)
            }
        })
    }
    
    //MARK: TAP BUTTONS
    @IBAction func onCreateTap(_ sender: Any) {
        insertNewTag()
    }
    
    @IBAction func onCancelTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: CircleButtonDelegate
    func circleButtonTapped(sender: CircleCheckBox) {
        for button in tagButtonsList {
            if button != sender {
                button.isOn = false
            } else {
                if button.isOn {
                    selectedColorString = button.hexColor![button.hexColor!.index(after: button.hexColor!.startIndex)...].description //button.hexColor
                } else {
                    selectedColorString = nil
                }
            }
        }
        buttonValidation()
        print(selectedColorString ?? "no color chosen")
        
    }
  
    //MARK: TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //hide keyboard
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        selectedTagName = textField.text
        buttonValidation()
    }
    
    //MARK: - CALL API
    func insertNewTag(){
        guard let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String,
              let tagName = selectedTagName,
              !tagName.isEmpty,
              let tagColor = selectedColorString else {
            return
        }
        
        instantiateProgressVC()
        let url = URL(string: siteSnapBackendHost + "tag/createTag")!
        var request = URLRequest(url: url)
        if (self.pool?.token().isCompleted)! {
            let tokenString = "Bearer " + (self.pool?.token().result as String?)!
            request.setValue(tokenString, forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
        } else {
            return
        }
        let parameters: [String: Any] = [
            "forProject": currentProjectId,
            "tagName": tagName,
            "tagColour": tagColor,
        ]
       
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        } catch let error {
            print(error.localizedDescription)
            dismissProgressVC(completion: nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {(data, response, error) -> Void in
            guard error == nil else { //have errors code
                self.dismissProgressVC(completion: {
                   self.treatErrors(error)
                })
                return
            }
            guard let data = data else { //data is nil
                self.dismissProgressVC(completion: nil)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                print(json)
                self.dismissProgressVC(completion: { [self] in
                    treatErrorsAPI(json)
                })
            }
            catch let error as NSError
            {
                print(error.localizedDescription)
                self.dismissProgressVC(completion: nil)
            }
        }
        task.resume()
    }
    
    func treatErrors(_ error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            if let err = error as? URLError {
                var message: String?
                switch err.code {
                case .notConnectedToInternet:
                    message = "Not Connected To The Internet"
                case .timedOut:
                    message = "Request Timed Out"
                case .networkConnectionLost:
                    message = "Lost Connection to the Network"
                default:
                    print("Default Error")
                    message = "Error"
                    print(err)
                }
                
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(
                        title: "SiteSnap server access",
                        message: message,
                        preferredStyle: .alert)
                    
                    let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                        // do something when user press OK button
                    }
                    alert.addAction(OKAction)
                    self.present(alert, animated: true, completion: nil)
                
                })
            }
        }
    }
    
    func treatErrorsAPI(_ json: NSDictionary?) {
        if json != nil {
            if let error = json!["error"] as? Int{
                var title = "Error"
                var message: String?
                var handler: ((UIAlertAction) -> Void)?
                switch error {
                case 0:
                    print("Successful")
                    message = "The new tag was successfuly created."
                    title = "Success"
                    handler = { [self] (action) in
                        self.dismiss(animated: true, completion: nil)
                    }
                    if let newTagId = json!["id"] as? String {
                        if TagHandler.saveTag(id: newTagId, text: self.selectedTagName!, tagColor: self.selectedColorString) {
                            let tag = TagHandler.getSpecificTag(id: newTagId)
                            let project = ProjectHandler.getSpecificProject(id: (UserDefaults.standard.value(forKey: "currentProjectId") as? String)!)
                            project?.addToAvailableTags(tag!)
                            print("new tag was added to CoreData and assigned to current project")
                            self.dismiss(animated: true, completion: nil)
                            delegate!.tagWasAdded()
                        }
                    }
                case 1:
                    print("Invalid body, server could not decode body sent or one or more variables were sent unset")
                    message = "An error occurred when creating a new tag: The server could not understand the request. Please try again later."
                case 2:
                    print("Invalid project")
                    message = "An error occurred when creating a new tag: The project you are trying to create a tag for does not exist or you do not have the rights to add tags to it."
                case 3:
                    print("unknown error")
                    message =  "An error occurred when creating a new tag: The server returned error 0x1. Please try again later."
                case 4:
                    print("unknown error")
                    message = "An error occurred when creating a new tag: The server returned error 0x2. Please try again later."
                default:
                    print("Default error")
                }
                if error != 0{
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: title,
                            message: message ?? "",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: handler)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            }
        }
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


