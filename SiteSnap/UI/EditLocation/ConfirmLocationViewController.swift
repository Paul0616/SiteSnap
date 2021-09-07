//
//  ConfirmLocationViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 02/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Photos


class ConfirmLocationViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, BackendConnectionDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var confirmPhotoLocationButton: UIButton!
    @IBOutlet weak var cancelEditButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var slideContainer: Slider!
    @IBOutlet weak var editAllLocationButton: UIButton!
    @IBOutlet weak var editLocationButton: UIButton!
    @IBOutlet weak var gpsIcon: UIButton!
    
    var photos: [Photo]!
    var slideArray = [Slide]()
    var clustersPhotos = [[Photo]]()
    var locationManager: CLLocationManager!
    var lastLocation: CLLocation!
    var annotationsArray: [PhotoAnnotation] = []
    var firstTime: Bool = true
    var hiddenCurrentLocation: Bool = false
    var annotationIsMultiple: Bool = false
    var preventShowSlider: Bool = false
    var pointForCurrentAnnotation: CGPoint!
    var currentClusterAnnotation: PhotoAnnotation!
    var selectedPhotoIdentifier: String!
    var dummy: Annotation_V2!
    private var scaleKvoToken:NSKeyValueObservation?
    var doubleTapGesture: UITapGestureRecognizer!
    var isPortrait: Bool?
    
    var timerBackend: Timer!
    var projectWasSelected: Bool = false
    var oldProjectSelectedId: String!
    private var _isEditingLocation: Bool = false
    private var _isEditingLocationForAllSelectedGroup: Bool?
    private var sizeForLess700ScreenHeight: CGSize = CGSize(width: 83 * 0.8, height: 100 * 0.8)
    private var sizeForMore700ScreenHeight: CGSize = CGSize(width: 100 * 0.8, height: 120 * 0.8)
    
    var isEditingLocation: Bool {
        get {
            return self._isEditingLocation
        }
        set {
            _isEditingLocation = newValue
            if _isEditingLocation {
                uploadButton.setTitle("   SET PHOTO\n   LOCATION", for: .normal)
                uploadButton.setImage(UIImage(named: "gps_fixed"), for: .normal)
            } else {
                uploadButton.setTitle("   UPLOAD", for: .normal)
                uploadButton.setImage(UIImage(named: "cloud_upload"), for: .normal)
            }
        }
    }
    
    //MARK: -
    override func viewDidLoad() {
       
        super.viewDidLoad()
        map.showsCompass = false
        backButton.layer.cornerRadius = 20
        confirmPhotoLocationButton.layer.cornerRadius = 6
        confirmPhotoLocationButton.isEnabled = false
        isEditingLocation = false
        _isEditingLocationForAllSelectedGroup = nil
        cancelEditButton.layer.cornerRadius = 20
        cancelEditButton.isHidden = true
        gpsIcon.isHidden = false
        confirmPhotoLocationButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        confirmPhotoLocationButton.setTitle("Tap a pin to edit\nphoto location", for: .normal)
        confirmPhotoLocationButton.titleLabel?.textAlignment = .center
        uploadButton.layer.cornerRadius = 6
        
        // Do any additional setup after loading the view.
        photos = PhotoHandler.fetchAllObjects(excludeUploaded: true)
        self.map.delegate = self
        determineMyCurrentLocation()
        setPhotoClusters()
        map.mapType = .hybrid
        createAnnotations(setFitVisibleAllAnnotations: true)
        doubleTapGesture = UITapGestureRecognizer(target: self, action: nil)//#selector(mapDoubleTapSelector(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        doubleTapGesture.delegate = self
        map.addGestureRecognizer(doubleTapGesture)
        if let currentPrj = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            oldProjectSelectedId = currentPrj
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let _photos = PhotoHandler.fetchAllObjects(excludeUploaded: true)
        if _photos?.count == 0 {
            dismiss(animated: true, completion: nil)
        }
        if _photos?.count != photos.count {
            photos = _photos
            setPhotoClusters()
            createAnnotations(setFitVisibleAllAnnotations: false)
        }
        if let prjWasSelected = UserDefaults.standard.value(forKey: "projectWasSelected") as? Bool {
            projectWasSelected = prjWasSelected
        }
        if timerBackend == nil || !timerBackend.isValid {
            timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
            print("TIMER STARTED - map")
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timerBackend.invalidate()
        print("TIMER INVALID - map")
    }
    override func viewDidLayoutSubviews() {
        if firstTime {
            for view in view.subviews {
                if view is Slider {
                    slideContainer = view as? Slider
                }
            }
            var identifiers = [String]()
            for photo in photos! {
                identifiers.append(photo.localIdentifierString!)
            }
            firstTime = false
            slideContainer.loadImages(identifiers: identifiers)
            sliderVisibility(hidden: true)
            slideArray =  slideContainer.slides
        }
        if self.view.safeAreaLayoutGuide.layoutFrame.size.width > self.view.safeAreaLayoutGuide.layoutFrame.size.height {
            print("landscape")
            isPortrait = false
            
        } else {
            print("portrait")
            isPortrait = true
           
        }
    }
    
    
    //MARK: -
    @IBAction func onBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func onClickCurrentLocation(_ sender: UIButton) {
        preventShowSlider = true
        guard let location = lastLocation else {
            return
        }
        map.setCenter(location.coordinate, animated: true)
    }
    
    @IBAction func onClickChangeMapType(_ sender: UIButton) {
        switch map.mapType {
        case .standard:
            map.mapType = .hybrid
        case .hybrid:
            map.mapType = .standard
        default:
            map.mapType = .standard
        }
    }
    @IBAction func onTapUpload(_ sender: Any) {
        if isEditingLocation {
            print("LOCATION EDITING - NO UPLOAD")
            onTapSetPhotoLocation(uploadButton)
        } else {
            if let _ = UserDefaults.standard.value(forKey: "currentProjectName") as? String,
               let _ = UserDefaults.standard.value(forKey: "currentProjectId") as? String{
                performSegue(withIdentifier: "uploadSegue", sender: nil)
            }
        }
    }
    
    @IBAction func onTapEditLocation(_ sender: UIButton) {
        isEditingLocation = true
        _isEditingLocationForAllSelectedGroup = false
        //confirmPhotoLocationButton.isEnabled = true
        //confirmPhotoLocationButton.backgroundColor = UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0) //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
        confirmPhotoLocationButton.setTitle("Drag the map to edit\nphoto location", for: .normal)
        cancelEditButton.isHidden = false
        gpsIcon.setImage(UIImage(named: "gps_not_fixed"), for: .normal)
        gpsIcon.isHidden = false
        //uploadButton.isHidden = true
        backButton.isHidden = true
        //createAnnotations(isAfterEditLocation: true)
       
        for annotation in annotationsArray {
            if let annotationView = map.view(for: annotation) as? PhotoAnnotationView {
                if(annotation.subtitle == currentClusterAnnotation.subtitle) {
                    if let noOfPhotos = currentClusterAnnotation.numberOfPhotos,
                       noOfPhotos > 1 {
                        //annotation.numberOfPhotos! -= 1
                        let no:Int = (annotation.numberOfPhotos ?? 0) - 1
                        annotationView.alpha = 0.5
                        annotationView.customView.numberOfPhotos.text = String(no)
                    } else {
                        annotationView.isHidden = true
                    }
                } else {
                    annotationView.alpha = 0.5
                }
            }
        }
        
        sliderVisibility(hidden: true)
        dummy = Bundle.main.loadNibNamed("Annotation_v2", owner: self, options: nil)?.first as? Annotation_V2
        if UIScreen.main.bounds.height < 700 {
            dummy!.frame = CGRect(x: pointForCurrentAnnotation.x, y: pointForCurrentAnnotation.y, width: sizeForLess700ScreenHeight.width, height: sizeForLess700ScreenHeight.height)
            dummy.pinCircle.layer.cornerRadius = CGFloat(sizeForLess700ScreenHeight.width * 0.3)
        } else {
            dummy!.frame = CGRect(x: pointForCurrentAnnotation.x, y: pointForCurrentAnnotation.y, width: sizeForMore700ScreenHeight.width, height: sizeForMore700ScreenHeight.height)
            dummy.pinCircle.layer.cornerRadius = CGFloat(sizeForMore700ScreenHeight.width * 0.3)
        }
    
        //dummy.numberOfPhotos.isHidden = true
    
        selectedPhotoIdentifier = slideContainer.slides[slideContainer.photosControl.currentPage].localIdentifier
        //dummy.photoImage.image = slideContainer.slides[slideContainer.photosControl.currentPage].mainImage.image
//        for annotation in annotationsArray {
//            if annotation.subtitle == currentClusterAnnotation.subtitle {
//                dummy.numberOfPhotos.text = "1" //String(annotation.numberOfPhotos!)
//            }
//        }
        dummy.numberOfPhotos.text = "1"
        map.addSubview(dummy!)
    }
    
    @IBAction func onTapEditAllClusterLocation(_ sender: UIButton) {
        isEditingLocation = true
        _isEditingLocationForAllSelectedGroup = true
        //confirmPhotoLocationButton.isEnabled = true
        //confirmPhotoLocationButton.backgroundColor = UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0) //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
        confirmPhotoLocationButton.setTitle("Drag the map to edit\nphoto location", for: .normal)
        cancelEditButton.isHidden = false
        gpsIcon.setImage(UIImage(named: "gps_not_fixed"), for: .normal)
        gpsIcon.isHidden = false
        //uploadButton.isHidden = true
        backButton.isHidden = true
        //editLocationMode = true
        
        for annotation in annotationsArray {
            if(annotation.subtitle == currentClusterAnnotation.subtitle) {
                map.view(for: annotation)?.isHidden = true
            } else {
                map.view(for: annotation)?.alpha = 0.5
            }
        }
        sliderVisibility(hidden: true)
        dummy = Bundle.main.loadNibNamed("Annotation_v2", owner: self, options: nil)?.first as? Annotation_V2
        if UIScreen.main.bounds.height < 700 {
            dummy!.frame = CGRect(x: pointForCurrentAnnotation.x, y: pointForCurrentAnnotation.y, width: sizeForLess700ScreenHeight.width, height: sizeForLess700ScreenHeight.height)
            dummy.pinCircle.layer.cornerRadius = CGFloat(sizeForLess700ScreenHeight.width * 0.3)
        } else {
            dummy!.frame = CGRect(x: pointForCurrentAnnotation.x, y: pointForCurrentAnnotation.y, width: sizeForMore700ScreenHeight.width, height: sizeForMore700ScreenHeight.height)
            dummy.pinCircle.layer.cornerRadius = CGFloat(sizeForMore700ScreenHeight.width * 0.3)
        }
        
        //dummy.numberOfPhotos.isHidden = true
        selectedPhotoIdentifier = nil
        //dummy.photoImage.isHidden = true
        //dummy.numberOfPhotos.isHidden = false
        for annotation in annotationsArray {
            if annotation.subtitle == currentClusterAnnotation.subtitle {
                dummy.numberOfPhotos.text = String(annotation.numberOfPhotos!)
            }
        }
        map.addSubview(dummy!)
    }
    
    @IBAction func onTapCancelEditButton(_ sender: UIButton) {

        for annotation in annotationsArray {
            if let annotationView = map.view(for: annotation) as? PhotoAnnotationView {
                if let noOfPhotos = currentClusterAnnotation.numberOfPhotos,
                   noOfPhotos > 1,
                   annotation.subtitle == currentClusterAnnotation.subtitle {
                    annotationView.customView.numberOfPhotos.text = String(annotation.numberOfPhotos ?? 0)
                }
                annotationView.isHidden = false
                annotationView.alpha = 1
                map.deselectAnnotation(annotation, animated: false)
            }
        }
       cancelUI()
    }
    
    //MARK: - The called function for the timer
    @objc func callBackendConnection(){
        let backendConnection = BackendConnection.shared
        backendConnection.delegate = self
        backendConnection.attemptSignInToSiteSnapBackend(projectWasSelected: projectWasSelected, lastLocation: lastLocation)
    }
    func treatErrors(_ error: Error?) {
        print(error!)
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
    
    fileprivate func refreshAnnotations() {
        photos.removeAll()
        slideContainer.isHidden = true
        photos = PhotoHandler.fetchAllObjects(excludeUploaded: true)
        setPhotoClusters()
        createAnnotations(setFitVisibleAllAnnotations: false)
        cancelUI()
    }
    
    @IBAction func onTapSetPhotoLocation(_ sender: UIButton) {
        print("SET PHOTO LOCATION - ALL PHOTO = \(String(describing: _isEditingLocationForAllSelectedGroup))")
        var locationCoordinate = map.centerCoordinate
//        let pinCoordinate = view.annotation?.coordinate
//        let currentCoordinates = mapView.centerCoordinate
//        mapView.centerCoordinate = pinCoordinate!
//        let viewCenter = self.view.center
//        let fakeCenter = CGPoint(x: viewCenter.x, y: viewCenter.y - 100)
//        let coordinate = mapView.convert(fakeCenter, toCoordinateFrom: self.view)
//        mapView.centerCoordinate = currentCoordinates
        if let isPortrait = isPortrait, !isPortrait {
            let frame = map.frame
            let center = CGPoint(x: frame.midX, y: frame.midY)
           // map.centerCoordinate = center
            let h: CGFloat = 120 //annotaion height
            let fakeCenter = CGPoint(x: center.x, y: center.y + (h / 2) + 7 + 8)
            locationCoordinate = map.convert(fakeCenter, toCoordinateFrom: map)
        }
        var identifiers = [String]()
        if selectedPhotoIdentifier == nil {
            for cluster in clustersPhotos {
                for item in cluster {
                    if item.localIdentifierString == currentClusterAnnotation.subtitle {
                        for item1 in cluster {
                            identifiers.append(item1.localIdentifierString!)
                        }
                        break
                    }
                }
            }
        } else {
            identifiers.append(selectedPhotoIdentifier)
        }
        /*
         ================
         IF current editing location pin is from multiple annotation
         and edit single photo was tapped
         ================
         */
        if _isEditingLocationForAllSelectedGroup == false && annotationIsMultiple {
            if let photo = PhotoHandler.getSpecificPhoto(localIdentifier: identifiers[0]){
                let first = CLLocation(latitude: photo.latitude, longitude: photo.longitude)
                let second =  CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
                let dist = first.distance(from: second)
                if dist <= 50 {
                    refreshAnnotations()
                } else if PhotoHandler.updateLocations(localIdentifiers: identifiers, location: locationCoordinate) {
                    refreshAnnotations()
                }
            }
        } else if PhotoHandler.updateLocations(localIdentifiers: identifiers, location: locationCoordinate) {
            refreshAnnotations()
        }
    }
    
    func noProjectAssigned() {
        timerBackend.invalidate()
        print("TIMER INVALID - tags")
        performSegue(withIdentifier: "NoProjectsAssigned", sender: nil)
    }
    
    func userNeedToCreateFirstProject() {
        
    }
    
    func databaseUpdateFinished() {
        if let currentPrj = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            if oldProjectSelectedId != currentPrj {
                let alertController = UIAlertController(title: "Project no longer available",
                                                        message: "You no longer have access to the project \(String(describing: oldProjectSelectedId)), either because you have been removed from it or the project has been removed by an administrator.\r\n\r\nYou will be returned to the Photo Data Screen. Please confirm this is the correct project you wish to upload the photo(s) to before continuing.",
                    preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.dismiss(animated: true, completion: nil)
                })
                )
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }


    
    //MARK: - private methods
    private func cancelUI(){
        //confirmPhotoLocationButton.isEnabled = false
        //confirmPhotoLocationButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        confirmPhotoLocationButton.setTitle("Tap a pin to edit\nphoto location", for: .normal)
        cancelEditButton.isHidden = true
        gpsIcon.setImage(UIImage(named: "gps_fixed"), for: .normal)
        //uploadButton.isHidden = false
        backButton.isHidden = false
        isEditingLocation = false
        _isEditingLocationForAllSelectedGroup = nil
       // dummy.photoImage.image = nil
        dummy.removeFromSuperview()
    }
    
    private func createAnnotations(setFitVisibleAllAnnotations: Bool){
        if map.annotations.count > 0 {
            map.removeAnnotations(map.annotations)
           // map.removeOverlays(map.overlays)
        }
        annotationsArray.removeAll()
        for cluster in clustersPhotos {
            var annotation: PhotoAnnotation!
            let loc: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (cluster.first?.latitude)!, longitude: (cluster.first?.longitude)!)
//            var image: UIImage! = nil
            
//            if cluster.count == 1 {
//                image = loadImage(identifier: cluster.first?.localIdentifierString)
//            }
            
            annotation =  PhotoAnnotation(coordinate: loc, title: "Image local identifier:", subtitle: (cluster.first?.localIdentifierString)!, isCluster: cluster.count > 1, numberOfPhotos: cluster.count, photoImage: nil) //photoImage: image)
            annotationsArray.append(annotation)
        }
        map.addAnnotations(annotationsArray)
        if setFitVisibleAllAnnotations {
            map.showAnnotations(annotationsArray, animated: true)

        }
        
    
    }
    
    
    private func setPhotoClusters(){
       
        clustersPhotos.removeAll()

        
        var uncheckedPhotos: [Photo]! = photos
        var restPhotos: [Photo]! = photos
        
        for photo in photos!{
            var cluster = [Photo]()
            if !restPhotos.contains(photo) {
                continue
            }
            restPhotos!.removeFirst()
            uncheckedPhotos = restPhotos
            cluster.append(photo)
            
            for element in uncheckedPhotos! {
                if isLocationsNearby(firstLocation: photo, secondLocation: element) {
                    cluster.append(element)
                    var k: Int = 0
                    for restPhoto in restPhotos {
                        if element.localIdentifierString == restPhoto.localIdentifierString {
                            restPhotos.remove(at: k)
                            break
                        }
                        k = k + 1
                    }
                }
            }
            clustersPhotos.append(cluster)
        }
    }
    
    //MARK: - show/hide slider
    private func sliderVisibility(hidden: Bool) {
        
        slideContainer.isHidden = hidden
        editLocationButton.isHidden = hidden
        if !hidden {
            editAllLocationButton.isHidden = !annotationIsMultiple
            confirmPhotoLocationButton.setTitle("Move single photos\nor a group", for: .normal)
        } else {
            editAllLocationButton.isHidden = hidden
            if isEditingLocation {
                confirmPhotoLocationButton.setTitle("Drag the map to edit\nphoto location", for: .normal)
            } else {
                confirmPhotoLocationButton.setTitle("Tap a pin to edit\nphoto location", for: .normal)
            }
        }
    }
    //MARK: - USED WHEN COMPOSE PINS ang grouping them
    func isLocationsNearby(firstLocation: Photo, secondLocation: Photo) -> Bool {
        let first = CLLocation(latitude: firstLocation.latitude, longitude: firstLocation.longitude)
        let second = CLLocation(latitude: secondLocation.latitude, longitude: secondLocation.longitude)
        let dist = first.distance(from: second)
        print("first:\(String(describing: firstLocation.localIdentifierString)) - second:\(String(describing: secondLocation.localIdentifierString)) - dist:\(dist)")
        if  dist <= 50.0 {
            return true
        }
        return false
    }
   
    //MARK: - getting current LOCATION - function delegate
    func determineMyCurrentLocation() {
        
        locationManager = LocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        
        if LocationManager.locationServicesEnabled() {
            //locationManager.requestLocation()
            
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
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
    //MARK: - Loading image
    func loadImage(identifier: String!) -> UIImage! {
        var img: UIImage!
        let hiddenIdentifiers = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: [identifier])
        if hiddenIdentifiers.count > 0 {
            let imageSize = CGSize(width: 150, height: 150)
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let imagePath: String = path.appending("/\(identifier!)")
            if FileManager.default.fileExists(atPath: imagePath),
                let imageData: Data = FileManager.default.contents(atPath: imagePath),
                let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
                img = image.resizeImage(targetSize: imageSize)
            }
        } else {
            //This will fetch all the assets in the collection
            let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier!] , options: nil)
            //print(assets)
            
            let imageManager = PHCachingImageManager()
            //Enumerating objects to get a chached image - This is to save loading time
            
            assets.enumerateObjects{(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                print(count)
                if object is PHAsset {
                    let asset = object as! PHAsset
                    //                print(asset)
                    
                    //let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    let imageSize = CGSize(width: 150, height: 150)
                    
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .opportunistic
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    options.resizeMode = PHImageRequestOptionsResizeMode.exact
                    
                    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                        (image, info) -> Void in
                        //print(info!)
                        //let loadedImage = image
                        img = image
                        /* The image is now available to us */
                        
                    })
                }
            }
        }
        return img
    }
    
    //MARK: - gesture delegate
    //if double tap is recognized on map slider need to stay hidden
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.tapCount == 2 && !isEditingLocation {
            preventShowSlider = true
            confirmPhotoLocationButton.setTitle("Tap a pin to edit\nphoto location", for: .normal)
            print("DOUBLE TAP preventShowSlider")
        }
        return true
    }

    //MARK: - map delegate methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = self.map.dequeueReusableAnnotationView(withIdentifier: "photoAnnotation") as? PhotoAnnotationView
        let currentAnnotation = annotation as! PhotoAnnotation
        if annotationView == nil{
            var width: Double, height: Double
            if UIScreen.main.bounds.height < 700{
                width = Double(sizeForLess700ScreenHeight.width)
                height = Double(sizeForLess700ScreenHeight.height)
            } else {
                width = Double(sizeForMore700ScreenHeight.width)
                height = Double(sizeForMore700ScreenHeight.height)
            }
            annotationView = PhotoAnnotationView.init(annotation: annotation, reuseIdentifier: "photoAnnotation", isCluster: currentAnnotation.isCluster, numberOfPhotos: currentAnnotation.numberOfPhotos!, photoImage: nil, width: width, height: height)//currentAnnotation.photo
            annotationView?.canShowCallout = false
        }else{
            if annotationView?.customView != nil {
                annotationView?.customView.removeFromSuperview()
            }
            annotationView?.resetProperties(newIsCluster: currentAnnotation.isCluster, newNumberOfPhotos: currentAnnotation.numberOfPhotos!, newPhotoImage: nil)//currentAnnotation.photo)
            annotationView?.canShowCallout = false
            annotationView?.annotation = annotation
        }
        let h: CGFloat = annotationView?.bounds.height ?? 0.0
        annotationView?.centerOffset = CGPoint.init(x: -8, y: -(h / 2.0)-7);
        annotationView?.alpha = 1
        return annotationView

    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let screenCenter = self.view.center
        let annotationFrame = view.frame
        let annotationMiddleBottom = CGPoint(x: view.center.x + 8.4, y: view.center.y + (view.bounds.height / 2.0) - 2.7)
        //let x = mapView.convert( annotationMiddleBottom, to: self.view)
        
        if let isPortrait = isPortrait, !isPortrait {
            let pinCoordinate = view.annotation?.coordinate
            let currentCoordinates = mapView.centerCoordinate
            mapView.centerCoordinate = pinCoordinate!
            let viewCenter = self.view.center
            let fakeCenter = CGPoint(x: viewCenter.x, y: viewCenter.y - 100)
            let coordinate = mapView.convert(fakeCenter, toCoordinateFrom: self.view)
            mapView.centerCoordinate = currentCoordinates
            mapView.setCenter(coordinate, animated: true)
        } else {
            mapView.setCenter((view.annotation?.coordinate)!, animated: true)
        }
        
        let annotations = mapView.annotations
        currentClusterAnnotation = view.annotation as? PhotoAnnotation
        print("SELECT ---------- \(currentClusterAnnotation.subtitle ?? "")")
        gpsIcon.isHidden = true
        
        for annotation in annotations {
            if annotation.subtitle != currentClusterAnnotation?.subtitle {
                print("\(annotation.subtitle! ?? "") is OTHER Annotation than CURRENT")
            } else {
                let currentAnnotation = annotation as? PhotoAnnotation
                annotationIsMultiple = currentAnnotation!.numberOfPhotos! > 1
                var slides = [Slide]()
                for cluster in clustersPhotos {
                    for item in cluster {
                        if currentAnnotation?.subtitle == item.localIdentifierString { // this cluster should be displayed in slider
                            for item1 in cluster {
                                for slide in slideArray {
                                    if slide.localIdentifier == item1.localIdentifierString {
                                        slides.append(slide)
                                    }
                                }
                            }
                        }
                    }

                }
                confirmPhotoLocationButton.setTitle("Move single photos\nor a group", for: .normal)
                slideContainer.setSlides(slides: slides)
                
            }
        }
        preventShowSlider = false
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if animated {
            print("map changed ANIMATED - here carousel should appear (preventShowSlider \(preventShowSlider)) (isEditingLocation \(isEditingLocation)")
            if !preventShowSlider {
                if !isEditingLocation {
                    sliderVisibility(hidden: false)
                }
                for annotation in annotationsArray {
                    if annotation.subtitle == currentClusterAnnotation?.subtitle {
                        
                        let annotationView = mapView.view(for: annotation)
                        if let annotationView = annotationView {
                            let x = annotationView.frame.minX + 8//+ (annotationView!.frame.maxX - annotationView!.frame.minX) / 2
                            let y = annotationView.frame.minY + 7//+ (annotationView!.frame.maxY - annotationView!.frame.minY) / 2
                            pointForCurrentAnnotation = CGPoint(x: x, y: y) //annotationView!.convert(annotationView!.center, to: mapView)
                        }
                    }
                }
            }
            
        }
        preventShowSlider = false
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("DID DESELECT")
    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if !animated && !isEditingLocation {
            if hiddenCurrentLocation {
                gpsIcon.isHidden = hiddenCurrentLocation
                hiddenCurrentLocation = false
            } else {
                gpsIcon.isHidden = hiddenCurrentLocation
            }
            
            print("USER CHANGE REGION - carousel should disappear")
            for annotation in mapView.annotations {
                mapView.deselectAnnotation(annotation, animated: false)
                sliderVisibility(hidden: true)
                mapView.view(for: annotation)?.isHidden = false
            }
        }
    }
    

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.fillColor = UIColor.black //.withAlphaComponent(0.5)
        return renderer
    }
    
    //MARK: - location delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        lastLocation = userLocation
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        //manager.stopUpdatingLocation()
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
}
