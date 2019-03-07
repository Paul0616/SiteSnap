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
    var hiddenCurrentLocation: Bool = true
    var annotationIsMultiple: Bool = false
    var editLocationMode: Bool = false
    var preventShowSlider: Bool = false
    var pointForCurrentAnnotation: CGPoint!
    var currentClusterAnnotationIdentifier: String!
    var selectedPhotoIdentifier: String!
    var dummy: Annotation!
    private var scaleKvoToken:NSKeyValueObservation?
    var doubleTapGesture: UITapGestureRecognizer!
    
    var timerBackend: Timer!
    var projectWasSelected: Bool = false
    var oldProjectSelectedId: String!
    
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        map.showsCompass = false
        backButton.layer.cornerRadius = 20
        confirmPhotoLocationButton.layer.cornerRadius = 6
        confirmPhotoLocationButton.isEnabled = false
        cancelEditButton.layer.cornerRadius = 20
        cancelEditButton.isHidden = true
        gpsIcon.isHidden = true
        confirmPhotoLocationButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        uploadButton.layer.cornerRadius = 6
        // Do any additional setup after loading the view.
        photos = PhotoHandler.fetchAllObjects()
        self.map.delegate = self
        determineMyCurrentLocation()
        setPhotoClusters()
        map.mapType = .hybrid
        createAnnotations(isAfterEditLocation: false)
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
    @IBAction func onTapEditLocation(_ sender: UIButton) {
        confirmPhotoLocationButton.isEnabled = true
        confirmPhotoLocationButton.backgroundColor = UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0) //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
        cancelEditButton.isHidden = false
        gpsIcon.setImage(UIImage(named: "gps_not_fixed"), for: .normal)
        gpsIcon.isHidden = false
        uploadButton.isHidden = true
        backButton.isHidden = true
        editLocationMode = true
        for annotation in annotationsArray {
            map.view(for: annotation)?.isHidden = true
           // map.removeOverlays(map.overlays)
            
        }
        sliderVisibility(hidden: true)
        dummy = Bundle.main.loadNibNamed("Annotation", owner: self, options: nil)?.first as? Annotation
        dummy!.frame = CGRect(x: pointForCurrentAnnotation.x, y: pointForCurrentAnnotation.y, width: 120, height: 120)
        dummy.numberOfPhotos.isHidden = true
        selectedPhotoIdentifier = slideContainer.slides[slideContainer.photosControl.currentPage].localIdentifier
        dummy.photoImage.image = slideContainer.slides[slideContainer.photosControl.currentPage].mainImage.image
        map.addSubview(dummy!)
    }
    
    @IBAction func onTapEditAllClusterLocation(_ sender: UIButton) {
        confirmPhotoLocationButton.isEnabled = true
        confirmPhotoLocationButton.backgroundColor = UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0) //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
        cancelEditButton.isHidden = false
        gpsIcon.setImage(UIImage(named: "gps_not_fixed"), for: .normal)
        gpsIcon.isHidden = false
        uploadButton.isHidden = true
        backButton.isHidden = true
        editLocationMode = true
        for annotation in annotationsArray {
            map.view(for: annotation)?.isHidden = true
           // map.removeOverlays(map.overlays)
        }
        sliderVisibility(hidden: true)
        dummy = Bundle.main.loadNibNamed("Annotation", owner: self, options: nil)?.first as? Annotation
        dummy!.frame = CGRect(x: pointForCurrentAnnotation.x, y: pointForCurrentAnnotation.y, width: 120, height: 120)
        dummy.numberOfPhotos.isHidden = true
        selectedPhotoIdentifier = nil
        dummy.photoImage.isHidden = true
        dummy.numberOfPhotos.isHidden = false
        for annotation in annotationsArray {
            if annotation.subtitle == currentClusterAnnotationIdentifier {
                dummy.numberOfPhotos.text = String(annotation.numberOfPhotos!)
            }
        }
        map.addSubview(dummy!)
    }
    
    @IBAction func onTapCancelEditButton(_ sender: UIButton) {
        for annotation in annotationsArray {
            map.view(for: annotation)?.isHidden = false
            map.deselectAnnotation(annotation, animated: false)
        }
       cancelUI()
    }
    
    //MARK: - The called function for the timer
    @objc func callBackendConnection(){
        let backendConnection = BackendConnection(projectWasSelected: projectWasSelected, lastLocation: lastLocation)
        backendConnection.delegate = self
        backendConnection.attemptSignInToSiteSnapBackend()
    }
    func treatErrors(_ error: Error?) {
        print(error!)
    }
    
    func noProjectAssigned() {
        timerBackend.invalidate()
        print("TIMER INVALID - tags")
        performSegue(withIdentifier: "NoProjectsAssigned", sender: nil)
    }
    
    func databaseUpdateFinished() {
        //makeTagArray()
        //tblView.reloadData()
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


    @IBAction func onTapSetPhotoLocation(_ sender: UIButton) {
        let frame = map.frame
        let center = CGPoint(x: frame.midX, y: frame.midY)
        
//        let line = SimpleLine(frame: CGRect(x: 0, y: 0, width: 21, height: 21))
//        line.draw(CGRect(x: center.x, y: center.y, width: 21, height: 21))
//        var identifierSelected: String = currentClusterAnnotationIdentifier
//        if annotationIsMultiple {
//            identifierSelected = slideContainer.slides[slideContainer.photosControl.currentPage].localIdentifier!
//        }
        let locationCoordinate = map.convert(center, toCoordinateFrom: map)
        var identifiers = [String]()
        if selectedPhotoIdentifier == nil {
            for cluster in clustersPhotos {
                for item in cluster {
                    if item.localIdentifierString == currentClusterAnnotationIdentifier {
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
            
        if PhotoHandler.updateLocations(localIdentifiers: identifiers, location: locationCoordinate) {
            //onTapCancelEditButton(cancelEditButton)
            photos.removeAll()
            slideContainer.isHidden = true
            photos = PhotoHandler.fetchAllObjects()
            setPhotoClusters()
            createAnnotations(isAfterEditLocation: true)
           
            cancelUI()
        }
    }
    //MARK: - private methods
    private func cancelUI(){
        confirmPhotoLocationButton.isEnabled = false
        confirmPhotoLocationButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        cancelEditButton.isHidden = true
        gpsIcon.setImage(UIImage(named: "gps_fixed"), for: .normal)
        uploadButton.isHidden = false
        backButton.isHidden = false
        editLocationMode = false
        dummy.photoImage.image = nil
        dummy.removeFromSuperview()
    }
    
    private func createAnnotations(isAfterEditLocation: Bool){
        if map.annotations.count > 0 {
            map.removeAnnotations(map.annotations)
           // map.removeOverlays(map.overlays)
        }
        annotationsArray.removeAll()
        for cluster in clustersPhotos {
            var annotation: PhotoAnnotation!
            let loc: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (cluster.first?.latitude)!, longitude: (cluster.first?.longitude)!)
            var image: UIImage! = nil
            
            if cluster.count == 1 {
                image = loadImage(identifier: cluster.first?.localIdentifierString)
            }
            
            annotation =  PhotoAnnotation(coordinate: loc, title: "Image local identifier:", subtitle: (cluster.first?.localIdentifierString)!, isCluster: cluster.count > 1, numberOfPhotos: cluster.count, photoImage: image)
            annotationsArray.append(annotation)
        }
        map.addAnnotations(annotationsArray)
        if !isAfterEditLocation {
            map.showAnnotations(annotationsArray, animated: true)
//            let overlays = annotationsArray.map { MKCircle(center: $0.coordinate, radius: 2) }
//            map.addOverlays(overlays)
        }
        
    
    }
    
    
    private func setPhotoClusters(){
        clustersPhotos.removeAll()
//        for photo in photos!{
//            if photo.latitude == 0 && photo.longitude == 0 {
//                if let currentProject  = ProjectHandler.getCurrentProject() {
//                    photo.latitude = currentProject.latitude
//                    photo.longitude = currentProject.longitude
//                }
//            }
//        }
        
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
        } else {
            editAllLocationButton.isHidden = hidden
        }
    }
    //MARK: -
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
        if touch.tapCount == 2 && !editLocationMode {
            preventShowSlider = true
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
            annotationView = PhotoAnnotationView.init(annotation: annotation, reuseIdentifier: "photoAnnotation", isCluster: currentAnnotation.isCluster!, numberOfPhotos: currentAnnotation.numberOfPhotos!, photoImage: currentAnnotation.photo)
            annotationView?.canShowCallout = false
        }else{
            if annotationView?.customView != nil {
                annotationView?.customView.removeFromSuperview()
            }
            annotationView?.resetProperties(newIsCluster: currentAnnotation.isCluster!, newNumberOfPhotos: currentAnnotation.numberOfPhotos!, newPhotoImage: currentAnnotation.photo)
            annotationView?.canShowCallout = false
            annotationView?.annotation = annotation
        }
        let h: CGFloat = annotationView?.bounds.height ?? 0.0
        annotationView?.centerOffset = CGPoint.init(x: -8, y: -(h / 2.0)-7);
        return annotationView

    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //if let annotation = view.annotation?.title {
        mapView.setCenter((view.annotation?.coordinate)!, animated: true)
        let annotations = mapView.annotations
        currentClusterAnnotationIdentifier = view.annotation!.subtitle as? String
        print("SELECT")
        gpsIcon.isHidden = true
        for annotation in annotations {
            if annotation.subtitle != currentClusterAnnotationIdentifier {
                mapView.view(for: annotation)?.isHidden = true
            } else {
                let currentAnnotation = annotation as? PhotoAnnotation
                annotationIsMultiple = currentAnnotation!.numberOfPhotos! > 1
                //var identifiers = [String]()
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
                slideContainer.setSlides(slides: slides)
                
            }
        }
       
  
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if animated {
            print("map changed ANIMATED - here carousel should appear")
            if !preventShowSlider {
                if !editLocationMode {
                    sliderVisibility(hidden: false)
                }
                for annotation in annotationsArray {
                    if annotation.subtitle == currentClusterAnnotationIdentifier {
                        
                        let annotationView = mapView.view(for: annotation)
                        let x = annotationView!.frame.minX + 8//+ (annotationView!.frame.maxX - annotationView!.frame.minX) / 2
                        let y = annotationView!.frame.minY + 7//+ (annotationView!.frame.maxY - annotationView!.frame.minY) / 2
                        pointForCurrentAnnotation = CGPoint(x: x, y: y) //annotationView!.convert(annotationView!.center, to: mapView)
                    }
                }
            }
            preventShowSlider = false
        }
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("DID DESELECT")
     //   annotationWasSelected = false
    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if !animated && !editLocationMode {
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
        //renderer.strokeColor = UIColor.blue
        //renderer.lineWidth = 2
        return renderer
    }
    
    //MARK: - location delegate methods
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
        print("Error \(error)")
    }
}
