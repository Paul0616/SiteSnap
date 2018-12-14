//
//  CameraViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 13/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
   
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var capturePreviewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    // let cameraController = CameraController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
     //   configureCameraController()
     //   let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
           // let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            //captureSession?.addInput(input)
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
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        capturePreviewView.layer.addSublayer(videoPreviewLayer!)
        captureSession?.startRunning()
        
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        //captureButton.frame.width = 70
        //captureButton.frame.height = 70
        captureButton.layer.cornerRadius = 35
        
    }
    
//    func configureCameraController(){
//        cameraController.prepare {(error) in
//            if let error = error {
//                print(error)
//            }
//            try? self.cameraController.displayPreview(on: self.capturePreviewView)
//        }
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
