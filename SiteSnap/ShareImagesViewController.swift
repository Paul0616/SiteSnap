//
//  ShareImagesViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 03.04.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import Photos

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
    
    @IBOutlet weak var addTagsButton: UIButton!
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var tagsNumberLabel: UILabel!
    @IBOutlet weak var commentAppliedLabel: UILabel!
    @IBOutlet weak var projectsTableView: UITableView!
    
    
   
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
//        self.navigationController?.navigationBar.barTintColor = UIColor.white
//        self.navigationController?.navigationBar.tintColor = UIColor.white
//        let titleDict = [NSAttributedString.Key.foregroundColor: UIColor.white]//, NSAttributedString.Key.font:constantsNaming.fontType.kOpenSans_SemiBoldLarge!]
//        self.navigationController?.navigationBar.titleTextAttributes = titleDict
       loadingProjectIntoList()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setPhotos()
        if timerBackend == nil || !timerBackend.isValid {
            timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
            timerBackend.fire()
            print("TIMER STARTED - SHARED IMAGES")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        invalidateTimer()
    }
    
    @IBAction func addTaggTapped(_ sender: Any) {
    }
    
    @IBAction func addCommentTapped(_ sender: Any) {
    }
    
    @IBAction func openSiteSnapTapped(_ sender: Any) {
    }
    
    @IBAction func uploadTapped(_ sender: Any) {
    }
    
    func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setPhotos),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    //MARK: - The called function for the timer backend
    @objc func callBackendConnection(){
        let backendConnection = BackendConnection(projectWasSelected: true, lastLocation: nil)
        backendConnection.delegate = self
        backendConnection.attemptSignInToSiteSnapBackend()
    }
    
    func invalidateTimer() {
        if timerBackend != nil {
            timerBackend.invalidate()
            print("TIMER INVALID - SHARED IMAGES")
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
        loadingProjectIntoList()
        //updateTagNumber()
    }
    
    func userNeedToCreateFirstProject() {
        
    }
    
    @objc func handleTapRoundCheckBox(sender: RoundCheckBox){
        currentProjectId = userProjects[sender.tag].id
        projectsTableView.reloadData()
        //dismiss(animated: true, completion: nil)
        print("\(currentProjectId ?? "")")
        //delegate?.projectWasSelectedFromOutside(projectId: currentProjectId!)
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
        //print(assets)
        
        //let imageManager = PHCachingImageManager()
        //Enumerating objects to get a chached image - This is to save loading time
        
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            //print(count)
            if object is PHAsset {
                let asset = object as! PHAsset
                //                print(asset)
                
               
                let latitude = (asset.location?.coordinate.latitude)!
                let longitude = (asset.location?.coordinate.longitude)!
                //photo.isHidden = false
                //photo.localIdentifierString = asset.localIdentifier
                //photo.successfulUploaded = false
                let createdDate = asset.creationDate as NSDate?
                let resources = PHAssetResource.assetResources(for: asset) // your PHAsset
                var sizeOnDisk: Int64? = 0
                if let resource = resources.first {
                    let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
                    sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
                }
                
                let photo = PhotoModel(localIdentifier: asset.localIdentifier, createdDate: createdDate, latitude: latitude, longitude: longitude, isHidden: false, fileSize: sizeOnDisk, allPhotosComment: nil, allTagsWasSet: false, individualComment: nil, successfulUploaded: false, localIdentifierForAllTags: nil, tags: nil)
                self.photoObjects.append(photo!)
                
//                let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
//                //let imageSize = CGSize(width: 100, height: 100)
//
//                let options = PHImageRequestOptions()
//                options.deliveryMode = .opportunistic
//                options.isSynchronous = true
//                options.isNetworkAccessAllowed = true
//                options.resizeMode = PHImageRequestOptionsResizeMode.exact
//
//                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFit, options: options, resultHandler: {
//                    (image, info) -> Void in
//
//                })
            }
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
