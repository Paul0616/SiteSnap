//
//  CameraViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 13/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var orientation = "Portrait"
   
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var capturePreviewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var captureInnerButton: UIView!
    @IBOutlet weak var selectedProjectButton: ActivityIndicatorButton!
    
    @IBOutlet weak var dropDownListProjectsTableView: UITableView!
    
    var userProjects = [ProjectModel]()
    var projectId: Int = 0
    
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
    
    }
    
    @IBAction func onClickSelectedProjectButton(_ sender: ActivityIndicatorButton) {
         animateProjectsList(toogle: dropDownListProjectsTableView.isHidden)
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
           // loadLocationTodayDocuments(locationId: locationId)
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
                    camera.unlockForConfiguration()
                    let input = try AVCaptureDeviceInput(device: camera)
                    captureSession?.addInput(input)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        orientationChange()
        videoPreviewLayer?.frame = view.layer.bounds
        capturePreviewView.layer.addSublayer(videoPreviewLayer!)
    }
    
    
    
    func orientationChange() {
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
    }
    
    @IBAction func onClickFlashButton(_ sender: FlashStateButton) {
        print(sender.currentFlashState)
    }
    @IBAction func onClickCaptureButton(_ sender: UIButton) {
        print("CLICK")
        selectedProjectButton.showLoading()
    }
    @IBAction func onClickGalerry(_ sender: UIButton) {
        print("GALERY")
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
