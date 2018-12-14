//
//  CameraController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 13/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import AVFoundation

class CameraController: NSObject {
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    
    var currentCameraPosition: CameraPosition?
    
    var photoOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureVideoDataOutput?
    
    var currentMode: CameraOutputMode?
    
    func prepare(completionHandler: @escaping (Error?) -> Void){
        //------------------------
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        //------------------------
        func configureCaptureDevices() throws {
           //1
            let session = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            let cameras = (session.devices.compactMap{ $0 })
            if cameras.isEmpty {throw CameraControllerError.noCameraAvailable}
            //2
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
            //---------------------------
            func configureDeviceInput() throws {
                //3
                guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
                if let rearCamera = self.rearCamera {
                    self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                    if captureSession.canAddInput(self.rearCameraInput!) {
                        captureSession.addInput(self.rearCameraInput!)
                    }
                    self.currentCameraPosition = .rear
                } else if let frontCamera = self.frontCamera {
                    self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                    if captureSession.canAddInput(self.frontCameraInput!) {
                        captureSession.addInput(self.frontCameraInput!)
                    }
                    self.currentCameraPosition = .front
                }
                else {throw CameraControllerError.noCameraAvailable}
            }
            //-------------------------------------
            func configurePhotoOutput() throws {
                guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
                self.photoOutput = AVCapturePhotoOutput() //or// AVCaptureVideoOutput()
                self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
                if captureSession.canAddOutput(self.photoOutput!) {
                    captureSession.addOutput(self.photoOutput!)
                }
                self.currentMode = .photoMode
                captureSession.startRunning()
            }
            //----------------------------------
            
            DispatchQueue(label: "prepare").async {
                do {
                    createCaptureSession()
                    try configureCaptureDevices()
                    try configureDeviceInput()
                    try configurePhotoOutput()
                }
                catch {
                    DispatchQueue.main.async {
                        completionHandler(error)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            }
        }
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else {throw CameraControllerError.captureSessionIsMissing}
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.videoPreviewLayer!, at: 0)
        self.videoPreviewLayer?.frame = view.frame
    }
}
extension CameraController {
    enum CameraControllerError: Swift.Error {
        case noCameraAvailable
        case captureSessionIsMissing
    }
    public enum CameraPosition{
        case front
        case rear
    }
    public enum CameraOutputMode{
        case photoMode
        case videoMode
    }
}
