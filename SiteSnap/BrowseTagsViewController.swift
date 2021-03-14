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
    var tagsApplied = 1
    
    @IBOutlet weak var allTagsTableView: UITableView!
    @IBOutlet weak var tagsAppliedStackView: UIStackView!
    @IBOutlet weak var applyTagLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        if self.view.safeAreaLayoutGuide.layoutFrame.size.width > self.view.safeAreaLayoutGuide.layoutFrame.size.height {
            print("landscape")
            tagsAppliedStackView.isHidden = false
            applyTagLabel.isHidden = true
        } else {
            print("portrait")
            applyTagLabel.isHidden = false
            if tagsApplied == 0 {
                tagsAppliedStackView.isHidden = true
            } else {
                tagsAppliedStackView.isHidden = false
            }
        }
    }


    @IBAction func onBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
