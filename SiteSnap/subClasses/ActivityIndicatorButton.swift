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
    var image: UIImageView!
    
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
        self.image = UIImageView(image: UIImage(named: "import_export"))
        self.image.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(image)
        positioningImage()
    }
    
    func showLoading() {
        if (activityIndicator == nil) {
            activityIndicator = createActivityIndicator()
        }
        self.image.isHidden = true
        showSpinning()
    }
    
    func haveProjectSelected() -> Bool {
        return self.title(for: .normal) != "Connecting to SiteSnap..."
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
    
    func hideLoading(buttonText: String?) {
        guard let currentActivityIndicator = activityIndicator else {
            print("No activity Indicator")
            return
        }
        currentActivityIndicator.stopAnimating()
        self.image.isHidden = false
        guard let text = buttonText else {
            self.setTitle("Uploading to:", for: .normal)
            return
        }
        self.setTitle(text, for: .normal)
        
    }
    private func positioningImage() {
        self.rightAnchor.constraint(equalTo: image.rightAnchor, constant: 10).isActive = true
//        let xRightConstraint = NSLayoutConstraint(item: self, attribute: .rightMargin, relatedBy: .equal, toItem: image, attribute: .rightMargin, multiplier: 1, constant: 10)
//        self.addConstraint(xRightConstraint)
        self.centerYAnchor.constraint(equalTo: image.centerYAnchor, constant: 0).isActive = true
//        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: image, attribute: .centerY, multiplier: 1, constant: 0)
//        self.addConstraint(yCenterConstraint)
        image.heightAnchor.constraint(equalToConstant: 30).isActive = true
        image.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        let height = NSLayoutConstraint(item: self.image, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
//        let width = NSLayoutConstraint(item: self.image, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
//        self.image.addConstraints([height, width])
    
//        self.image.isHidden = true
    }
    
    private func positioningActivityIndicatorInButton() {
        activityIndicator.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
//        let xRightConstraint = NSLayoutConstraint(item: self, attribute: .rightMargin, relatedBy: .equal, toItem: activityIndicator, attribute: .rightMargin, multiplier: 1, constant: 10)
//        self.addConstraint(xRightConstraint)
//
//        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
//        self.addConstraint(yCenterConstraint)
    }
}
