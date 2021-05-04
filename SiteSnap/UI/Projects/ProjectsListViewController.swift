//
//  ProjectsListViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 25.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

protocol ProjectListViewControllerDelegate {
    func projectWasSelectedFromOutside(projectId: String)
    func projectsPopoverWasDismissed()
}

class ProjectsListViewController: UIViewController, UITableViewDataSource, NewProjectViewControllerDelegate, BackendConnectionDelegate {
   
    
   
    //MARK: - New Project DELEGATE
    func newProjectAddedCallback(projectModel: ProjectModel?) {
        if let project = projectModel{
            if ProjectHandler.saveProject(id: project.id, name: project.projectName, latitude: project.latitudeCenterPosition, longitude: project.longitudeCenterPosition, projectOwnerName: project.projectOwnerName) {
                print("PROJECT: \(project.projectName) added")
                loadingProjectIntoList()
            }
        }
    }
    

    var userProjects = [ProjectModel]()
    var currentProjectId: String?
    var delegate: ProjectListViewControllerDelegate?
    
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
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadingProjectIntoList()
        BackendConnection.shared.delegate = self
    }
    
    
    @IBAction func onCloseTap(_ sender: Any) {
        dismiss(animated: true, completion: {
            self.delegate?.projectsPopoverWasDismissed()
        })
    }
    
    
    func loadingProjectIntoList(){
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
        projectsTableView.reloadData()
    }
    
    @objc func handleTapRoundCheckBox(sender: RoundCheckBox){
        currentProjectId = userProjects[sender.tag].id
        //projectsTableView.reloadData()
        dismiss(animated: true, completion: nil)
        print("\(currentProjectId ?? "")")
        delegate?.projectWasSelectedFromOutside(projectId: currentProjectId!)
    }
    //MARK: - navigation


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    
        if segue.identifier == "createProjectIdentifier", let destination = segue.destination as? NewProjectViewController {
            destination.delegate = self
        }
    }
    
    //MARK: Backend delegate
    func treatErrors(_ error: Error?) {
        
    }

    func treatErrorsApi(_ json: NSDictionary?) {
        
    }

    func displayMessageFromServer(_ message: String?) {
        
    }

    func noProjectAssigned() {
        
    }

    func databaseUpdateFinished() {
        loadingProjectIntoList()
    }

    func userNeedToCreateFirstProject() {
        
    }
}



//MARK: - TableView Delegate
extension ProjectsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "projectCell", for: indexPath) as! ProjectTableViewCell
        cell.projectTitleLabel.text = userProjects[indexPath.row].projectName
        cell.projectOwnerLabel.text = userProjects[indexPath.row].projectOwnerName
        cell.roundCheckBox.tag = indexPath.row
        cell.roundCheckBox.addTarget(self, action: #selector(handleTapRoundCheckBox(sender:)), for: .allTouchEvents)
        cell.roundCheckBox.isChecked = userProjects[indexPath.row].id == currentProjectId
//        if userProjects[indexPath.row].id == currentProjectId {
//            //currentProjectId = userProjects[sender.tag].id
//            currentIndex = indexPath.row
//            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.none)
//        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

