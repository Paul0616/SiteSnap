//
//  FlashStateButton.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class FlashStateButton: UIButton {
   var currentFlashState = "auto"
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }
    
    func initButton(){
        setBackgroundImage(UIImage(named: "flash_auto"), for: .normal)
        addTarget(self, action: #selector(FlashStateButton.buttonPressed), for: .touchUpInside)
    }
    
    @objc func buttonPressed(){
        switch currentFlashState {
        case "auto":
            changeFlashState(flashState: "on")
        case "on":
            changeFlashState(flashState: "off")
        case "off":
            changeFlashState(flashState: "auto")
        default:
            print("flash state unknown")
        }
    }
    
    func changeFlashState(flashState: String){
        switch flashState {
        case "auto":
            setBackgroundImage(UIImage(named: "flash_auto"), for: .normal)
            currentFlashState = flashState
        case "on":
            setBackgroundImage(UIImage(named: "flash_on"), for: .normal)
            currentFlashState = flashState
        case "off":
            setBackgroundImage(UIImage(named: "flash_off"), for: .normal)
            currentFlashState = flashState
        default:
            print("flash state unknown")
        }
        
    }
}

