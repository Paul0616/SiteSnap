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

class ConfirmLocationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var confirmPhotoLocationButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    var photos: [Photo]!
    var clustersPhotos = [[Photo]]()
    var locationManager: CLLocationManager!
    var lastLocation: CLLocation!
    var annotationsArray: [PhotoAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
        confirmPhotoLocationButton.layer.cornerRadius = 6
        confirmPhotoLocationButton.isEnabled = false
        confirmPhotoLocationButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        uploadButton.layer.cornerRadius = 6
        // Do any additional setup after loading the view.
        photos = PhotoHandler.fetchAllObjects()
        self.map.delegate = self
        determineMyCurrentLocation()
        for photo in photos {
            print("lat:\(photo.latitude) - long:\(photo.longitude)")
        }
        let latitude: CLLocationDegrees = (photos!.first?.latitude)!
        let longitude: CLLocationDegrees = (photos!.first?.longitude)!
//        let latDelta: CLLocationDegrees = 0.05
//        let lonDelta: CLLocationDegrees = 0.05
        //let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: 200, longitudinalMeters: 200)
        //let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
        map.setRegion(region, animated: true)
        
       
//        annotation.coordinate = location
//        annotation.title = "First Photo"
//        annotation.subtitle = "location:(\(location.latitude),\(location.longitude))"
         setPhotoClusters()
        map.mapType = .hybrid
//        map.register(PhotoAnnotationView.self,
//                         forAnnotationViewWithReuseIdentifier: "photoAnnotation")
        for cluster in clustersPhotos {
            var annotation: PhotoAnnotation!
             let loc: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (cluster.first?.latitude)!, longitude: (cluster.first?.longitude)!)
            if cluster.count > 1 {
                annotation =  PhotoAnnotation(coordinate: loc, title: "xxx", subtitle: "test", isCluster: cluster.count > 1, numberOfPhotos: cluster.count, photoImage: nil)
            } else {
                let image = loadImage(identifier: cluster.first?.localIdentifierString)
                annotation =  PhotoAnnotation(coordinate: loc, title: "xxx", subtitle: "test", isCluster: cluster.count > 1, numberOfPhotos: cluster.count, photoImage: image)
            }
           annotationsArray.append(annotation)
        }
        map.addAnnotations(annotationsArray)
        map.showAnnotations(annotationsArray, animated: true)
    }
    
    @IBAction func onBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func onClickCurrentLocation(_ sender: UIButton) {
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
    func setPhotoClusters(){
        
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
        locationManager.requestAlwaysAuthorization()
        
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
        return img
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = self.map.dequeueReusableAnnotationView(withIdentifier: "photoAnnotation")
        if annotationView == nil{
            let currentAnnotation = annotation as! PhotoAnnotation
            annotationView = PhotoAnnotationView.init(annotation: annotation, reuseIdentifier: "photoAnnotation", isCluster: currentAnnotation.isCluster!, numberOfPhotos: currentAnnotation.numberOfPhotos!, photoImage: currentAnnotation.photo)
            annotationView?.canShowCallout = true
        }else{
            annotationView?.annotation = annotation
        }

        return annotationView

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
        print("Error \(error)")
    }
}
