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


class CameraViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var orientation = "Portrait"
    var cameraHasFlash: Bool = true
    var currentFlashMode = AVCaptureDevice.FlashMode.auto
    
    var locationManager: CLLocationManager!
    var lastLocation: CLLocation!
    
    
    var assetCollection: PHAssetCollection!
    var albumFound : Bool = false
   // var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    //var photosAsset: PHFetchResult<AnyObject>!
    var currentPhoto: UIImage!
    var projectImages = [UIImage]()
    var photosLocalIdentifierArray: [String]?
    
    var processingPopup = ProcessingPopup()
    var photoObjects = [Photo]()
    var managedObjectContext: NSManagedObjectContext!
   
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var capturePreviewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var captureInnerButton: UIView!
    @IBOutlet weak var selectedProjectButton: ActivityIndicatorButton!
    
    @IBOutlet weak var dropDownListProjectsTableView: UITableView!
    
    var userProjects = [ProjectModel]()
    var projectId: Int = 0
    var selectedFromGallery: Bool = false
    
    
    //MARK: - Loading Camera View Controller
    override func viewDidLoad() {
        super.viewDidLoad()
        dropDownListProjectsTableView.isHidden = true
        setupInputOutput()
        setupPreviewLayer()
        captureSession?.startRunning()
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 5
        captureButton.backgroundColor = nil
        captureInnerButton.backgroundColor = UIColor.white
        captureInnerButton.layer.cornerRadius = 24
        captureButton.layer.cornerRadius = 35
        determineMyCurrentLocation()
        //photosLocalIdentifierArray = UserDefaults.standard.stringArray(forKey: "localIdentifiers")
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        managedObjectContext = appDelegate.persistentContainer.viewContext
        appDelegate.deleteAllPhoto()
        photoObjects = appDelegate.getAllPhotos()
        
//        for photo in photoObjects {
//            print("\(photo.localIdentifierString!) - \(String(describing: photo.createdDate!))")
//        }
        //Photos
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    print(status)
                } else {
                    print(status)
                }
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if selectedFromGallery {
            selectedFromGallery = false
            performSegue(withIdentifier: "PhotsViewIdentifier", sender: nil)
        }
    }
    
    
    //MARK: - Selecting new project
    @IBAction func onClickSelectedProjectButton(_ sender: ActivityIndicatorButton) {
         animateProjectsList(toogle: dropDownListProjectsTableView.isHidden)
    }
    
    //MARK: - Click on UI buttons
    @IBAction func onClickMenu(_ sender: UIButton){
        performSegue(withIdentifier: "Photo1", sender: sender)
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
        determineMyCurrentLocation()
    // Make sure capturePhotoOutput is valid
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        // Get an instance of AVCapturePhotoSettings class
        let photoSettings = AVCapturePhotoSettings()
        // Set photo settings for our need
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        if cameraHasFlash {
            photoSettings.flashMode = currentFlashMode
        } 
        // Call capturePhoto method by passing our photo settings and a
        // delegate implementing AVCapturePhotoCaptureDelegate
        
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    @IBAction func onClickGalerry(_ sender: UIButton) {
        //-------------
        //showImages()
        //-------------
        checkPermission()
    }
   
    
    //MARK: - Loading and processing PROJECTS
    func showProjectLoadingIndicator(){
        selectedProjectButton.showLoading()
    }
    func loadingProjectIntoList(){
        selectedProjectButton.hideLoading(buttonText: nil)
        userProjects.removeAll()
        for i in 0...3 {
            guard let project = ProjectModel(id: i+1, projectName: "Project \(i+1)") else {
                fatalError("Unable to instantiate ProductModel")
            }
            self.userProjects += [project]
        }
        self.dropDownListProjectsTableView.reloadData()
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
            projectId = userProjects[indexPath.row].id
            selectedProjectButton.setTitle("\(userProjects[indexPath.row].projectName)", for: .normal)
            animateProjectsList(toogle: false)
            let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
            selectedCell.contentView.backgroundColor = UIColor.black
            setProjectsSelected(projectId: projectId)
            //UserDefaults.standard.setValuesForKeys([Constants.LOCATION_NAME_KEY + Constants.ID_KEY: locationId])
        }
    }
    
    func setProjectsSelected(projectId: Int){
        for i in 0...userProjects.count-1 {
            userProjects[i].selected = userProjects[i].id == projectId
        }
    }
    
    func animateProjectsList(toogle: Bool){
        UIView.animate(withDuration: 0.3, animations: {
            self.dropDownListProjectsTableView.isHidden = !toogle
        })
    }
    
    //MARK: - Setting for CAMERA device
    func setupInputOutput(){
        do {
            captureSession = AVCaptureSession()
            let session = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            let cameras = (session.devices.compactMap{ $0 })
            
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    cameraHasFlash = camera.hasFlash
                    camera.unlockForConfiguration()
                    let input = try AVCaptureDeviceInput(device: camera)
                    captureSession?.addInput(input)
                }
            }
            // Get an instance of ACCapturePhotoOutput class
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            
            
            
            // Set the output on the capture session
            captureSession?.addOutput(capturePhotoOutput!)
            
           
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        settingPreviewOrientation()
        videoPreviewLayer?.frame = view.layer.bounds
        capturePreviewView.layer.addSublayer(videoPreviewLayer!)
    }
    
    func settingPreviewOrientation() {
        if orientation == "Portrait" {
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        if orientation == "Portrait UpsideDown" {
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        }
        if orientation == "Landscape Right" {
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        }
        if orientation == "Landscape Left" {
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        }
        guard let connection = capturePhotoOutput!.connection(with: AVMediaType.video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        // guard connection.isVideoMirroringSupported else { return }
        if orientation == "Portrait" {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        if orientation == "Portrait UpsideDown" {
            connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        }
        if orientation == "Landscape Right" {
            connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        }
        if orientation == "Landscape Left" {
            connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        }
    
    }
    
    //MARK: - changing PHONE ORIENTATION
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation == .portrait { //UIDevice.current.orientation == .portrait {
            captureSession?.stopRunning()
            capturePreviewView.layer.sublayers?.removeAll()
            orientation = "Portrait"
            //    setupInputOutput()
            setupPreviewLayer()
            captureSession?.startRunning()
        }
        if UIDevice.current.orientation == .portraitUpsideDown {
            captureSession?.stopRunning()
            capturePreviewView.layer.sublayers?.removeAll()
            orientation = "Portrait UpsideDown"
            // setupInputOutput()
            setupPreviewLayer()
            captureSession?.startRunning()
        }
        
        if UIDevice.current.orientation == .landscapeLeft {
            captureSession?.stopRunning()
            capturePreviewView.layer.sublayers?.removeAll()
            orientation = "Landscape Left"
            // setupInputOutput()
            setupPreviewLayer()
            captureSession?.startRunning()
        }
        if UIDevice.current.orientation == .landscapeRight {
            captureSession?.stopRunning()
            capturePreviewView.layer.sublayers?.removeAll()
            orientation = "Landscape Right"
            //   setupInputOutput()
            setupPreviewLayer()
            captureSession?.startRunning()
        }
    }
    
    //MARK: - Permission for viewing and saving photos in Custom Album
    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
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
            if (self.photosLocalIdentifierArray == nil){
                self.photosLocalIdentifierArray = [localId!]
            } else {
                self.photosLocalIdentifierArray?.append(localId!)
            }
            
            print(self.photosLocalIdentifierArray as Any)
            let newPhoto = Photo(context: self.managedObjectContext!)
            newPhoto.localIdentifierString = localId!
            newPhoto.createdDate = createdDate as NSDate?
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            self.photoObjects = appDelegate.getAllPhotos()
            DispatchQueue.main.async {
                self.processingPopup.hideAndDestroy(from: self.view)
                self.performSegue(withIdentifier: "PhotsViewIdentifier", sender: nil)
                
            }
            //self.showImages()
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
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        animateCircle(point: touch!.location(in: self.view))
        
        
        print("Began.x = \(touch!.location(in: self.view).x)")
        print("Began.y = \(touch!.location(in: self.view).y)")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }
    
    func animateCircle(point: CGPoint){
        guard let device = self.rearCamera else {
            return
        }
        let rect = CGRect(x: point.x - 30 , y: point.y - 30, width: 60, height: 60)
        let dot = UIView(frame: rect)
        dot.layer.cornerRadius = 30
        dot.layer.borderColor = UIColor.white.cgColor
        dot.layer.borderWidth = 1
        self.capturePreviewView.addSubview(dot)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, animations: {() -> Void in
            dot.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }, completion: {(finished: Bool) -> Void in
            dot.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor
            let focusPoint: CGPoint = CGPoint(x: point.y / UIScreen.main.bounds.height, y: 1.0 - point.x / UIScreen.main.bounds.width)
            do {
                if(device.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus)){
                    try device.lockForConfiguration()
                    device.focusPointOfInterest = focusPoint
                    device.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    device.unlockForConfiguration()
                    dot.removeFromSuperview()
                }
            } catch {
                print(error)
            }
           // dot.removeFromSuperview()
        })
    }

    //MARK: - Screen White Flash on Taking Photos
    func whiteFlash(){
        let screenFlash = UIView(frame: capturePreviewView.frame)
        screenFlash.backgroundColor = UIColor.white
        capturePreviewView.addSubview(screenFlash)
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseOut], animations: {() -> Void in
            screenFlash.alpha = 0
        }, completion: {(finished: Bool) -> Void in
            screenFlash.removeFromSuperview()
        })
        
    }

    //MARK: - getting current LOCATION - function delegate
    func determineMyCurrentLocation() {
    
        locationManager = LocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if LocationManager.locationServicesEnabled() {
            //locationManager.requestLocation()
            
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
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
//        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        print(documentsURL)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
//        if  segue.identifier == "PhotsViewIdentifier",
//            let destination = segue.destination as? PhotosViewController {
//            destination.photosLocalIdentifiers = self.photosLocalIdentifierArray
//            
//        }
       
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
        let uiImage = UIImage(data: photo.fileDataRepresentation()!)
        
        self.createAlbumAndSave(image: uiImage)
       // processingPopup.hideAndDestroy(from: view)
        guard error == nil else {
            print("Error in capture process: \(String(describing: error))")
            return
        }
    }
 
}
extension CameraViewController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {}
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {}
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        // do your job with selected assets
        
        for phAsset in assets {
            
//            print(phAsset.localIdentifier)
//            print(phAsset.creationDate!)
            if(phAsset.location != nil) {
                print(phAsset.location!)
            }
            if (self.photosLocalIdentifierArray == nil){
                self.photosLocalIdentifierArray = [phAsset.localIdentifier]
            } else {
                self.photosLocalIdentifierArray?.append(phAsset.localIdentifier)
            }
            print(self.photosLocalIdentifierArray as Any)
            selectedFromGallery = true
            let newPhoto = Photo(context: self.managedObjectContext!)
            newPhoto.localIdentifierString = phAsset.localIdentifier
            newPhoto.createdDate = phAsset.creationDate as NSDate?
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            photoObjects = appDelegate.getAllPhotos()
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
