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
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.text = "Account \(user?.username)"
        cell.tag = indexPath.row
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        if selectedCell.tag == 0 {
            self.user?.signOut()
            self.refresh()
//            let cameraViewController = storyboard!.instantiateViewController(withIdentifier: "initController") as? CameraViewController
//
//
//            DispatchQueue.main.async {
//                if (!cameraViewController!.isViewLoaded || cameraViewController!.view.window == nil) {
//                    self.present(cameraViewController!, animated: true, completion: nil)
//                }
//            }
        }
//        if tableView == dropDownListProjectsTableView {
//            projectId = userProjects[indexPath.row].id
//            selectedProjectButton.setTitle("\(userProjects[indexPath.row].projectName)", for: .normal)
//            animateProjectsList(toogle: false)
//            let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
//            selectedCell.contentView.backgroundColor = UIColor.black
//            setProjectsSelected(projectId: projectId)
//        }
    }
}
