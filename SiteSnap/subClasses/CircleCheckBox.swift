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

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
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
    
    
    override func awakeFromNib() {
            super.awakeFromNib()
            addTarget(self, action: #selector(CheckBox.buttonPressed), for: .touchUpInside)
            layer.borderWidth = 4 / UIScreen.main.nativeScale
            layer.borderColor = UIColor.clear.cgColor
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        self.setTitle("", for: .normal)
       isUserInteractionEnabled = true
        
        }


    override func layoutSubviews(){
        super.layoutSubviews()
        backgroundColor = UIColor(hexString: hexColor ?? "#000000")
        layer.cornerRadius = frame.height / 2
        layer.borderColor = selectedState ? UIColor.black.cgColor : UIColor.clear.cgColor
        //self.titleLabel?.textColor = selectedState ? UIColor.green : UIColor.white
    }

    @objc func buttonPressed(){
        selectedState = !selectedState
        self.layoutSubviews()
        if let delegate = delegate {
            delegate.circleButtonTapped(sender: self)
        }
    }
    
}
