//
//  BouncingProgressView.swift
//  SiteSnap
//
//  Created by Paul Oprea on 28.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class BouncingProgressView: UIView {
    var color: UIColor? = UIColor(hexString: "#110F3E").adjustedColor(percent: 1.2) {
        didSet { setNeedsDisplay() }
    }
    var progress: CGFloat = 0 {
        didSet {
            if progress > 1.0 {
                progress = 1.0
            }
            setNeedsDisplay()
        }
    }
    
    private let progressLayer = CALayer()
    private let backgroundMask = CAShapeLayer()
    private let thumbPercent: CGFloat = 0.2
    private var progresMustIncrease: Bool = true
    private var timer: Timer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    
    private func setupLayers(){
        layer.addSublayer(progressLayer)
    }
    

    override func draw(_ rect: CGRect) {
        backgroundMask.path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.25).cgPath
        layer.mask = backgroundMask
        let thumbWidth = thumbPercent * rect.width
        let progressRect = CGRect(origin: CGPoint(x: rect.width * progress - (thumbWidth / 2), y: 0), size: CGSize(width: thumbWidth, height: rect.height))
        progressLayer.frame = progressRect
        
        layer.addSublayer(progressLayer)
        progressLayer.backgroundColor = color?.cgColor
    }
    
    
    @objc private func animate(){
        var oldProgress = self.progress
        if self.progresMustIncrease {
            oldProgress += 0.1
        } else {
            oldProgress -= 0.1
        }
        if(oldProgress > 1){
            self.progresMustIncrease = false
        }
        if(oldProgress < 0){
            self.progresMustIncrease = true
        }
        
        self.progress = oldProgress
    }
    
    func stopAnimate(){
        if timer != nil && timer.isValid {
            timer.invalidate();
            timer = nil
        }
    }
    
    func startAnimate(){
        if timer == nil || !timer.isValid {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(animate), userInfo: nil, repeats: true)
        }
    }

}
