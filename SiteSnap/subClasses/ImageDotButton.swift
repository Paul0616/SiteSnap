//
//  ImageDotView.swift
//  SiteSnap
//
//  Created by Paul Oprea on 20/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class ImageDotButton: UIButton {
    var selectedValue: Bool!
    var localIdentifier: String!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initDot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initDot()
    }
   
    
    func initDot() {
        makeSelfConstraint()
        selectDot(selected: false)
        self.layer.cornerRadius = 10
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
        
    }
    
    func selectDot(selected: Bool) {
        self.selectedValue = selected
        if(selected) {
            self.layer.backgroundColor = UIColor.white.cgColor
        } else {
            self.layer.backgroundColor = UIColor.clear.cgColor
        }
    }

    
    func makeSelfConstraint() {
        self.heightAnchor.constraint(equalToConstant: 20).isActive = true
        self.widthAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
}
