//
//  BrowseTagsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class BrowseTagsViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    var tagsApplied = 0
    
    @IBOutlet weak var allTagsTableView: UITableView!
    @IBOutlet weak var tagsAppliedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTablesView()
        // Do any additional setup after loading the view.
    }
    

    @IBAction func onBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setupTablesView() {
        if tagsApplied == 0 {
            tagsAppliedTableView.isHidden = true
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
