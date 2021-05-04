//
//  ShareImagesViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 03.04.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import Photos
import AWSCognitoIdentityProvider

class ShareImagesViewController: UIViewController, UITableViewDataSource, BackendConnectionDelegate {
   

    private let groupName = "group.com.au.tridenttechnologies.sitesnapapp"
    private let userDefaultsKey = "incomingLocalIdentifiers"
    let darkBlue: UIColor = UIColor(red: 17/255, green: 15/255, blue: 62/255, alpha: 1.0)
    let systemGray6: UIColor = .systemGray6
    private var sharedImagesIdentifiers: [String]!
    
    
    var timerBackend: Timer!
    var userProjects = [ProjectModel]()
    var currentProjectId: String?
    var photoObjects = [PhotoModel]()
    var currentTags = [TagModel]()
    var currentCommentText: String?
    
    @IBOutlet weak var addTagsButton: UIButton!
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var tagsNumberLabel: UILabel!
    @IBOutlet weak var commentAppliedLabel: UILabel!
    @IBOutlet weak var projectsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var isUserLogged: Bool = false
    var timerAuthenticationCognito: Timer!
    
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotification()
        addTagsButton.layer.cornerRadius = 25
        tagsNumberLabel.layer.cornerRadius = 15
        tagsNumberLabel.textColor = darkBlue
        tagsNumberLabel.layer.backgroundColor = systemGray6.cgColor
        tagsNumberLabel.layer.borderColor = darkBlue.cgColor
        tagsNumberLabel.layer.borderWidth = 1
        tagsNumberLabel.isHidden = true
        addCommentButton.layer.cornerRadius = 25
        commentAppliedLabel.layer.cornerRadius = 15
        commentAppliedLabel.textColor = darkBlue
        commentAppliedLabel.layer.backgroundColor = systemGray6.cgColor
        commentAppliedLabel.layer.borderColor = darkBlue.cgColor
        commentAppliedLabel.layer.borderWidth = 1
        commentAppliedLabel.isHidden = true
        print("=======>>>>>>>>>>>>>>>>>>> load currentProjectId = \(String(describing: currentProjectId))")
        if currentProjectId == nil {
            self.currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String
        }
        if let currentProjectId = currentProjectId {
            currentTags = ProjectHandler.getTagsForProject(projectId: currentProjectId)
        }
        //activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        projectsTableView.isHidden = true
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
            if let username = (self.user?.username) {
                print("USER = CURRENT USER = \(String(describing: username))")
            }
            if let _userlogged = self.user?.isSignedIn {
                isUserLogged = _userlogged
                
            }
        }
        
        if !(pool?.token().isCompleted ?? false) {
            self.showToast(message: "token completed \(String(describing: pool?.token().isCompleted))", font: .systemFont(ofSize: 14))
            timerAuthenticationCognito = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        } else {
            BackendConnection.shared.delegate = self
            startBackendConnection()
        }
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setPhotos()
//        if let _ = pool?.token().isCompleted {
//            startBackendConnection()
//
//        }
        showToast(message: "Delegate self", font: .systemFont(ofSize: 16))
        BackendConnection.shared.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        invalidateTimer()
    }
    
    @IBAction func addTaggTapped(_ sender: Any) {
        if let _ = currentProjectId {
//            if !currentTags.isEmpty {
                performSegue(withIdentifier: "ShareExtensionAddTagSegue", sender: nil)
//            } else {
//                let alert = UIAlertController(
//                    title: "SiteSnap",
//                    message: "There are no tags available for this project.",
//                    preferredStyle: .alert)
//                let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
//                    // do something when user press OK button
//                }
//                alert.addAction(OKAction)
//                self.present(alert, animated: true, completion: nil)
//            }
        } else {
            let alert = UIAlertController(
                title: "SiteSnap",
                message: "Please select a project first.",
                preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                // do something when user press OK button
            }
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func addCommentTapped(_ sender: Any) {
        
        if let _ = currentProjectId {
           performSegue(withIdentifier: "ShareExtensionAddCommentSegue", sender: nil)
        } else {
            let alert = UIAlertController(
                title: "SiteSnap",
                message: "Please select a project first.",
                preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                // do something when user press OK button
            }
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func openSiteSnapTapped(_ sender: Any) {
        guard !photoObjects.isEmpty else {
            return
        }
        guard isUserLogged else {
            return
        }
        if let oldPhotos = PhotoHandler.fetchAllObjects(excludeUploaded: true), !oldPhotos.isEmpty{
            var oldPhotosCount = 0
            for oldPhoto in oldPhotos {
                if !photoObjects.map({$0.localIdentifierString}).contains(oldPhoto.localIdentifierString) {
                    oldPhotosCount += 1
                }
            }
            let alert = UIAlertController(
                title: "SiteSnap",
                message: "There are already \(oldPhotosCount) images, which do not appear to have been uploaded. They will be assigned the current project.",
                preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                UserDefaults.standard.set(self.currentProjectId, forKey: "currentProjectId")
                let currentProjectName = self.userProjects.first(where: {$0.id == self.currentProjectId})?.projectName
                UserDefaults.standard.set(currentProjectName, forKey: "currentProjectName")
                UserDefaults.standard.set(true, forKey: "projectWasSelected")
                self.addCurrentPhotosToDatabase()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = storyboard.instantiateViewController(identifier: "photosViewController") as! PhotosViewController
                viewController.modalPresentationStyle = .fullScreen
                viewController.wasCalledFromImageSharing = true
                self.present(viewController, animated: true, completion: nil)
            }
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
        }
        
    
    }
    
    @IBAction func uploadTapped(_ sender: Any) {
        guard !photoObjects.isEmpty else {
            return
        }
        guard isUserLogged else {
            return
        }
        addCurrentPhotosToDatabase()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: "uploadViewController") as! UploadsViewController
        viewController.modalPresentationStyle = .fullScreen
        viewController.projectIdToUploadToFromSharing = currentProjectId
        self.present(viewController, animated: true, completion: nil)
    }
    
    
    @objc func refresh() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userTappedLogOut = false
        
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async {
                self.response = task.result
                UserDefaults.standard.set(self.user?.deviceId, forKey: "deviceId")
                print("RESPONSE to refresh user")
                self.showToast(message: "RESPONSE to refresh user", font: .systemFont(ofSize: 14))
                for attribute in (self.response?.userAttributes)! {
                    if attribute.name == "given_name" {
                        UserDefaults.standard.set(attribute.value, forKey: "given_name")
                    }
                    if attribute.name == "family_name" {
                        UserDefaults.standard.set(attribute.value, forKey: "family_name")
                    }
                    if attribute.name == "email" {
                        UserDefaults.standard.set(attribute.value, forKey: "email")
                    }
                }
                if (self.pool?.token().isCompleted)! {
                    UserDefaults.standard.set(self.pool?.token().result, forKey: "token")
                    print(self.pool?.token().result as Any)
                    self.timerAuthenticationCognito.invalidate()
                    if let _userlogged = self.user?.isSignedIn {
                        self.isUserLogged = _userlogged
                    }
                    self.startBackendConnection()
                } else {
                    UserDefaults.standard.removeObject(forKey: "token")
                }
                print("USER DEFAULTS SETTED")
                self.showToast(message: "USER DEFAULTS SETTED", font: .systemFont(ofSize: 14))
            }
            return nil
        }
    }
    
    func startBackendConnection(){
        if timerBackend == nil || !timerBackend.isValid {
            timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
            timerBackend.fire()
            print("TIMER STARTED - SHARED IMAGES")
        }
    }
    
    func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setPhotos),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    func addCurrentPhotosToDatabase(){
        guard !photoObjects.isEmpty else {
            return
        }
        for photo in photoObjects{
            if let _photo = PhotoHandler.getSpecificPhoto(localIdentifier: photo.localIdentifierString) {
                let _ = PhotoHandler.removePhoto(localIdentifier: _photo.localIdentifierString!)
            }
            
            if PhotoHandler.savePhotoInMyDatabase(localIdentifier: photo.localIdentifierString, creationDate: photo.createdDate! as Date, latitude: photo.latitude, longitude: photo.longitude, isHidden: false, comeFromSharing: true){
                if let commentText = currentCommentText {
                    let _ = PhotoHandler.updateComment(localIdentifier: photo.localIdentifierString, comment: commentText)
                }
                if !currentTags.isEmpty {
                    if let _photo = PhotoHandler.getSpecificPhoto(localIdentifier: photo.localIdentifierString){
                        for tagModel in currentTags {
                            if tagModel.selected {
                                _photo.addToTags(tagModel.tag)
                                tagModel.tag.addToPhotos(_photo)
                            }
                        }
                    }
                }
            }
        }
       
        PhotoHandler.setFileSize(localIdentifiers: photoObjects.map{$0.localIdentifierString})
    }
    
    //MARK: - The called function for the timer backend
    @objc func callBackendConnection(){
//        let backendConnection = BackendConnection.shared
//        backendConnection.delegate = self
        BackendConnection.shared.attemptSignInToSiteSnapBackend(projectWasSelected: true, lastLocation: nil)
        
    }
    
    func invalidateTimer() {
        if timerBackend != nil {
            timerBackend.invalidate()
            print("TIMER INVALID - SHARED IMAGES")
        }
    }
    
    func updateTagsButton(){
        if !currentTags.filter({$0.selected}).isEmpty {
            tagsNumberLabel.text = String(currentTags.filter({$0.selected}).count)
            tagsNumberLabel.isHidden = false
        } else {
            tagsNumberLabel.text = "0"
            tagsNumberLabel.isHidden = true
        }
    }
    
    func updateCommentButton(){
        if let currentCommentText = currentCommentText, !currentCommentText.isEmpty {
            commentAppliedLabel.isHidden = false
        } else {
            commentAppliedLabel.isHidden = true
        }
    }
    
    //MARK: - Connect to SITESnap function DELEGATE
    func treatErrors(_ error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            if let err = error as? URLError {
                switch err.code {
                case .notConnectedToInternet:
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "SiteSnap server access",
                            message:"Not Connected To The Internet",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case .timedOut:
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "SiteSnap server access",
                            message:"Request Timed Out",
                            preferredStyle: .alert)
                        
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case .networkConnectionLost:
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "SiteSnap server access",
                            message:"Lost Connection to the Network",
                            preferredStyle: .alert)
                        
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                default:
                    print("Default Error")
                    print(err)
                }
            }
        }
    }
    
    func treatErrorsApi(_ json: NSDictionary?) {
    }
    
    func displayMessageFromServer(_ message: String?) {
        if let message = message{
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(
                    title: nil,
                    message: message,
                    preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    // do something when user press OK button
                }
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    func noProjectAssigned() {
    
    }
    
    func databaseUpdateFinished() {
        projectsTableView.isHidden = false
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
        loadingProjectIntoList()
        //updateTagNumber()
        showToast(message: "DatabaseUpdated", font: .systemFont(ofSize: 14))
    }
    
    func userNeedToCreateFirstProject() {
        
    }
    
    @objc func handleTapRoundCheckBox(sender: RoundCheckBox){
        currentProjectId = userProjects[sender.tag].id
        UserDefaults.standard.set(currentProjectId, forKey: "currentProjectId")
        let project = ProjectHandler.getSpecificProject(id: currentProjectId!)
        print(project?.name)
        currentTags = ProjectHandler.getTagsForProject(projectId: currentProjectId!)
        updateTagsButton()
        projectsTableView.reloadData()
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
        if currentProjectId == nil {
            self.currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String
        } else {
            let project = ProjectHandler.getSpecificProject(id: currentProjectId!)
            print(project?.name)
        }
        if currentTags.isEmpty {
            currentTags = ProjectHandler.getTagsForProject(projectId: currentProjectId!)
            let project = ProjectHandler.getSpecificProject(id: currentProjectId!)
            print(project?.name)
        }
        projectsTableView.reloadData()
    }
    
    @objc func setPhotos(){
        if let incomingLocalIdentifiers = UserDefaults(suiteName: groupName)?.value(forKey: userDefaultsKey) as? [String], incomingLocalIdentifiers.count > 0 {
            sharedImagesIdentifiers = incomingLocalIdentifiers
           
            loadImages()
            UserDefaults(suiteName: groupName)?.removeObject(forKey: userDefaultsKey)
        }
    }

    private func loadImages(){
        //This will fetch all the assets in the collection
        
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: sharedImagesIdentifiers , options: nil)
    
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
        
            if object is PHAsset {
                let asset = object as! PHAsset
              
                var latitude: Double = 0
                var longitude: Double = 0
                if let location = asset.location{
                    latitude = (location.coordinate.latitude)
                    longitude = (location.coordinate.longitude)
                }
                let createdDate = asset.creationDate as NSDate?
                let resources = PHAssetResource.assetResources(for: asset) // your PHAsset
                var sizeOnDisk: Int64? = 0
                if let resource = resources.first {
                    let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
                    sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
                }
                
                let photo = PhotoModel(localIdentifier: asset.localIdentifier, createdDate: createdDate, latitude: latitude, longitude: longitude, isHidden: false, fileSize: sizeOnDisk, allPhotosComment: nil, allTagsWasSet: false, individualComment: nil, successfulUploaded: false, localIdentifierForAllTags: nil, tags: nil)
                self.photoObjects.append(photo!)
 
            }
        }
    }
    
    // MARK: - Navigation
    @IBAction func unwindFromBrowseTags(segue: UIStoryboardSegue) {
    
        if let sourceViewController = segue.source as? BrowseTagsViewController {
            print(sourceViewController.description)
            print(sourceViewController.tags.count)
            currentTags = sourceViewController.tags
            updateTagsButton()
            if timerBackend == nil || !timerBackend.isValid {
                timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
                print("TIMER STARTED - photos")
            }
        }
    }
    
    @IBAction func unwindFromAddComents(segue: UIStoryboardSegue) {
    
        if let sourceViewController = segue.source as? AddCommentsViewController {
        
            currentCommentText = sourceViewController.commentTextview.text
            updateCommentButton()
            if timerBackend == nil || !timerBackend.isValid {
                timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
                print("TIMER STARTED - photos")
            }
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if  segue.identifier == "ShareExtensionAddTagSegue",
            let destination = segue.destination as? BrowseTagsViewController {
            destination.tags = currentTags
            destination.projectWasSelected = true
        }
        if  segue.identifier == "ShareExtensionAddCommentSegue",
            let destination = segue.destination as? AddCommentsViewController {
            destination.textForEdit = currentCommentText ?? ""
        }
    }

}
//MARK: - TableView Delegate
extension ShareImagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "projectCell", for: indexPath) as! ProjectTableViewCell
        cell.projectTitleLabel1.text = userProjects[indexPath.row].projectName
        cell.projectOwnerLabel1.text = userProjects[indexPath.row].projectOwnerName
        cell.roundCheckBox1.tag = indexPath.row
        cell.roundCheckBox1.addTarget(self, action: #selector(handleTapRoundCheckBox(sender:)), for: .allTouchEvents)
        cell.roundCheckBox1.isChecked = userProjects[indexPath.row].id == currentProjectId

        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension UIViewController {
    func showToast(message : String, font: UIFont) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            }
        )
    }
}
