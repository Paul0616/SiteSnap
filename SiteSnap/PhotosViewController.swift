//
//  Photos1ViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 21/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import Photos
import AssetsPickerViewController
import CoreData

class PhotosViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var addFromGalleryButton: UIButton!
    @IBOutlet weak var imagesDotsContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageControl: UIPageControl!
    @IBOutlet weak var slidesContainer: UIView!
    @IBOutlet weak var addTagButton: UIButton!
    @IBOutlet weak var tagNumberLabel: UILabel!
    @IBOutlet weak var deleteImageButton: UIButton!
    @IBOutlet weak var commentScrollView: UIScrollView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var stackViewAllComments: UIStackView!
    
    var photosLocalIdentifiers: [String]?
    var photoObjects: [Photo]?
    var slides:[Slide] = [];
    
    let minImageScale: CGFloat = 0.75
    let minImageAlpha: CGFloat = 0.2
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
       
        takePhotoButton.layer.cornerRadius = 6
        takePhotoButton.titleLabel?.lineBreakMode = .byWordWrapping
        takePhotoButton.titleLabel?.numberOfLines = 2
        takePhotoButton.titleLabel?.textAlignment = .center
        addFromGalleryButton.layer.cornerRadius = 6
        addFromGalleryButton.titleLabel?.lineBreakMode = .byWordWrapping
        addFromGalleryButton.titleLabel?.numberOfLines = 2
        addFromGalleryButton.titleLabel?.textAlignment = .center
        nextButton.layer.cornerRadius = 6
        addTagButton.layer.cornerRadius = 25
        tagNumberLabel.layer.cornerRadius = 15
        tagNumberLabel.layer.backgroundColor = UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0).cgColor
        tagNumberLabel.layer.borderColor = UIColor.white.cgColor
        tagNumberLabel.layer.borderWidth = 1
        deleteImageButton.layer.cornerRadius = 25
        addCommentButton.layer.cornerRadius = 15
        stackViewAllComments.isHidden = true
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.bottomAnchor.constraint(equalTo: commentScrollView.bottomAnchor, constant: 0).isActive = true
        //commentScrollView.translatesAutoresizingMaskIntoConstraints = false
        //commentScrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: commentLabel.bottomAnchor).isActive = true
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        photoObjects = appDelegate.getAllPhotos()
        //imageControl.transform = CGAffineTransform(scaleX: 2, y: 2);
        //updatePageControl()
        photosLocalIdentifiers?.removeAll()
        for photo in photoObjects! {
            photosLocalIdentifiers?.append(photo.localIdentifierString!)
        }
        scrollView.contentSize = CGSize(width: self.slidesContainer.frame.width, height: self.slidesContainer.frame.height)
        loadImages(identifiers: photosLocalIdentifiers)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation == .portrait {
            takePhotoButton.setTitle("", for: .normal)
            addFromGalleryButton.setTitle("", for: .normal)
            takePhotoButton.layer.cornerRadius = 30
            addFromGalleryButton.layer.cornerRadius = 30
        } else {
            takePhotoButton.setTitle("TAKE ANOTHER PHOTO", for: .normal)
            addFromGalleryButton.setTitle("ADD PHOTO FROM GALLERY", for: .normal)
            takePhotoButton.layer.cornerRadius = 6
            addFromGalleryButton.layer.cornerRadius = 6
        }
        if slides.count > 0 {
            setupSlideScrollView(slides: slides)
            onPageChange(imageControl)
        }
        
    }
    
    func updatePageControl() {
        for (index, dot) in imageControl.subviews.enumerated() {
            if index == imageControl.currentPage {
                dot.backgroundColor = UIColor.white
            } else {
                dot.backgroundColor = UIColor.clear
            }
            dot.layer.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            dot.layer.cornerRadius = dot.frame.size.height / 2;
            dot.layer.borderColor = UIColor.white.cgColor
            dot.layer.borderWidth = 1
            //dot.transform = CGAffineTransform.init(scaleX: 1/2, y: 1/2)
        }
    }
    
    @IBAction func onClickAddFromGallery(_ sender: UIButton) {
        checkPermission()
    }
    @IBAction func onNext(_ sender: UIButton) {
    
    }
    
    @IBAction func onClickTakePhoto(_ sender: UIButton) {
         self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onClickAddComment(_ sender: UIButton) {
        if stackViewAllComments.isHidden {
        commentLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin est lectus, ultricies quis nisi in, bibendum rhoncus justo. Duis suscipit molestie posuere. Quisque condimentum sem aliquet, mollis quam at, elementum neque. Donec sollicitudin tincidunt turpis. Ut feugiat mi nec aliquet varius. Nulla elementum consequat metus, et placerat enim sollicitudin eget. Nunc vel venenatis mi. Nulla luctus felis at ligula eleifend bibendum in vitae magna. Aenean vel purus finibus, consectetur lacus at, eleifend turpis. Quisque mattis id ex ut accumsan. Nunc leo dui, luctus vel massa in, sodales tempus magna. Integer tempus ante vitae sollicitudin elementum."
            stackViewAllComments.isHidden = false
        } else {
            commentLabel.text = "Tap here to add a comment"
            stackViewAllComments.isHidden = true
        }
    }
    
    
    @IBAction func onClickDeleteImageButton(_ sender: UIButton) {
        let page = imageControl.currentPage
        if imageControl.numberOfPages > 0 {
            imageControl.numberOfPages = imageControl.numberOfPages - 1
            if imageControl.numberOfPages > 0 {
                if page > 0 {
                    imageControl.currentPage = page - 1
                }
            } else {
                // zero pages
            }
            photosLocalIdentifiers?.remove(at: page)
            slides[page].removeFromSuperview()
            slides.remove(at: page)
            setupSlideScrollView(slides: self.slides)
            if slides.count > 0 {
                onPageChange(imageControl)
            }
        } else {
            return
        }
    }
    
    @IBAction func onPageChange(_ sender: UIPageControl) {
        let page = sender.currentPage
        let scrollPoint = CGPoint(x: self.slidesContainer.frame.width * CGFloat(page) / 2, y: 0.0)
        
        UIView.animate(
            withDuration: 0.3, delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .allowUserInteraction,
            animations: {
                self.scrollView.contentOffset = scrollPoint
                self.slides[self.imageControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1, y: 1)
                if(self.imageControl.currentPage < self.slides.count - 1) {
                    self.slides[self.imageControl.currentPage + 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                    self.slides[self.imageControl.currentPage + 1].mainImage.alpha = self.minImageAlpha
                }
                if(self.imageControl.currentPage > 0) {
                    self.slides[self.imageControl.currentPage - 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                    self.slides[self.imageControl.currentPage - 1].mainImage.alpha = self.minImageAlpha
                }
                self.slides[self.imageControl.currentPage].mainImage.alpha = 1
                self.scrollView.layoutIfNeeded()
        }, completion: nil)
    }
    
    //MARK: - Permission for viewing and saving photos in Custom Album
    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access was already granted.")
            let picker = AssetsPickerViewController()
            picker.pickerDelegate = self
            picker.pickerConfig.albumIsShowEmptyAlbum = false
            self.present(picker, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in print("status is \(newStatus)")
                if newStatus == PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("Success. Access was granted.")
                    let picker = AssetsPickerViewController()
                    picker.pickerDelegate = self
                    picker.pickerConfig.albumIsShowEmptyAlbum = false
                    self.present(picker, animated: true, completion: nil)
                }
            })
        case .restricted:
            print("User do not have access to photo album.")
        case .denied:
            print("User has denied the permission.")
        }
    }
    
    func createSlide(image: UIImage) -> Slide {
        
        let slide:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide.mainImage.image = image
        return slide
    }

    func setupSlideScrollView(slides : [Slide]) {
        for i in 0 ..< slides.count {
            slides[i].removeFromSuperview()
        }
        scrollView.frame = CGRect(x: 0, y: 0, width: self.slidesContainer.frame.width, height: self.slidesContainer.frame.height)
        scrollView.contentSize = CGSize(width: self.slidesContainer.frame.width * (CGFloat(slides.count) / 2 + 0.5), height: self.slidesContainer.frame.height)
        //scrollView.isPagingEnabled = true
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: self.slidesContainer.frame.width * (CGFloat(2 * i + 1) * 0.25), y: 0, width: self.slidesContainer.frame.width / 2, height: self.slidesContainer.frame.height)
            scrollView.addSubview(slides[i])
            if i > 0 {
                slides[i].mainImage.transform = CGAffineTransform(scaleX: minImageScale, y: minImageScale)
                slides[i].mainImage.alpha = minImageAlpha
            }
        }
        imageControl.numberOfPages = slides.count
       
//        imageControl.currentPage = 0
        //updatePageControl()
        imagesDotsContainer.bringSubviewToFront(imageControl)
    }
    
    func loadImages(identifiers: [String]!) {
        if photosLocalIdentifiers == nil {
            imageControl.numberOfPages = 0
            return
        }
        //This will fetch all the assets in the collection
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers! , options: nil)
        //print(assets)
        
        let imageManager = PHCachingImageManager()
        //Enumerating objects to get a chached image - This is to save loading time
        print(assets.count)
        assets.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            print(count)
            if object is PHAsset {
                let asset = object as! PHAsset
//                print(asset)
                
                let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = true
                options.isNetworkAccessAllowed = true
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    self.slides.append(self.createSlide(image: image!))
                    
                    /* The image is now available to us */
                    
                })
            }
        }
        if self.slides.count > 0 {
            setupSlideScrollView(slides: self.slides)
        }
        onPageChange(imageControl)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        targetContentOffset.pointee = scrollView.contentOffset
       
        if scrollView == scrollView {
            let maxIndex = slides.count - 1
            //print("velocity:\(velocity)")
            let targetX: CGFloat = scrollView.contentOffset.x + velocity.x * 200.0
            //print("targetX:\(targetX)")
            var targetIndex = Int(round(Double(targetX * 2 / (self.slidesContainer.frame.width))))
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
            var newOffset = CGPoint(x: (CGFloat(targetIndex) * self.slidesContainer.frame.width / 2) - additionalWidth, y: 0)
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
                    //print("\(scrollView.contentSize) ->\(self.slidesContainer.frame.width)")
                    scrollView.contentOffset = newOffset
                    self.slides[self.imageControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1, y: 1)
                    if(self.imageControl.currentPage < self.slides.count - 1) {
                        self.slides[self.imageControl.currentPage + 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                        self.slides[self.imageControl.currentPage + 1].mainImage.alpha = self.minImageAlpha
                    }
                    if(self.imageControl.currentPage > 0) {
                        self.slides[self.imageControl.currentPage - 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                        self.slides[self.imageControl.currentPage - 1].mainImage.alpha = self.minImageAlpha
                    }
                    self.slides[self.imageControl.currentPage].mainImage.alpha = 1
                    scrollView.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("offset \(scrollView.contentOffset.x) - framewidth \(self.slidesContainer.frame.width)")
        let pageIndex = floor(scrollView.contentOffset.x * 2 / self.slidesContainer.frame.width)
        imageControl.currentPage = Int(pageIndex)
        //print(scrollView.contentOffset.x)
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
        let valueMin = CGFloat(imageControl.currentPage) / CGFloat(slides.count - 1)
        let valueMax = CGFloat(imageControl.currentPage + 1) / CGFloat(slides.count - 1)
        //print("\(valueMin) - \(valueMax) - percentage : \(percentageHorizontalOffset)")
        if(percentOffset.x > valueMin && percentOffset.x <= valueMax) {
            slides[imageControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1 - (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin), y: 1 - (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin))
            slides[imageControl.currentPage].mainImage.alpha = 1 - (1 - self.minImageAlpha) * (percentOffset.x - valueMin) / (valueMax - valueMin)
            if imageControl.currentPage < slides.count - 1 {
                slides[imageControl.currentPage+1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale + (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin) , y: self.minImageScale + (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin))
                 slides[imageControl.currentPage + 1].mainImage.alpha = self.minImageAlpha + (1 - self.minImageAlpha) * (percentOffset.x - valueMin) / (valueMax - valueMin)
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension PhotosViewController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {}
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {}
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        // do your job with selected assets
        var identifiers = [String]()
        for phAsset in assets {
            identifiers.append(phAsset.localIdentifier)
            if (self.photosLocalIdentifiers == nil){
                self.photosLocalIdentifiers = [phAsset.localIdentifier]
            } else {
                self.photosLocalIdentifiers?.append(phAsset.localIdentifier)
            }
        }
        loadImages(identifiers: identifiers)
    }
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {}
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath) {}
}

