//
//  PreviewView.swift
//  SiteSnap
//
//  Created by Paul Oprea on 04/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }

}
