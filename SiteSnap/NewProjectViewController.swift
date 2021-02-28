//
//  NewProjectViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 28.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import MapKit

class NewProjectViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.layer.cornerRadius = 8
        closeButton.layer.cornerRadius = 8
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
        projectNameTextField.delegate = self
        mapView.mapType = .hybrid
        let span = MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: -25.470554, longitude: 134.200377), span: span)
        mapView.setRegion(region, animated: false)
        self.hideKeyboardWhenTappedAround()
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
//        project.name = projectNameTextField.text
//        project.latitude = locationCoordinate.latitude
//        project.longitude = locationCoordinate.longitude
//        insertNewProject(project: project)
    }
    
    func insertNewProject(project: ProjectModel){
        print("project name: \(project.projectName)")
        print("project rough latitude: \(project.latitudeCenterPosition)")
        print("project rough longitude \(project.longitudeCenterPosition)")
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
        
        UIView.beginAnimations("animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
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
