//
//  MenuViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 13/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!

    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var failedPhotosNumber: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
        // Do any additional setup after loading the view.
        tableView.delegate = self
        failedPhotosNumber = PhotoHandler.getFailedUploadPhotosNumber()
        versionLabel.text = "Version "
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        versionLabel.text = versionLabel.text?.appending(appVersion!)
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppDelegate.AppUtility.lockOrientation(.portrait)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Don't forget to reset when view is being removed
        AppDelegate.AppUtility.lockOrientation(.all)
    }

    @IBAction func onClickBack(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func refresh() {
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
                self.response = task.result
                self.dismiss(animated: false, completion: nil)
            })
            return nil
        }
    }
    //MARK: - TABLE view delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath) as! MenuTableViewCell
        //cell.textLabel?.textColor = UIColor.black
        //cell.textLabel?.text = "Account \(user?.username)"
        cell.tag = indexPath.row
        switch indexPath.row {
        case 0:
            cell.menuItemIcon.image = UIImage(named: "person")
            cell.menuItemTitle.text = "Account"
            cell.menuItemDescription.text = (UserDefaults.standard.value(forKey: "given_name") as? String)! + " " + (UserDefaults.standard.value(forKey: "family_name") as? String)!
        case 1:
            cell.menuItemIcon.image = UIImage(named: "upload")
            cell.menuItemTitle.text = "Uploads"
            cell.menuItemDescription.text = "\(failedPhotosNumber) photos failed to upload"
        case 2:
            cell.menuItemIcon.image = UIImage(named: "settings")
            cell.menuItemTitle.text = "Settings"
            cell.menuItemDescription.text = ""
        default:
            print("default")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        if selectedCell.tag == 0 {
            let alertController = UIAlertController(title: "Please confirm choice",
                                                    message: "Would you like to sign out and be taken to sign in page?",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.user?.signOut()
                UserDefaults.standard.removeObject(forKey: "given_name")
                UserDefaults.standard.removeObject(forKey: "family_name")
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.userTappedLogOut = true
                self.refresh()
            })
            )
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                print("cancel")
            })
            )
           
            self.present(alertController, animated: true, completion: nil)

        }
        if selectedCell.tag == 2 {
            performSegue(withIdentifier: "SettingSegue", sender: nil)
        }

    }

}


