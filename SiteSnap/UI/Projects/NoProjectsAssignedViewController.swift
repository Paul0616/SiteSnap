//
//  NoProjectsAssignedViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 28/02/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class NoProjectsAssignedViewController: UIViewController {

    @IBOutlet weak var signInButton: UIButton!
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
   // var response: AWSCognitoIdentityUserGetDetailsResponse?
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.titleLabel!.lineBreakMode = .byWordWrapping
        signInButton.titleLabel!.textAlignment = .center
        signInButton.layer.cornerRadius = 6
        // Do any additional setup after loading the view.
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
            
        }
    }
    

    @IBAction func onTapSignInButton(_ sender: UIButton) {
        self.user?.signOut()
        UserDefaults.standard.removeObject(forKey: "given_name")
        UserDefaults.standard.removeObject(forKey: "family_name")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userTappedLogOut = true
        self.refresh()
    }
    
    func refresh() {
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
               // self.response = task.result
                self.dismiss(animated: false, completion: nil)
            })
            return nil
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
