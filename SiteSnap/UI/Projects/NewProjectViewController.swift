//
//  NewProjectViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 28.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import MapKit
import AWSCognitoIdentityProvider

protocol NewProjectViewControllerDelegate: class {
    func newProjectAddedCallback(projectModel: ProjectModel?)
}

class NewProjectViewController: UIViewController, UITextFieldDelegate {
    
    var isFirstProject: Bool = false
    var pool: AWSCognitoIdentityUserPool?
    weak var delegate: NewProjectViewControllerDelegate?
    var progressVC: ProcessingViewController?

    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var createProjectLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        nextButton.layer.cornerRadius = 8
        closeButton.layer.cornerRadius = 8
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
        projectNameTextField.delegate = self
        createProjectLabel.text = isFirstProject ? "Create your first project" : "Create project"
        mapView.mapType = .hybrid
        let span = MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: -25.470554, longitude: 134.200377), span: span)
        mapView.setRegion(region, animated: false)
        self.hideKeyboardWhenTappedAround()
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            self.dismissProgressVC()
//            self.dismiss(animated: true, completion: nil)
//            self.delegate?.newProjectAddedCallback()
//       }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
  //     instantiateProgressVC()
//        if let delegate = delegate as? CameraViewController{
//            print("Camera")
//        } else if let delegate = delegate as? ProjectsListViewController {
//            print("Projects")
//        }
    }
    
//    @objc func dismissLoading(){
//        timer.invalidate()
//
//    }
    fileprivate func instantiateProgressVC(){
        progressVC = self.storyboard?.instantiateViewController(withIdentifier: ProcessingViewController.identifier) as? ProcessingViewController
        if let progressVC = progressVC {
            progressVC.modalPresentationStyle = .overCurrentContext
            progressVC.modalTransitionStyle = .crossDissolve
            present(progressVC, animated: true, completion: nil)
        }
    }
    
    fileprivate func dismissProgressVC(completion: (() -> Void)?) {
        // then remove the spinner view controller
        DispatchQueue.main.async(execute: {
            if let progressVC = self.progressVC{
                progressVC.dismiss(animated: true, completion: completion)
            }
        })
    }
    
    @IBAction func onClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onNext(_ sender: Any) {
        let frame = mapView.frame
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let locationCoordinate = mapView.convert(center, toCoordinateFrom: mapView)
        print("project name: \(projectNameTextField.text ?? "")")
        print("project rough latitude: \(locationCoordinate.latitude)")
        print("project rough longitude \(locationCoordinate.longitude)")
        let project = ProjectModel(id: "", projectName: projectNameTextField.text!, projectOwnerName: "", latitudeCenterPosition: locationCoordinate.latitude, longitudeCenterPosition: locationCoordinate.longitude, tagIds: [])
        insertNewProject(project: project)
    }
    
    func showProcessing(){
    }
    
    func insertNewProject(project: ProjectModel?){
        guard let project = project else {
            return
        }
        instantiateProgressVC()
        let url = URL(string: siteSnapBackendHost + "project/createproject")!
        var request = URLRequest(url: url)
        if (self.pool?.token().isCompleted)! {
            let tokenString = "Bearer " + (self.pool?.token().result as String?)!
            request.setValue(tokenString, forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
        } else {
            return
        }
        let parameters: [String: Any] = [
            "projectName": project.projectName,
            "centerPosition": [project.latitudeCenterPosition, project.longitudeCenterPosition],
            "baseZoom": getBoundsZoom(),
            "mobileRequest": true,
        ]
       
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        } catch let error {
            print(error.localizedDescription)
            dismissProgressVC(completion: nil)
            return
        }
        
       
        let task = URLSession.shared.dataTask(with: request as URLRequest) {(data, response, error) -> Void in
            guard error == nil else { //have errors code
                self.dismissProgressVC(completion: {
                   self.treatErrors(error)
                })
                return
            }
            guard let data = data else { //data is nil
                self.dismissProgressVC(completion: nil)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                print(json)
                self.dismissProgressVC(completion: { [self] in
                    treatErrorsAPI(json)
                })
            }
            catch let error as NSError
            {
                print(error.localizedDescription)
                self.dismissProgressVC(completion: nil)
            }
        }
        task.resume()
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
                if message != "Error"{
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
    }
    
    func treatErrorsAPI(_ json: NSDictionary?) {
        if json != nil {
            if let error = json!["error"] as? Int{
                var title = "Error"
                var message: String?
                var handler: ((UIAlertAction) -> Void)?
                switch error {
                case 0:
                    print("Successful")
                    message = "The new project was successfuly created."
                    title = "Success"
                    handler = { [self] (action) in
                        // do something when user press OK button
                            if let projectMobile = json?["projectMobile"] as? NSDictionary{
                                let id = projectMobile["id"] as! String
                                let name = projectMobile["name"] as! String
                                let projectOwnerName = projectMobile["projectOwnerName"] as! String
                                var latitude: Double?
                                var longitude: Double?
                                if let coords = projectMobile["projectCenterPosition"] as? NSArray{
                                    latitude = coords[0] as? Double
                                    longitude = coords[1] as? Double
                                }
                                let tags = projectMobile["tagIds"] as? NSArray
                                var tagsIds: [String] = []
                                for item in tags! {
                                    let tag = item as! String
                                    tagsIds.append(tag)
                                }
                                
                                let project = ProjectModel(id: id, projectName: name, projectOwnerName: projectOwnerName, latitudeCenterPosition: latitude!, longitudeCenterPosition: longitude!, tagIds: tagsIds)
                                delegate!.newProjectAddedCallback(projectModel: project)
                            }
                        self.dismiss(animated: true, completion: nil)
                    }
                case 1:
                    print("server is busy starting up, please try again later")
                    message = "Server is busy starting up, please try again later."
                case 2:
                    print("Supplied user account does exist")
                    message = "Supplied user account does exist."
                case 3:
                    print("can't understand request (something went wrong serializing the body into a json object on the server)")
                    message =  "Something went wrong when creating the new project.\n\nThe server could not understand the request from your phone. Please try again later."
                case 4:
                    print("error creating project")
                    message = "Error creating project. Please try again later."
                case 5:
                    print("company doesn't exist")
                    message = "Company doesn't exist."
                case 6:
                    print("you don't have the right to create projects")
                    message = "You don't have the right to create projects."
                case 7:
                    print("project already exists with that name")
                    message = "Project already exists with that name."
                default:
                    print("Default error")
                }
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(
                        title: title,
                        message: message ?? "",
                        preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: handler)
                    alert.addAction(OKAction)
                    self.present(alert, animated: true, completion: nil)
                })
                
            }
        }
    }

    //MARK: - UItextfieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //hide keyboard
        if textField == projectNameTextField{
            textField.resignFirstResponder()
        }
        return true
    }
    
   
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == projectNameTextField {
            animateViewMoving(up: true, moveValue: 100)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == projectNameTextField  {
            animateViewMoving(up: false, moveValue: 100)
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == projectNameTextField {
            if projectNameTextField.text != nil {
                nextButton.isEnabled = true
                nextButton.alpha = 1
            } else {
                nextButton.isEnabled = false
                nextButton.alpha = 0.5
            }
        }
    }
    
    func animateViewMoving (up:Bool, moveValue :CGFloat){
        let movementDuration:TimeInterval = 0.3
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        
        UIView.animate(withDuration: movementDuration, animations: {
            self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        })
        
//        UIView.beginAnimations("animateView", context: nil)
//        UIView.setAnimationBeginsFromCurrentState(true)
//        UIView.setAnimationDuration(movementDuration)
//
//        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
//        UIView.commitAnimations()
    }
    

    
    //MARK: - Calculate zoom level for map using map bounds
    private func getBoundsZoom() -> Int {
        let WORLD_DIM: CGSize = CGSize(width: 256.0, height: 256.0)
        let ZOOM_MAX = 21.0
        
        let nePoint: CGPoint = CGPoint(x: mapView.bounds.origin.x + mapView.bounds.size.width, y: mapView.bounds.origin.y)
        let swPoint: CGPoint = CGPoint(x: mapView.bounds.origin.x, y: mapView.bounds.origin.y + mapView.bounds.size.height)
        let neCoord: CLLocationCoordinate2D = mapView.convert(nePoint, toCoordinateFrom: mapView)
        let swCoord: CLLocationCoordinate2D = mapView.convert(swPoint, toCoordinateFrom: mapView)
        //mapView.centerCoordinate.latitude
        let latFraction = (latRad(latitude: neCoord.latitude) - latRad(latitude: swCoord.latitude)) / Double.pi
        let lngDiff = neCoord.longitude - swCoord.longitude
        let lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360
        
        let latZoom = zoom(mapPx: Double(mapView.bounds.height), worldPx: Double(WORLD_DIM.width), fraction: latFraction)
        let lngZoom = zoom(mapPx: Double(mapView.bounds.width), worldPx: Double(WORLD_DIM.height), fraction: lngFraction)
        
        return Int(min(latZoom, lngZoom, ZOOM_MAX))
    }
    
    private func latRad(latitude: Double) -> Double{
        let sinus = sin(latitude * Double.pi / 180)
        let radX2 = log((1 + sinus) / (1 - sinus)) / 2
        return max(min(radX2, Double.pi), -Double.pi) / 2
    }
    
    private func zoom(mapPx: Double, worldPx: Double, fraction: Double) -> Double{
        let mathLn2 = 0.6931471805599453
        return log(mapPx / worldPx / fraction) / mathLn2
    }

}


extension UIViewController {
    func hideKeyboardWhenTappedAround() {
          let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
          tap.cancelsTouchesInView = false
          view.addGestureRecognizer(tap)
      }
      
      @objc func dismissKeyboard() {
          view.endEditing(true)
      }
}
//extension Double {
//    func rounded(toPlaces places: Int) -> Double{
//        let divisor = pow(10.0, Double(places))
//        return  (self * divisor).rounded() / divisor
//    }
//}
