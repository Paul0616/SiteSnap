//
//  NoProjectsAssignedViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 28/02/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class NoProjectsAssignedViewController: UIViewController {

    @IBOutlet weak var signInButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.titleLabel!.lineBreakMode = .byWordWrapping
        signInButton.titleLabel!.textAlignment = .center
        signInButton.layer.cornerRadius = 6
        // Do any additional setup after loading the view.
    }
    

    @IBAction func onTapSignInButton(_ sender: UIButton) {
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
