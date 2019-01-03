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

class ConfirmLocationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var confirmPhotoLocationButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    var photos: [Photo]!
    var locationManager: CLLocationManager!
    var lastLocation: CLLocation!
    
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
        let region1: MKCoordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: 200, longitudinalMeters: 200)
        //let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
        map.setRegion(region1, animated: true)
        let annotation = PhotoAnnotation(coordinate: location, title: "xxx", subtitle: "test")
//        annotation.coordinate = location
//        annotation.title = "First Photo"
//        annotation.subtitle = "location:(\(location.latitude),\(location.longitude))"
        map.mapType = .hybrid
        map.addAnnotation(annotation)
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
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "photoAnnotation")
        let pinImage = UIImage(named: "pin")
        let size = CGSize(width: 150, height: 150)
        UIGraphicsBeginImageContext(size)
        pinImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        annotationView.image = resizedImage
        annotationView.canShowCallout = true
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
