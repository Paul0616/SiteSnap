//
//  SettingsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 21/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    @IBOutlet weak var backButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
//        let configuration = URLSessionConfiguration.default
//        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onClickBack(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }
    //MARK: - TABLE view delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! SettingsTableViewCell
        cell.settingLabel?.textColor = UIColor.white
        cell.settingLabel?.text = "Save photos to gallery automatically"
        cell.settingSwitch.tag = indexPath.row
        if let status = UserDefaults.standard.value(forKey: "saveToGallery") as? Bool {
            cell.settingSwitch.isOn = status
        } else {
            cell.settingSwitch.isOn = true
        }//== nil ? true : UserDefaults.standard.bool(forKey: "saveToGallery")
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    @IBAction func onSwitchSetting(_ sender: UISwitch) {
        if sender.tag == 0 {
            UserDefaults.standard.set(sender.isOn, forKey: "saveToGallery")
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