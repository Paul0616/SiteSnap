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



class CameraViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, BackendConnectionDelegate, NewProjectViewControllerDelegate {
    
    private let groupName = "group.com.au.tridenttechnologies.sitesnapapp"
    private let userDefaultsKey = "incomingLocalIdentifiers"
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
    var isUserLogged: Bool = false
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var capturePreviewView: PreviewView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var captureInnerButton: UIView!
    @IBOutlet weak var selectedProjectButton: ActivityIndicatorButton!

    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var gpsStatusImageView: UIImageView!
    @IBOutlet weak var cameraUnavailableLabel: UILabel!
    @IBOutlet weak var dropDownListProjectsTableView: UITableView!
    
    var userProjects = [ProjectModel]()
    var selectedFromGallery: Bool = false
    var timerAuthenticationCognito: Timer!
    var timerBackend: Timer!
    //  var locationWasUpdated: Bool = false
    var projectWasSelected: Bool = false
    var galleryWillBeOpen: Bool = false
    
    
    
    
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
        
        gpsStatusImageView.image = GPSStatus.no_gps.image
        //delete unused files from document directory
        deleteAssets(unused: true)
        
        if photoDatabaseShouldBeDeleted {
            for tag in TagHandler.fetchObjects()! {
                tag.photos = nil
            }
            //delete uploaded files from photo database
            if let uploadedPhotoIds = PhotoHandler.getUploadedPhotosForDelelete() {
                if PhotoHandler.photosDeleteBatch(identifiers: uploadedPhotoIds) {
                    print("all uploaded photos was deleted from Core Data")
                }
            }
            userProjects.removeAll()
            photoDatabaseShouldBeDeleted = false
        }
        print("there ARE \(photoObjects.count) photos")
        
        self.showProjectLoadingIndicator()
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
        
       startCameraViewController()
    }
    
    
    
    fileprivate func startCameraViewController() {
        //initially user do not have project choosed
        projectWasSelected = false
        UserDefaults.standard.set(projectWasSelected, forKey: "projectWasSelected")
        
        loadingProjectIntoList()
        checkLocationAuthorization()
        libraryAuthorization()
        
        timerAuthenticationCognito = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.callBackendConnection()
        }
        
        videoAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let prjWasSelected = UserDefaults.standard.value(forKey: "projectWasSelected") as? Bool {
            projectWasSelected = prjWasSelected
        }
        
        photoObjects = PhotoHandler.fetchAllObjects()!
        if !galleryWillBeOpen  {
            if timerBackend == nil || !timerBackend.isValid {
                timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
                print("TIMER STARTED - camera")
            }
        }
        checkDatabasePhotoIsStillInGallery()
        
        if let prjId = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            print(prjId)
            self.setProjectsSelected(projectId: prjId)
        }
        //        if isUserLogged{
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
        //        }
        
//        if LocationManager.locationServicesEnabled() && !LocationManager.shared.isUpdatingLocation {
//            locationManager.startUpdatingLocation()
//        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.cameraSetupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
//        locationManager.stopUpdatingLocation();
        
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(" gallery \(galleryWillBeOpen)")
        print("shared \(wasCalledFromSharedExtension())")
        if !galleryWillBeOpen {
            if timerBackend != nil {
                timerBackend.invalidate()
            }
            print("TIMER INVALID - camera 1")
        }
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
    
    //MARK: - SHARE EXTENSION CHECK
    func wasCalledFromSharedExtension() -> Bool {
        let sharedExtension = (UserDefaults(suiteName: groupName)?.value(forKey: userDefaultsKey) as? [String]) != nil
        return sharedExtension
    }
    
    func openSharedExtensionView(){
        performSegue(withIdentifier: "ShareImagesViewIdentifier", sender: nil)
    }
    
    //MARK: - New Project DELEGATE
    func newProjectAddedCallback(projectModel: ProjectModel?) {
        if timerBackend == nil || !timerBackend.isValid {
            timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
            timerBackend.fire()
            print("TIMER STARTED - camera")
        }
    }
    
    //MARK: - The called function for the timer
    @objc func callBackendConnection(){
        let backendConnection = BackendConnection(projectWasSelected: projectWasSelected, lastLocation: lastLocation)
        backendConnection.delegate = self
        backendConnection.attemptSignInToSiteSnapBackend()
    }
    
    //MARK: - Connect to SITESnap function DELEGATE
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
    
    func treatErrors(_ error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            if let err = error as? URLError {
                var message: String?
                switch err.code {
                case .notConnectedToInternet:
                    message = "Not Connected To The Internet"
                case .timedOut:
                    message = "Request Timed Out"
                case .networkConnectionLost:
                    message = "Lost Connection to the Network"
                default:
                    print("Default Error")
                    message = "Error"
                    print(err)
                }
                
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(
                        title: "SiteSnap server access",
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
    }
    
    func noProjectAssigned() {
        timerBackend.invalidate()
        print("TIMER INVALID - camera 2")
    
        DispatchQueue.main.async {
            
            self.selectedProjectButton.hideLoading(buttonText: nil)
            if let _: UIAlertController = self.presentedViewController as? UIAlertController{
                print("alert is on screen")
                self.dismiss(animated: true, completion: {
                    self.performSegue(withIdentifier: "NoProjectsAssigned", sender: nil)
                })
            } else {
                self.performSegue(withIdentifier: "NoProjectsAssigned", sender: nil)
            }
        }
    }
    
    func userNeedToCreateFirstProject() {
        timerBackend.invalidate()
        print("TIMER INVALID - camera 3")
    
        DispatchQueue.main.async {
            //self.selectedProjectButton.hideLoading(buttonText: nil)
            if let _: UIAlertController = self.presentedViewController as? UIAlertController{
                print("alert is on screen")
                self.dismiss(animated: true, completion: {
                    self.performSegue(withIdentifier: "createNewProjectIdentifier", sender: nil)
                })
            } else {
                self.performSegue(withIdentifier: "createNewProjectIdentifier", sender: nil)
            }
        }
    }
    
    func databaseUpdateFinished() {
        if wasCalledFromSharedExtension() {
            openSharedExtensionView()
        }
        loadingProjectIntoList()
        
    }
    
    
    
    //MARK: - Check still in gallery
    func checkDatabasePhotoIsStillInGallery(){
        //-----------------------  check if photos from CoreData is still in gallery and if not detele them from CoreData
        //photoObjects = PhotoHandler.fetchAllObjects()!
        for photo in photoObjects {
            let photoId = photo.localIdentifierString
            if !photo.isHidden {
                let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoId!] , options: nil)
                if assets.count == 0 {
                    if PhotoHandler.photosDeleteBatch(identifiers: [photoId!]) {
                        print("Photo with is: \(String(describing: photoId)) was deleted")
                    }
                }
            }
        }
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
        case .limited:
            break
        @unknown default:
            print("unknown")
        }
    }
    
    func checkPermissionLibrary() {
        switch librarySetupResult {
        case .authorized:
            print("Access was already granted.")
            let picker = AssetsPickerViewController()
            picker.modalPresentationStyle = .fullScreen
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
        case .limited:
            break
        @unknown default:
            print("unknown")
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
        @unknown default:
            print("unknown")
        }
    }
    
    func checkLocationAuthorization() {
        locationManager = LocationManager.shared
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 35.0
        locationManager.delegate = self
        switch locationSetupResult {
        case .notDetermined:
            // Request when-in-use authorization initially
            //noValidLocationIcon.isHidden = false
            gpsStatusImageView.image = GPSStatus.no_gps.image
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            //noValidLocationIcon.isHidden = false
            gpsStatusImageView.image = GPSStatus.no_gps.image
            // Disable location features
            break
            
        case .authorizedWhenInUse:
            //noValidLocationIcon.isHidden = true
            gpsStatusImageView.image = GPSStatus.gps_no_updating.image
            // Enable basic location features
            break
            
        case .authorizedAlways:
            //noValidLocationIcon.isHidden = true
            gpsStatusImageView.image = GPSStatus.gps_no_updating.image
            // Enable any of your app's location features
            break
        default:
            locationSetupResult = .denied
        }
        
        if LocationManager.locationServicesEnabled() && !LocationManager.shared.isUpdatingLocation {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationSetupResult = status
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            //noValidLocationIcon.isHidden = true
            gpsStatusImageView.image = GPSStatus.gps_no_updating.image
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        lastLocation = userLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        
        
        //manager.stopUpdatingLocation()
        gpsStatusImageView.image = GPSStatus.gps_updating.image
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.gpsStatusImageView.image = GPSStatus.gps_no_updating.image
        })
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        //noValidLocationIcon.isHidden = false
        gpsStatusImageView.image = GPSStatus.no_gps.image
        print("Error on getting location \(error)")
    }
    
    //MARK: - log in user
    @objc func refresh() {
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
                    self.timerAuthenticationCognito.invalidate()
                } else {
                    UserDefaults.standard.removeObject(forKey: "token")
                }
                print("USER DEFAULTS SETTED")
                
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
            if reason == .videoDeviceNotAvailableInBackground {
                print("Capture session was interrupted with reason: 'An interruption caused by the app being sent to the background while using a camera.'")
            } else {
                print("Capture session was interrupted with reason \(reason)")
            }
            
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
       // animateProjectsList(toogle: dropDownListProjectsTableView.isHidden)
        
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
        // determineMyCurrentLocation()
        
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
            if  self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
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
        galleryWillBeOpen = true
        checkPermissionLibrary()
        
    }
    
    
    //MARK: - Loading and processing PROJECTS
    func showProjectLoadingIndicator(){
        selectedProjectButton.showLoading()
    }
    
    func loadingProjectIntoList(){
        // DispatchQueue.main.async {
        if !dropDownListProjectsTableView.isHidden {
            return
        }
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
        guard let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String else {
            return
        }
        selectedProjectButton.hideLoading(buttonText: nil)
        galleryButton.isEnabled = true
        
        setProjectsSelected(projectId: currentProjectId)
        dropDownListProjectsTableView.reloadData()
        // }
        
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
            projectWasSelected = true
            UserDefaults.standard.set(projectWasSelected, forKey: "projectWasSelected")
        }
    }
    
    func setProjectsSelected(projectId: String){
        if userProjects.count == 0 {
            return
        }
        for i in 0...userProjects.count-1 {
            //userProjects[i].selected = userProjects[i].id == projectId
            if userProjects[i].id == projectId {
                selectedProjectButton.setTitle(userProjects[i].projectName, for: .normal)
            }
        }
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
                    let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
                   // print(interfaceOrientation?.rawValue)
                   // let statusBarOrientation = UIApplication.shared.statusBarOrientation
                  //  print(statusBarOrientation.rawValue)
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if interfaceOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(rawValue: interfaceOrientation!.rawValue) {
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
                self.timerBackend.invalidate()
                print("TIMER INVALID - camera 4")
                self.performSegue(withIdentifier: "PhotsViewIdentifier", sender: nil)
                
            }
        })
    }
    func saveDocumentImageToDatabase(fileName: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let now: Date = Date()
            if PhotoHandler.savePhotoInMyDatabase(localIdentifier: fileName, creationDate: now, latitude: self.lastLocation.coordinate.latitude, longitude: self.lastLocation.coordinate.longitude, isHidden: true){
                print("Photo added in core data")
            }
            
            let imagePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0].appending("/\(fileName)")
            var fileSize : Int64 = 0
            
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: imagePath)
                fileSize = attr[FileAttributeKey.size] as! Int64
                
                //if you convert to NSDictionary, you can get file size old way as well.
                //            let dict = attr as NSDictionary
                //            fileSize = dict.fileSize()
            } catch {
                print("Error to save image in database: \(error)")
            }
            // let size: Int64 = image.fileSize(image: fileName)
            //PhotoHandler.setFileSize(localIdentifiers: [localId!])
            PhotoHandler.updateFileSize(localIdentifier: fileName, size: fileSize)
            self.photoObjects = PhotoHandler.fetchAllObjects()!
            
            self.processingPopup.hideAndDestroy(from: self.view)
            self.performSegue(withIdentifier: "PhotsViewIdentifier", sender: nil)
            
        }
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
        if  segue.identifier == "PhotsViewIdentifier",
            let destination = segue.destination as? PhotosViewController {
            destination.lastLocation = lastLocation
            
        }
        if segue.identifier == "projectsListSegue", let destination = segue.destination as? ProjectsListViewController {
            destination.delegate = self
        }
        
        if segue.identifier == "createNewProjectIdentifier", let destination = segue.destination as? NewProjectViewController {
            destination.delegate = self
            destination.isFirstProject = true
        }
       
        
    }
    //MARK: - delete hidden assets
    func deleteAssets(unused: Bool) {
        do {
            let directoryPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let files: [String] = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
            let hiddenAndUploadedPhotos:[String] = PhotoHandler.getHiddenAndUploadedPhotosForDelelete()
            for fileName in files {
                let hiddenIdentifier = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: [fileName])
                if unused {
                    if hiddenIdentifier.count == 0 {
                        try FileManager.default.removeItem(atPath: directoryPath.appending("/\(fileName)"))
                    }
                } else {
                    if hiddenAndUploadedPhotos.contains(fileName) {
                        try FileManager.default.removeItem(atPath: directoryPath.appending("/\(fileName)"))
                    }
                }
            }
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
}

extension CameraViewController: ProjectListViewControllerDelegate {
    func projectWasSelectedFromOutside(projectId: String) {
        UserDefaults.standard.set(projectId, forKey: "currentProjectId")
        if let project = ProjectHandler.getCurrentProject() {
            UserDefaults.standard.set(project.name, forKey: "currentProjectName")
            animateProjectsList(toogle: false)
            setProjectsSelected(projectId: projectId)
            projectWasSelected = true
            UserDefaults.standard.set(projectWasSelected, forKey: "projectWasSelected")
        }
    }
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
        
        if let saveToGallery = UserDefaults.standard.value(forKey: "saveToGallery") as? Bool {
            if saveToGallery {
                self.createAlbumAndSave(image: uiImage)
            } else {
                let fileName = UUID().uuidString + ".jpg"
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                // Get the Document directory path
                let documentDirectorPath:String = paths[0].appending("/\(fileName)")
                let data = uiImage?.jpegData(compressionQuality: 1.0)
                if FileManager.default.createFile(atPath: documentDirectorPath, contents: data, attributes: nil) {
                    print("saved in documents was successfully")
                    saveDocumentImageToDatabase(fileName: fileName)
                }
            }
        } else {
            self.createAlbumAndSave(image: uiImage)
        }
        
        // processingPopup.hideAndDestroy(from: view)
        
    }
    
}
extension CameraViewController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {}
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {}
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        // do your job with selected assets
        galleryWillBeOpen = false
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

extension UIViewController {
    func isVisible() -> Bool {
        return self.isViewLoaded && self.view.window != nil
    }
}
