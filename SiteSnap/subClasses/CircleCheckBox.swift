//
//  CircleCheckBox.swift
//  SiteSnap
//
//  Created by Paul Oprea on 15.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

protocol CircleCheckBoxDelegate  {
    func circleButtonTapped(sender: CircleCheckBox)
}
class CircleCheckBox: UIButton {

    
//     Only override draw() if you perform custom drawing.
//     An empty implementation adversely affects performance during animation.
//    override func draw(_ rect: CGRect) {
//
//    }
   
    private var selectedState: Bool = false
    var isOn: Bool {
        get {
            return self.selectedState
        }
        set {
            self.selectedState = newValue
            self.layoutSubviews()
        }
    }
    var delegate: CircleCheckBoxDelegate?
    var hexColor: String?
    private var extraLayerWasDrawn = false
    
    
    override func awakeFromNib() {
            super.awakeFromNib()
            addTarget(self, action: #selector(CheckBox.buttonPressed), for: .touchUpInside)
            layer.borderWidth = 2 /// UIScreen.main.nativeScale
            layer.borderColor = UIColor.clear.cgColor
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        self.setTitle("", for: .normal)
       isUserInteractionEnabled = true
        
        }


    override func layoutSubviews(){
        super.layoutSubviews()
        backgroundColor = UIColor(hexString: hexColor ?? "#000000").adjustedColor(percent: 1.2)
        layer.cornerRadius = frame.height / 2
        layer.borderColor = selectedState ? UIColor.black.cgColor : UIColor.clear.cgColor
       
        if self.selectedState {
            if !extraLayerWasDrawn{
                print(self.selectedState)
                self.extraLayerWasDrawn = true
                let circlePath = UIBezierPath(arcCenter: CGPoint(x: self.frame.size.width / 2,y: self.frame.size.width / 2), radius: (self.frame.size.width / 2 - 3), startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
                let circleLayer = CAShapeLayer()
                circleLayer.path = circlePath.cgPath
                circleLayer.fillColor = UIColor.clear.cgColor
                circleLayer.strokeColor = UIColor.white.cgColor
                circleLayer.lineWidth = 1
                self.layer.addSublayer(circleLayer)
            }

        } else {
            if extraLayerWasDrawn {
                print(self.selectedState)
                self.extraLayerWasDrawn = false
                let _ = self.layer.sublayers?.popLast()
            }
        }
    }

    @objc func buttonPressed(){
        selectedState = !selectedState
        self.layoutSubviews()
        if let delegate = delegate {
            delegate.circleButtonTapped(sender: self)
        }
    }
    
}
