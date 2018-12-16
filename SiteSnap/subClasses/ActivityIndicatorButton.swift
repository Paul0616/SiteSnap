//
//  ActivityIndicatorButton.swift
//  SiteSnap
//
//  Created by Paul Oprea on 15/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class ActivityIndicatorButton: UIButton {
    var activityIndicator: UIActivityIndicatorView!
    
    
//      Only override draw() if you perform custom drawing.
//      An empty implementation adversely affects performance during animation.
//     override func draw(_ rect: CGRect) {
////      Drawing code
//        super.draw(rect)
//        self.layer.cornerRadius = 10
//        self.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
//        self.setTitleColor(UIColor.black, for: .normal)
//
//     }
    override init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        layer.cornerRadius = 3
//        clipsToBounds = true
        
//    }
    func initButton(){
        self.layer.cornerRadius = 10
        self.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        self.setTitleColor(UIColor.white, for: .normal)
    }
    func showLoading() {
        if (activityIndicator == nil) {
            activityIndicator = createActivityIndicator()
        }
        showSpinning()
    }
    
    private func createActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        return activityIndicator
    }
    
    private func showSpinning() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activityIndicator)
        self.setTitle("Connecting to SiteSnap...", for: .normal)
        positioningActivityIndicatorInButton()
        activityIndicator.startAnimating()
    }
    
    func hideLoading() {
        activityIndicator.stopAnimating()
        self.setTitle("Uploading to:", for: .normal)
    }
    
    private func positioningActivityIndicatorInButton() {
        let xRightConstraint = NSLayoutConstraint(item: self, attribute: .rightMargin, relatedBy: .equal, toItem: activityIndicator, attribute: .rightMargin, multiplier: 1, constant: 10)
        self.addConstraint(xRightConstraint)
        
        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraint(yCenterConstraint)
    }
}
