//
//  CheckBox.swift
//  SiteSnap
//
//  Created by Paul Oprea on 30/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class CheckBox: UIButton {
    //var isOn: Bool = false
    var isOn: Bool {
        get {
            return self.isSelected
        }
        set {
            self.isSelected = newValue
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }
    
    func initButton(){
//        setImage(UIImage(named: "unchecked"), for: .normal)
//        setImage(UIImage(named: "checked"), for: .selected)
        addTarget(self, action: #selector(CheckBox.buttonPressed), for: .touchUpInside)
    }
    
    @objc func buttonPressed(){
       isOn = !isOn
       self.isSelected = isOn
    }
}
