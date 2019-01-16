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
    
    @IBOutlet weak var tableView: UITableView!

    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
        // Do any additional setup after loading the view.
        tableView.delegate = self
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
            cell.menuItemIcon.image = UIImage(named: "person-80px")
            cell.menuItemTitle.text = "Account"
            cell.menuItemDescription.text = (UserDefaults.standard.value(forKey: "given_name") as? String)! + " " + (UserDefaults.standard.value(forKey: "family_name") as? String)!
        case 1:
            cell.menuItemIcon.image = UIImage(named: "upload-80px")
            cell.menuItemTitle.text = "Uploads"
            cell.menuItemDescription.text = "0 photos uploading"
        case 2:
            cell.menuItemIcon.image = UIImage(named: "settings-80px")
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
                self.refresh()
            })
            )
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                print("cancel")
            })
            )
           
            self.present(alertController, animated: true, completion: nil)

        }

    }
//     "https://backend.sitesnap.com.au:443/api/session/getPhoneSessionInfo"
    // Bearer eyJraWQiOiJEVkxHV1N4QlB4aXpLXC9STlRvXC84ckxSRFFRMUZ4dVo0azNvUDg4S1VIdFk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiI5Y2IxNTdhNS02ZTFiLTRkYzctOGIwZi1iYTVmMjVjNzM4N2EiLCJhdWQiOiI1NTMyZWhocTd1YmxvdmlhcmFzaG52dTc2byIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTU0NzU0NDc5MiwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yXzZKNUtDaDlMbiIsImNvZ25pdG86dXNlcm5hbWUiOiI5Y2IxNTdhNS02ZTFiLTRkYzctOGIwZi1iYTVmMjVjNzM4N2EiLCJleHAiOjE1NDc1NDgzOTIsImdpdmVuX25hbWUiOiJOaWNrIiwiaWF0IjoxNTQ3NTQ0NzkyLCJmYW1pbHlfbmFtZSI6IlRob3JuIiwiZW1haWwiOiJuaWNrQGF0b2xsb24uY29tLmF1In0.p1crQNfdBtHb0TWPtpJ0mNh4y5exhqFLIqofeMOup65CYMisaVvTAeRutvIrjBgUyWeBjvQWuC0P6yvXYkU3x9lHeuOto9EOjNuKlj1fJFRq1CdiNLdVzDEH_rF1MOYq6PrdIDHw79-M-0N8D4uMTm9cWBqHNmFvAOjFUCdW-c5QTwoU8NeGrtp5xa2ecL57SIn5XmA1iaac_dE2uhrIbOKHz6RDpWIACBe-XUQK2Iv2wOb7d0Gj-vfjfMMdMNDVanjXQWbAXdd2qsqw72SvHT2HlIXhxrjrPm693DJervVZ4pwkeuBi-32obhVrSGya6nYi2odbbjTscoNxbRB30Q
}


