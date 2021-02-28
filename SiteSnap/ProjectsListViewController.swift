//
//  ProjectsListViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 25.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class ProjectsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var userProjects = [ProjectModel]()
    var currentProjectId: String?
    
    @IBOutlet weak var line: UIView!
    @IBOutlet weak var newProjectButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var projectsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        newProjectButton.layer.cornerRadius = 8
        closeButton.layer.cornerRadius = 8
        // Do any additional setup after loading the view.
        loadingProjectIntoList()
    }
    
    @IBAction func onCloseTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func loadingProjectIntoList(){
        // DispatchQueue.main.async {
//        if !dropDownListProjectsTableView.isHidden {
//            return
//        }
        userProjects.removeAll()
        let projectsFromDatabase = ProjectHandler.fetchAllProjects()
        for item in projectsFromDatabase! {
            var tagIds = [String]()
            for tag in item.availableTags! {
                let t = tag as! Tag
                tagIds.append(t.id!)
            }
            guard let projectModel = ProjectModel(id: item.id!, projectName: item.name!, projectOwnerName: item.projectOwnerName!, latitudeCenterPosition: item.latitude, longitudeCenterPosition: item.longitude, tagIds: tagIds) else {
                fatalError("Unable to instantiate ProductModel")
            }
            userProjects += [projectModel]
        }
        if userProjects.count == 0 {
            return
        }
        currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String
//        selectedProjectButton.hideLoading(buttonText: nil)
//        galleryButton.isEnabled = true
//        setProjectsSelected(projectId: currentProjectId)
//        dropDownListProjectsTableView.reloadData()
        projectsTableView.reloadData()
        
    }
    
    //MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProjects.count
    }
    
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "projectCell", for: indexPath) as! ProjectTableViewCell
        cell.projectTitleLabel.text = userProjects[indexPath.row].projectName
        cell.projectOwnerLabel.text = userProjects[indexPath.row].projectOwnerName
        //cell.roundCheckBox.isChecked = userProjects[indexPath.row].id == currentProjectId
        if userProjects[indexPath.row].id == currentProjectId {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.none)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
