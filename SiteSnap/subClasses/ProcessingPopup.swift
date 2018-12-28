//
//  ProcessingPopup.swift
//  SiteSnap
//
//  Created by Paul Oprea on 18/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class ProcessingPopup: UIVisualEffectView {

    private var strLabel: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    
    func createAndShow(text: String, view: UIView){
        self.effect = UIBlurEffect(style: .dark)
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 160, height: 46))
        strLabel.text = text
        //strLabel.font = .systemFont(ofSize: 14, weight: UIFontWeightMedium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        self.frame = CGRect(x: view.frame.midX - strLabel.frame.width/2, y: view.frame.midY - strLabel.frame.height/2 , width: 160, height: 46)
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.startAnimating()
        self.contentView.addSubview(activityIndicator)
        self.contentView.addSubview(strLabel)
        view.addSubview(self)
    }
    
    
    func hideAndDestroy(from view: UIView){
        //print("HIDE")
        guard let label = strLabel,
            let indicator = activityIndicator
        else {
            return
        }
        indicator.removeFromSuperview()
        label.removeFromSuperview()
        self.removeFromSuperview()
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
