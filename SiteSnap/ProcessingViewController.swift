//
//  ProcessingViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 07.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class ProcessingViewController: UIViewController {
    @IBOutlet weak var popupView: UIView!
    static let identifier = "ProcessingViewController"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popupView.layer.cornerRadius = 8
        // Do any additional setup after loading the view.
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
