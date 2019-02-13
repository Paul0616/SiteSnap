//
//  CameraViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 13/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import AssetsPickerViewController
import CoreLocation
import CoreData
import AWSCognitoIdentityProvider


class CameraViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
 
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
    private let sessionAPIQueue = DispatchQueue(label: "session API")
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    private var cameraSetupResult: SessionSetupResult = .success
    private var locationSetupResult: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
    private var librarySetupResult: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    var defaultVideoDevice: AVCaptureDevice?
    private let photoOutput = AVCapturePhotoOutput()

    var cameraHasFlash: Bool = true
    var currentFlashMode = AVCaptureDevice.FlashMode.auto
    private var keyValueObservations = [NSKeyValueObservation]()
    
    var locationManager: CLLocationManager!
    var lastLocation: CLLocation!
    var assetCollection: PHAssetCollection!
    var albumFound : Bool = false
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    var currentPhoto: UIImage!
    var projectImages = [UIImage]()
    var photosLocalIdentifierArray: [String]?
    
    var processingPopup = ProcessingPopup()
    var photoObjects = [Photo]()
    var photoDatabaseShouldBeDeleted = false
    
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var userLogged: Bool = false
   
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var capturePreviewView: PreviewView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var captureInnerButton: UIView!
    @IBOutlet weak var selectedProjectButton: ActivityIndicatorButton!
    @IBOutlet weak var noValidLocationIcon: UIImageView!
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var cameraUnavailableLabel: UILabel!
    @IBOutlet weak var dropDownListProjectsTableView: UITableView!
    
    var userProjects = [ProjectModel]()
    //var projectId: String = ""
    var selectedFromGallery: Bool = false
    
    
    //MARK: - Loading Camera View Controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.removeObject(forKey: "currentProjectId")
        UserDefaults.standard.removeObject(forKey: "currentProjectName")
        dropDownListProjectsTableView.isHidden = true
        capturePreviewView.session = session
        capturePreviewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 5
        captureButton.backgroundColor = nil
        captureInnerButton.backgroundColor = UIColor.white
        captureInnerButton.layer.cornerRadius = 24
        captureButton.layer.cornerRadius = 35
        galleryButton.isEnabled = false
        
        noValidLocationIcon.isHidden = true
        if photoDatabaseShouldBeDeleted {
            for tag in TagHandler.fetchObjects()! {
                tag.photos = nil
            }
            if let saveToGallery = UserDefaults.standard.value(forKey: "saveToGallery") as? Bool {
                if !saveToGallery {
                    if let hiddenPhotoIds = PhotoHandler.getHiddenAndUploadedPhotosForDelelete() {
                        deleteAssets(withIdentifiers: hiddenPhotoIds)
                    }
                }
            }
            if let uploadedPhotoIds = PhotoHandler.getUploadedPhotosForDelelete() {
                if PhotoHandler.photosDeleteBatch(identifiers: uploadedPhotoIds) {
                    print("all uploaded photos was deleted from Core Data")
                }
            }
            
            userProjects.removeAll()
            photoDatabaseShouldBeDeleted = false
        }
        
        
        photoObjects = PhotoHandler.fetchAllObjects()!
       print("there ARE \(photoObjects.count) photos")
        //CHECK LAST LOG IN
        // if !userLogged {
            self.showProjectLoadingIndicator()
            self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
            if (self.user == nil) {
                self.user = self.pool?.currentUser()
                print("USER = CURRENT USER = \(String(describing: self.user?.username))")
            }
            self.refresh()
             videoAuthorization()
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let prjId = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            self.setProjectsSelected(projectId: prjId)
        }
        sessionQueue.async {
            switch self.cameraSetupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                do{
                    try self.videoDeviceInput.device.lockForConfiguration()
                    //videoDevice.focusMode = .continuousAutoFocus
                    self.videoDeviceInput.device.isSubjectAreaChangeMonitoringEnabled = true
                    self.videoDeviceInput.device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "SiteSnap doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "SiteSnap", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "SiteSnap", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        permissionLocationIfDenied()
        permissionLibraryIfDenied()
        if selectedFromGallery {
            selectedFromGallery = false
            performSegue(withIdentifier: "PhotsViewIdentifier", sender: nil)
        }
        
     //   }
    }
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.cameraSetupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let videoPreviewLayerConnection = capturePreviewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    //MARK: - Connect to SITESnap Backend API
    func attemptSignInToSiteSnapBackend()
    {
        let url = URL(string: siteSnapBackendHost + "session/getPhoneSessionInfo")!
        var request = URLRequest(url: url)
        let tokenString = "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String)!
        request.setValue(tokenString, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest)
        {(data,response,error) -> Void in
            if error != nil {
                print(error?.localizedDescription as Any)
                if let err = error as? URLError {
                    switch err.code {
                    case .notConnectedToInternet:
                        DispatchQueue.main.async(execute: {
                            let alert = UIAlertController(
                                title: "Failed to Login",
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
                                title: "Failed to Login",
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
                                title: "Failed to Login",
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
                return
            }
            
            do
            {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                self.setUpInternalTables(json: json)

            }
            catch let error as NSError
            {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func setUpInternalTables(json: NSDictionary){
        let projects = json["projects"] as! NSArray
        let projectId = json["lastUsedProjectId"] as! String
        
        UserDefaults.standard.set(projectId, forKey: "currentProjectId")
        
        let allTags = json["tags"] as! NSArray
        
        //-----------------------  check if photos from CoreData is still in gallery and if not detele them from CoreData
        for photo in photoObjects {
            let photoId = photo.localIdentifierString
            let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoId!] , options: nil)
            if assets.count == 0 {
                if PhotoHandler.photosDeleteBatch(identifiers: [photoId!]) {
                    print("Photo with is: \(String(describing: photoId)) was deleted")
                }
            }
            
        }

        self.userProjects.removeAll()
        for item in projects {
            let project = item as! NSDictionary
            let pID = project["id"]! as! String
            if pID == projectId {
               UserDefaults.standard.set(project["name"]! as! String, forKey: "currentProjectName")
            }
            let coord = project["projectCenterPosition"] as! NSArray
            let tags = project["tagIds"] as! NSArray
            
            //-------------------- make a list with all tag ids for current project from server
            var tagIds = [String]()
            for tag in tags {
                tagIds += [tag as! String]
            }
            //--------------------- fill the model with projects
            guard let projectModel = ProjectModel(id: project["id"]! as! String, projectName: project["name"]! as! String, latitudeCenterPosition: coord[0] as! Double, longitudeCenterPosition: coord[1] as! Double, tagIds: tagIds) else {
                fatalError("Unable to instantiate ProductModel")
            }
            self.userProjects += [projectModel]
        }
        DispatchQueue.main.async {
            //--------------------- clean projects Coredata and add projects from model
            if ProjectHandler.deleteAllProjects() {
                for projectModel in self.userProjects {
                    if ProjectHandler.saveProject(id: projectModel.id, name: projectModel.projectName, latitude: projectModel.latitudeCenterPosition, longitude: projectModel.longitudeCenterPosition) {
                        print("PROJECT: \(projectModel.projectName) added")
                    }
                }
            }
            
            //------------------------ 
            //----------------------- add extra tags from server to CoreData (saveTag will add new tag only if it not already exist)
            var allTagIds: [String]!
            if allTags.count > 0 {
                allTagIds = [String]()
            }
            for item in allTags {
                let tag = item as! NSDictionary
                allTagIds.append(tag["id"] as! String)
                if TagHandler.saveTag(id: tag["id"] as! String, text: tag["name"] as! String, tagColor: tag["colour"] as! String?) {
                    print("TAG \(tag["name"] as! String) \(tag["id"] as! String) with was added")
                }
            }
            let deletedTagsNumber = TagHandler.deleteExtraTags(tagsForVerification: allTagIds)
            print("\(deletedTagsNumber) tags was deleted")
            
            //------------------------ for each project from CoreData find the corespondent in projectModel
            //------------------------ and set each project from CoreData associated tags
            if let projectsRecords = ProjectHandler.fetchAllProjects() {
                for item in projectsRecords {
                    for projectModel in self.userProjects {
                        if projectModel.id == item.id {
                            let currentProjectTagIds = projectModel.tagIds
                            for tagId in currentProjectTagIds {
                                if let tagRecord = TagHandler.getSpecificTag(id: tagId) {
                                    item.addToAvailableTags(tagRecord)
                                }
                            }
                        }
                        break
                    }
                }
            }
            //-------------------- for each tag from CoreData set associated project
            for tagItem in TagHandler.fetchObjects()! {
                for projectItem in ProjectHandler.fetchAllProjects()! {
                    for associatedTag in projectItem.availableTags! {
                        let tag = associatedTag as! Tag
                        if tag.id == tagItem.id {
                            tagItem.addToProjects(projectItem)
                        }
                    }
                }
            }
            
        }
        print(json)
        self.loadingProjectIntoList()
    }
    //MARK: - PERMISSIONS / AUTHORIZATIONS
    func videoAuthorization(){
        
            
        
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If the user denies audio access, AVCam won't
         record audio during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.cameraSetupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            cameraSetupResult = .notAuthorized
        }
       
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    func libraryAuthorization() {
        let photos = librarySetupResult
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                self.librarySetupResult = status
            })
        }
    }
    
    func permissionLibraryIfDenied(){
        switch self.librarySetupResult {
        case .restricted, .denied:
            let changePrivacySetting = "SiteSnap doesn't have permission to accsess photo library, please change privacy settings"
            let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access photo library")
            let alertController = UIAlertController(title: "SiteSnap", message: message, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                    style: .cancel,
                                                    handler: nil))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                    style: .`default`,
                                                    handler: { _ in
                                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                  options: [:],
                                                                                  completionHandler: nil)
            }))
            
            self.present(alertController, animated: true, completion: nil)
            break
        case .notDetermined:
            break
        case .authorized:
            break
        }
    }
    
    func checkPermissionLibrary() {
        switch librarySetupResult {
        case .authorized:
            print("Access was already granted.")
            let picker = AssetsPickerViewController()
            picker.pickerDelegate = self
            picker.pickerConfig.albumIsShowEmptyAlbum = false
            self.present(picker, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in print("status is \(newStatus)")
                if newStatus == PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("Success. Access was granted.")
                    let picker = AssetsPickerViewController()
                    picker.pickerDelegate = self
                    picker.pickerConfig.albumIsShowEmptyAlbum = false
                    self.present(picker, animated: true, completion: nil)
                }
            })
        case .restricted:
            print("User do not have access to photo album.")
        case .denied:
            print("User has denied the permission.")
        }
    }
    
    func permissionLocationIfDenied() {
        switch self.locationSetupResult {
        case .restricted, .denied:
            let changePrivacySetting = "SiteSnap doesn't have permission to accsess localization, please change privacy settings"
            let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access localization")
            let alertController = UIAlertController(title: "SiteSnap", message: message, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert Cancel button"),
                                                    style: .cancel,
                                                    handler: nil))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                    style: .`default`,
                                                    handler: { _ in
                                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                  options: [:],
                                                                                  completionHandler: nil)
            }))
            
            self.present(alertController, animated: true, completion: nil)
            break
        case .notDetermined:
            break
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            break
        }
    }
    
    func determineMyCurrentLocation() {
        
        locationManager = LocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        switch locationSetupResult {
        case .notDetermined:
            // Request when-in-use authorization initially
            noValidLocationIcon.isHidden = false
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
             noValidLocationIcon.isHidden = false
            // Disable location features
            break
            
        case .authorizedWhenInUse:
             noValidLocationIcon.isHidden = true
            // Enable basic location features
            break
            
        case .authorizedAlways:
             noValidLocationIcon.isHidden = true
            // Enable any of your app's location features
            break
        default:
            locationSetupResult = .denied
            
        }
        
        if LocationManager.locationServicesEnabled() {
            //locationManager.requestLocation()
            
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationSetupResult = status
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            noValidLocationIcon.isHidden = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        lastLocation = userLocation
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        manager.stopUpdatingLocation()
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        noValidLocationIcon.isHidden = false
        print("Error \(error)")
    }
    
    //MARK: - log in user
    func refresh() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userTappedLogOut = false
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async {
                self.response = task.result
                UserDefaults.standard.set(self.user?.deviceId, forKey: "deviceId")
                print("RESPONSE to refresh user")
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

//                print(self.user?.username! as Any)
//                print("\(self.pool?.getUser() as Any)")
                if (self.pool?.token().isCompleted)! {
                    UserDefaults.standard.set(self.pool?.token().result, forKey: "token")
                    print(self.pool?.token().result as Any)
                } else {
                    UserDefaults.standard.removeObject(forKey: "token")
                }
                print("USER DEFAULTS SETTED")
                
                    //self.videoAuthorization()
                    self.determineMyCurrentLocation()
                    self.libraryAuthorization()
                    self.attemptSignInToSiteSnapBackend()
            }
            return nil
        }

    }
    
    //MARK: - Observers
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) {_ , change in
            guard let isSessionRunning = change.newValue else { return }
            DispatchQueue.main.async {
                self.captureButton.isEnabled = isSessionRunning
            }
        }
        keyValueObservations.append(keyValueObservation)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.subjectAreaDidChange),
                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput.device)
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using SiteSnap, then the user can let SiteSnap resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            //var showResumeButton = false
            if reason == .videoDeviceInUseByAnotherClient {
                print("Camera is in use by another client.")
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Fade-in a label to inform the user that the camera is unavailable.
                cameraUnavailableLabel.alpha = 0
                cameraUnavailableLabel.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.cameraUnavailableLabel.alpha = 1
                }
            } else
                if reason == .videoDeviceNotAvailableDueToSystemPressure {
                print("Session stopped running due to shutdown system pressure level.")
            }
            
        }
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        
        
        if !cameraUnavailableLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraUnavailableLabel.alpha = 0
            }, completion: { _ in
                self.cameraUnavailableLabel.isHidden = true
            }
            )
        }
    }
    
    //MARK: - Selecting new project
    @IBAction func onClickSelectedProjectButton(_ sender: ActivityIndicatorButton) {
         animateProjectsList(toogle: dropDownListProjectsTableView.isHidden)
    }
    
    //MARK: - Click on UI buttons
    @IBAction func onClickMenu(_ sender: UIButton){
        //performSegue(withIdentifier: "Photo1", sender: sender)
    }
   
    @IBAction func onClickFlashButton(_ sender: FlashStateButton) {
        print(sender.currentFlashState)
        switch sender.currentFlashState {
            case "auto":
                currentFlashMode = AVCaptureDevice.FlashMode.auto
            case "on":
                currentFlashMode = AVCaptureDevice.FlashMode.on
            case "off":
                currentFlashMode = AVCaptureDevice.FlashMode.off
            default:
                currentFlashMode = AVCaptureDevice.FlashMode.auto
        }
    }
    
    @IBAction func onClickCaptureButton(_ sender: UIButton) {
        if cameraSetupResult != .success {
            return
        }
        
        if locationSetupResult != .authorizedAlways && locationSetupResult != .authorizedWhenInUse {
            permissionLocationIfDenied()
            return
        }
        if librarySetupResult != .authorized {
            permissionLibraryIfDenied()
            return
        }
        determineMyCurrentLocation()
        
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensu re UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = capturePreviewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()
            
            // Capture HEIF photos when supported. Enable current flash mode and high-resolution photos.
            if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = self.currentFlashMode
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }

            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)

        }
    }
    
    @IBAction func onClickGalerry(_ sender: UIButton) {
        checkPermissionLibrary()
    }
   
    
    //MARK: - Loading and processing PROJECTS
    func showProjectLoadingIndicator(){
        selectedProjectButton.showLoading()
    }
    
    func loadingProjectIntoList(){
        DispatchQueue.main.async {
            self.selectedProjectButton.hideLoading(buttonText: nil)
            self.galleryButton.isEnabled = true
            
            if self.noValidLocationIcon.isHidden {
                let projId = self.getCloserProject()
                self.setProjectsSelected(projectId: projId!)
            } else {
                self.setProjectsSelected(projectId: (UserDefaults.standard.value(forKey: "currentProjectId") as? String)!)
            }
            self.dropDownListProjectsTableView.reloadData()
        }
       
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellProject", for: indexPath)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = userProjects[indexPath.row].projectName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let selected = tableView.indexPathForSelectedRow
        if selected == indexPath {
            cell.contentView.backgroundColor = UIColor.black
        } else {
            cell.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == dropDownListProjectsTableView {
            let projectId = userProjects[indexPath.row].id
            UserDefaults.standard.set(projectId, forKey: "currentProjectId")
            UserDefaults.standard.set(userProjects[indexPath.row].projectName, forKey: "currentProjectName")
            //selectedProjectButton.setTitle("\(userProjects[indexPath.row].projectName)", for: .normal)
            animateProjectsList(toogle: false)
            let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
            selectedCell.contentView.backgroundColor = UIColor.black
            setProjectsSelected(projectId: projectId)
        }
    }
    
    func setProjectsSelected(projectId: String){
        for i in 0...userProjects.count-1 {
            userProjects[i].selected = userProjects[i].id == projectId
            if userProjects[i].selected {
                selectedProjectButton.setTitle(userProjects[i].projectName, for: .normal)
            }
        }
    }
    func getCloserProject() -> String! {
        let projects = ProjectHandler.fetchAllProjects()
        var closestProject = projects?.first?.id
        let firstLocation = CLLocation(latitude: (projects?.first?.latitude)!, longitude: (projects?.first?.longitude)!)
        var closestDistance = firstLocation.distance(from: lastLocation)
        for project in projects! {
            let location = CLLocation(latitude: project.latitude, longitude: project.longitude)
            
            let dist = location.distance(from: lastLocation)
            if  dist < closestDistance {
                closestDistance = dist
                closestProject = project.id
            }
        }
        return closestProject
    }
    func animateProjectsList(toogle: Bool){
        UIView.animate(withDuration: 0.3, animations: {
            self.dropDownListProjectsTableView.isHidden = !toogle
        })
    }
    
    //MARK: - Setting for CAMERA device
    private func configureSession() {
        if cameraSetupResult != .success {
            return
        }
        
        session.beginConfiguration()
//        switch UIDevice().model {
//        case "iPhone":
//            session.sessionPreset = .high
//        default:
//            session.sessionPreset = .photo
//        }
        
        
        
        // Add video input.
        do {
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
//            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
//                defaultVideoDevice = dualCameraDevice
//            } else
                if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // In the event that the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                cameraSetupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
//            if videoDevice.isFocusModeSupported(.continuousAutoFocus){
//                do{
//                    try videoDevice.lockForConfiguration()
//                    //videoDevice.focusMode = .continuousAutoFocus
//                    videoDevice.isSubjectAreaChangeMonitoringEnabled = true
//                    videoDevice.unlockForConfiguration()
//                } catch {
//                    print("Could not lock device for configuration: \(error)")
//                }
//            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.capturePreviewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            cameraSetupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            print("Could not add photo output to the session")
            cameraSetupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }

    
    
    //MARK: - Saving Taken Photo in ALBUM
    func createAlbumAndSave(image: UIImage!) {
        
        //Get PHFetch Options
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "My SiteSnap photos")
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        //Check return value - If found, then get the first album out
        if let _: AnyObject = collection.firstObject {
            self.albumFound = true
            assetCollection = collection.firstObject
        } else {
            //If not found - Then create a new album
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "My SiteSnap photos")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                self.albumFound = success
                
                if (success) {
                    let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.assetCollectionPlaceholder.localIdentifier], options: nil)
                    print(collectionFetchResult)
                    self.assetCollection = collectionFetchResult.firstObject
                }
            })
        }
       
        saveImage(image: image)
    }
    
    func saveImage(image: UIImage!){
        var localId:String?
        var createdDate: Date?
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let saveToGallery = UserDefaults.standard.value(forKey: "saveToGallery") as? Bool {
                assetRequest.isHidden = !saveToGallery
            } else {
                assetRequest.isHidden = false
            }
            assetRequest.creationDate = Date()
            if(self.lastLocation != nil){
                assetRequest.location = self.lastLocation
            }
            let assetPlaceholder = assetRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            albumChangeRequest!.addAssets([assetPlaceholder!] as NSFastEnumeration)
            localId = assetRequest.placeholderForCreatedAsset!.localIdentifier
            
            createdDate = assetRequest.creationDate
        }, completionHandler: { success, error in
            print("added image to album")
            print(error as Any)
            
           
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if (self.photosLocalIdentifierArray == nil){
        
                   self.photosLocalIdentifierArray = [localId!]
                   
                } else {
                    self.photosLocalIdentifierArray?.append(localId!)
                }
                var isVisible: Bool = true
                if let visible = UserDefaults.standard.value(forKey: "saveToGallery") as? Bool {
                    isVisible = visible
                }
                if PhotoHandler.savePhotoInMyDatabase(localIdentifier: localId!, creationDate: createdDate!, latitude: self.lastLocation.coordinate.latitude, longitude: self.lastLocation.coordinate.longitude, isHidden: !isVisible){
                    print("Photo added in core data")
                }
                PhotoHandler.setFileSize(localIdentifiers: [localId!])
                self.photoObjects = PhotoHandler.fetchAllObjects()!
                
                self.processingPopup.hideAndDestroy(from: self.view)
                self.performSegue(withIdentifier: "PhotsViewIdentifier", sender: nil)
                
            }
        })
    }
    
    //MARK: - Optional find all images in specific assetCollection
    func showImages() {
        //This will fetch all the assets in the collection
        
        let assets : PHFetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        print(assets)
        
        let imageManager = PHCachingImageManager()
        //Enumerating objects to get a chached image - This is to save loading time
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset {
                let asset = object as! PHAsset
                print(asset)
                
                let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    self.currentPhoto = image!
                    /* The image is now available to us */
                    self.addImgToArray(uploadImage: self.currentPhoto!)
                    print("enum for image, This is number 2")
                    
                })
            }
        }
    }
    
    func addImgToArray(uploadImage:UIImage)
    {
        self.projectImages.append(uploadImage)
        print(projectImages.count)
    }
    
    //MARK: - Capturing tap screen for FOCUS POINT
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        print("auto")
        focusContinuous(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    @IBAction func focusAndExposeTap(_ sender: UITapGestureRecognizer) {
        
        let devicePoint = capturePreviewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: sender.location(in: sender.view))
       
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, locationPoint: sender.location(in: sender.view), monitorSubjectAreaChange: true)
    }
    
    private func focusContinuous (with focusMode: AVCaptureDevice.FocusMode,
                                  exposureMode: AVCaptureDevice.ExposureMode,
                                  at devicePoint: CGPoint,
                                  monitorSubjectAreaChange: Bool) {
        self.sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint, locationPoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        if cameraSetupResult != .success {
            return
        }
        let rect = CGRect(x: locationPoint.x - 30 , y: locationPoint.y - 30, width: 60, height: 60)
        let dot = UIView(frame: rect)
        dot.layer.cornerRadius = 30
        dot.layer.borderColor = UIColor.white.cgColor
        dot.layer.borderWidth = 1
        
        self.capturePreviewView.addSubview(dot)
        UIView.animate(withDuration: 0.3, delay: 0.0, animations: {() -> Void in
            dot.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }, completion: {(finished: Bool) -> Void in
            dot.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor
            dot.removeFromSuperview()
            self.sessionQueue.async {
                let device = self.videoDeviceInput.device
                do {
                    try device.lockForConfiguration()
                    
                    /*
                     Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                     Call set(Focus/Exposure)Mode() to apply the new point of interest.
                     */
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                        device.focusPointOfInterest = devicePoint
                        device.focusMode = focusMode
                    }
                    
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                        device.exposurePointOfInterest = devicePoint
                        device.exposureMode = exposureMode
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        })
        
    }
  

    //MARK: - Screen White Flash on Taking Photos NOT USED ANYMORE
    func whiteFlash(){
        let screenFlash = UIView(frame: capturePreviewView.frame)
        screenFlash.backgroundColor = UIColor.white
        capturePreviewView.addSubview(screenFlash)
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseOut], animations: {() -> Void in
            screenFlash.alpha = 0
        }, completion: {(finished: Bool) -> Void in
            
            //let test = self.capturePreviewView
            screenFlash.removeFromSuperview()
        })
        
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.

       
    }
    //MARK: - delete hidden assets
    func deleteAssets(withIdentifiers identifiers: [String]) {
        let assetsToDelete : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers , options: nil)
        var validation: Bool = true
        assetsToDelete.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            //print(count)
            if object is PHAsset {
                let asset = object as! PHAsset
                validation = validation && asset.isHidden
            }
        }
        if validation {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assetsToDelete)
            })
        }
    }
    // MARK: -
}
extension CameraViewController : AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        processingPopup.createAndShow(text: "Processing...", view: view)
        whiteFlash()
    }
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil else {
            print("Error in capture process: \(String(describing: error))")
            return
        }
        let uiImage = UIImage(data: photo.fileDataRepresentation()!)
        
        
        self.createAlbumAndSave(image: uiImage)
       // processingPopup.hideAndDestroy(from: view)
        
    }
 
}
extension CameraViewController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {}
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {}
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        // do your job with selected assets
        
        for phAsset in assets {

            if(phAsset.location != nil) {
                print(phAsset.location!)
            }
            if (self.photosLocalIdentifierArray == nil){
                self.photosLocalIdentifierArray = [phAsset.localIdentifier]
            } else {
                self.photosLocalIdentifierArray?.append(phAsset.localIdentifier)
            }
            selectedFromGallery = true
            var coordinates: CLLocationCoordinate2D!
            if let photoLocationCoordinate = phAsset.location?.coordinate {
                coordinates = photoLocationCoordinate
            } else {
                if let currentProject  = ProjectHandler.getCurrentProject() {
                    coordinates = CLLocationCoordinate2D(latitude: currentProject.latitude, longitude: currentProject.longitude)
                }
            }
            
            if PhotoHandler.savePhotoInMyDatabase(localIdentifier: phAsset.localIdentifier, creationDate: phAsset.creationDate!, latitude: coordinates.latitude, longitude: coordinates.longitude, isHidden: false) {
                print("photo saved in DataCore")
                PhotoHandler.setFileSize(localIdentifiers: [phAsset.localIdentifier])
                photoObjects = PhotoHandler.fetchAllObjects()!
            }
            
        }
    }
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {}
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath) {}
}

