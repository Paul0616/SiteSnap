//
//  Slider.swift
//  SiteSnap
//
//  Created by Paul Oprea on 05/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import Photos

//@IBDesignable
class Slider: UIView, UIScrollViewDelegate {
    let kSLIDER_XIB_NAME = "Slider"
    let kSLIDE_XIB_NAME = "Slide"
   
    @IBOutlet weak var photosControl: UIPageControl!
    @IBOutlet weak var scrollContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    
    var slides: [Slide] = []
    let minImageScale: CGFloat = 0.75
    let minImageAlpha: CGFloat = 0.5
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(kSLIDER_XIB_NAME, owner: self, options: nil)
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        photosControl.numberOfPages = 0
        //photosControl.currentPage = 0
        contentView.fixInView(self)
    }
    override func layoutSubviews() {
        if slides.count > 0 {
            scrollContainer.layoutIfNeeded()
            setupSlideScrollView(slides: slides)
            onPageChange(photosControl)
        }
    }
    //MARK: - Setting up Slides and ScrollView content
    private func createSlide(image: UIImage, localIdentifier: String) -> Slide {
        
        let slide:Slide = Bundle.main.loadNibNamed(kSLIDE_XIB_NAME, owner: self, options: nil)?.first as! Slide
        slide.mainImage.image = nil
        slide.mainImage.image = image
        slide.localIdentifier = localIdentifier
        slide.backgroundColor = UIColor.clear
        slide.mainImage.layer.borderColor = UIColor.white.cgColor
        slide.mainImage.layer.borderWidth = 1
        return slide
    }
    //   MARK: - config slider
    private func setupSlideScrollView(slides : [Slide]) {
        if slides.count == 0 {
            return
        }
        for i in 0 ..< slides.count {
            slides[i].removeFromSuperview()
        }
        
        scrollView.frame = CGRect(x: 0, y: 0, width: scrollContainer.frame.width, height: scrollContainer.frame.height)
        scrollView.contentSize = CGSize(width: scrollContainer.frame.width * (CGFloat(slides.count) / 2 + 0.5), height: scrollContainer.frame.height)
        //print(scrollView.frame)
        //print(scrollView.contentSize)
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: scrollContainer.frame.width * (CGFloat(2 * i + 1) * 0.25), y: 0, width: scrollContainer.frame.width / 2, height: scrollContainer.frame.height)
           
            scrollView.addSubview(slides[i])
            if i > 0 {
                slides[i].mainImage.transform = CGAffineTransform(scaleX: minImageScale, y: minImageScale)
                slides[i].mainImage.alpha = minImageAlpha
            }
        }
        photosControl.numberOfPages = slides.count
        
       // imagesDotsContainer.bringSubviewToFront(imageControl)
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(inspectPhoto(_:)))
//        tapGestureRecognizer.numberOfTapsRequired = 1
//        scrollView.addGestureRecognizer(tapGestureRecognizer)
    }
    func setSlides(slides: [Slide]){
        self.slides.removeAll()
        for slideView in scrollView.subviews {
            slideView.removeFromSuperview()
        }
        for slide in slides {
            self.slides.append(slide)
        }
      
        photosControl.currentPage = 0
        if self.slides.count > 0 {
            setupSlideScrollView(slides: self.slides)
        }
        onPageChange(photosControl)
    }
    //MARK: - Loading images into SLIDES
    func loadImages(identifiers: [String]!) {
        //This will fetch all the assets in the collection
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers! , options: nil)
        //print(assets)
        
        let imageManager = PHCachingImageManager()
        //Enumerating objects to get a chached image - This is to save loading time
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset {
                let asset = object as! PHAsset
                
                //let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                let imageSize = CGSize(width: 200, height: 200)
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = true
                options.isNetworkAccessAllowed = true
                options.resizeMode = PHImageRequestOptionsResizeMode.exact
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    self.slides.append(self.createSlide(image: image!, localIdentifier: asset.localIdentifier))
                })
            }
        }
        if self.slides.count > 0 {
            setupSlideScrollView(slides: self.slides)
        }
        onPageChange(photosControl)
    }
    
    @IBAction func onPageChange(_ sender: UIPageControl) {
        if photosControl.numberOfPages == 0 {
            return
        }
        
        let page = sender.currentPage
        let scrollPoint = CGPoint(x: scrollContainer.frame.width * CGFloat(page) / 2, y: 0.0)
       
        UIView.animate(
            withDuration: 0.3, delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .allowUserInteraction,
            animations: {
                self.scrollView.contentOffset = scrollPoint
                self.slides[self.photosControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1, y: 1)
                if(self.photosControl.currentPage < self.slides.count - 1) {
                    self.slides[self.photosControl.currentPage + 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                    self.slides[self.photosControl.currentPage + 1].mainImage.alpha = self.minImageAlpha
                }
                if(self.photosControl.currentPage > 0) {
                    self.slides[self.photosControl.currentPage - 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                    self.slides[self.photosControl.currentPage - 1].mainImage.alpha = self.minImageAlpha
                }
                self.slides[self.photosControl.currentPage].mainImage.alpha = 1
                self.scrollView.layoutIfNeeded()
        }, completion: nil)
    }
    
    //MARK: - Scroll View function from delegate
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        targetContentOffset.pointee = scrollView.contentOffset
        
        if scrollView == scrollView {
            let maxIndex = slides.count - 1
            //print("velocity:\(velocity)")
            let targetX: CGFloat = scrollView.contentOffset.x + velocity.x * 200.0
            //print("targetX:\(targetX)")
            var targetIndex = Int(round(Double(targetX * 2 / (scrollContainer.frame.width))))
            let additionalWidth: CGFloat = 0
            var isOverScrolled = false
            
            if targetIndex <= 0 {
                targetIndex = 0
            } else {
                // in case you want to make page to center of View
                // by substract width with this additionalWidth
                //additionalWidth = 20
            }
            
            if targetIndex > maxIndex {
                targetIndex = maxIndex
                isOverScrolled = true
            }
            
            let velocityX = velocity.x
            var newOffset = CGPoint(x: (CGFloat(targetIndex) * scrollContainer.frame.width / 2) - additionalWidth, y: 0)
            if velocityX == 0 {
                // when velocityX is 0, the jumping animation will occured
                // if we don't set targetContentOffset.pointee to new offset
                if !isOverScrolled &&  targetIndex == maxIndex {
                    newOffset.x = scrollView.contentSize.width - scrollView.frame.width
                }
                targetContentOffset.pointee = newOffset
            }
            
            // Damping equal 1 => no oscillations => decay animation:
            UIView.animate(
                withDuration: 0.3, delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: velocityX,
                options: .allowUserInteraction,
                animations: {
                    //print("\(scrollView.contentSize) ->\(self.scrollContainer.frame.width)")
                    scrollView.contentOffset = newOffset
                    self.slides[self.photosControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1, y: 1)
                    if(self.photosControl.currentPage < self.slides.count - 1) {
                        self.slides[self.photosControl.currentPage + 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                        self.slides[self.photosControl.currentPage + 1].mainImage.alpha = self.minImageAlpha
                    }
                    if(self.photosControl.currentPage > 0) {
                        self.slides[self.photosControl.currentPage - 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                        self.slides[self.photosControl.currentPage - 1].mainImage.alpha = self.minImageAlpha
                    }
                    self.slides[self.photosControl.currentPage].mainImage.alpha = 1
                    scrollView.layoutIfNeeded()
            }, completion: { (finished: Bool) in
               //
            })
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = floor(scrollView.contentOffset.x * 2 / scrollContainer.frame.width)
        photosControl.currentPage = Int(pageIndex)
        
        // horizontal
        let maximumHorizontalOffset: CGFloat = scrollView.contentSize.width - scrollView.frame.width
        let currentHorizontalOffset: CGFloat = scrollView.contentOffset.x
        
        // vertical
        //        let maximumVerticalOffset: CGFloat = scrollView.contentSize.height - scrollView.frame.height
        //        let currentVerticalOffset: CGFloat = scrollView.contentOffset.y
        
        let percentageHorizontalOffset: CGFloat = currentHorizontalOffset / maximumHorizontalOffset
        //        let percentageVerticalOffset: CGFloat = currentVerticalOffset / maximumVerticalOffset
        
        
        /*
         * below code scales the imageview on paging the scrollview
         */
        let percentOffset: CGPoint = CGPoint(x: percentageHorizontalOffset, y: 0)
        let valueMin = CGFloat(photosControl.currentPage) / CGFloat(slides.count - 1)
        let valueMax = CGFloat(photosControl.currentPage + 1) / CGFloat(slides.count - 1)
        //print("\(valueMin) - \(valueMax) - percentage : \(percentageHorizontalOffset)")
        if(percentOffset.x > valueMin && percentOffset.x <= valueMax) {
            slides[photosControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1 - (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin), y: 1 - (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin))
            slides[photosControl.currentPage].mainImage.alpha = 1 - (1 - self.minImageAlpha) * (percentOffset.x - valueMin) / (valueMax - valueMin)
            if photosControl.currentPage < slides.count - 1 {
                slides[photosControl.currentPage+1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale + (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin) , y: self.minImageScale + (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin))
                slides[photosControl.currentPage + 1].mainImage.alpha = self.minImageAlpha + (1 - self.minImageAlpha) * (percentOffset.x - valueMin) / (valueMax - valueMin)
            }
        }
    }
    
}
extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
