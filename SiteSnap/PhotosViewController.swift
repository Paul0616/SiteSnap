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

class PhotosViewController: UIViewController, UIScrollViewDelegate,  UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var dropDownListProjectsTableView: UITableView!
    @IBOutlet weak var selectedProjectButton: ActivityIndicatorButton!
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
    @IBOutlet weak var sameCommentsToAll: CheckBox!
    
    //var photosLocalIdentifiers: [String]?
    var userProjects = [ProjectModel]()
    var photoObjects: [Photo]?
    var slidesObjects:[Slide] = [];
    
    let minImageScale: CGFloat = 0.75
    let minImageAlpha: CGFloat = 0.2
    var firstTime: Bool = true
    
    //MARK: -
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
        tagNumberLabel.layer.backgroundColor = UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0).cgColor // blue
        //tagNumberLabel.layer.backgroundColor = UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0).cgColor // light purple
        tagNumberLabel.layer.borderColor = UIColor.white.cgColor
        tagNumberLabel.layer.borderWidth = 1
        deleteImageButton.layer.cornerRadius = 25
        addCommentButton.layer.cornerRadius = 25
        stackViewAllComments.isHidden = true
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.bottomAnchor.constraint(equalTo: commentScrollView.bottomAnchor, constant: 0).isActive = true
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        photoObjects = PhotoHandler.fetchAllObjects()
        if !firstTime {
            updateCommentLabel()
            updateTagNumber()
        }
        dropDownListProjectsTableView.isHidden = true
        loadingProjectIntoList()
        print("photos: \(photoObjects?.count as Any) = slides: \(slidesObjects.count)")
    }
    override func viewDidLayoutSubviews() {
        
        if firstTime {
            var identifiers = [String]()
            for photo in photoObjects! {
                identifiers.append(photo.localIdentifierString!)
            }
            firstTime = false
            loadImages(identifiers: identifiers)
        }
         updateTagNumber()
        
        if self.view.safeAreaLayoutGuide.layoutFrame.size.width > self.view.safeAreaLayoutGuide.layoutFrame.size.height {
            print("landscape")
            self.takePhotoButton.setTitle("", for: .normal)
            self.addFromGalleryButton.setTitle("", for: .normal)
            self.takePhotoButton.layer.cornerRadius = 30
            self.addFromGalleryButton.layer.cornerRadius = 30
        } else {
            print("portrait")
            self.takePhotoButton.setTitle("TAKE ANOTHER PHOTO", for: .normal)
            self.addFromGalleryButton.setTitle("ADD PHOTO FROM GALLERY", for: .normal)
            self.takePhotoButton.layer.cornerRadius = 6
            self.addFromGalleryButton.layer.cornerRadius = 6
        }
        if self.slidesObjects.count > 0 {
            self.setupSlideScrollView(slides: self.slidesObjects)
            self.onPageChange(self.imageControl)
        }
    }

    //MARK: - OPTONAL custom page Control
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
        }
    }
    
    //MARK: - Loading and processing PROJECTS
    func showProjectLoadingIndicator(){
        selectedProjectButton.showLoading()
    }
    
    func loadingProjectIntoList(){        
        self.userProjects.removeAll()
        let projects = ProjectHandler.fetchAllProjects()
        for item in projects! {
            var tagIds = [String]()
            for tag in item.availableTags! {
                let t = tag as! Tag
                tagIds.append(t.id!)
            }
            guard let projectModel = ProjectModel(id: item.id!, projectName: item.name!, latitudeCenterPosition: item.latitude, longitudeCenterPosition: item.longitude, tagIds: tagIds) else {
                fatalError("Unable to instantiate ProductModel")
            }
            self.userProjects += [projectModel]
        }
    
        self.selectedProjectButton.hideLoading(buttonText: nil)
        if let currentPrj = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            self.setProjectsSelected(projectId: currentPrj)
        }
        self.dropDownListProjectsTableView.reloadData()
     
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellProject", for: indexPath)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = userProjects[indexPath.row].projectName
         return cell
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        let selected = tableView.indexPathForSelectedRow
//        if selected == indexPath {
//            cell.contentView.backgroundColor = UIColor.black
//        } else {
//            cell.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
//        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.dropDownListProjectsTableView {
            let projectId = userProjects[indexPath.row].id
            let oldProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as? String
            
            //selectedProjectButton.setTitle("\(userProjects[indexPath.row].projectName)", for: .normal)
            animateProjectsList(toogle: false)
            let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
            selectedCell.contentView.backgroundColor = UIColor.black
            if projectId != oldProjectId {
                UserDefaults.standard.set(projectId, forKey: "currentProjectId")
                UserDefaults.standard.set(userProjects[indexPath.row].projectName, forKey: "currentProjectName")
                setProjectsSelected(projectId: projectId)
                resetAllPhotosTags(oldProjectId: oldProjectId!, oldProjectName: userProjects[indexPath.row].projectName)
            }
        }
    }
    
    func setProjectsSelected(projectId: String){
        for i in 0...userProjects.count-1 {
            userProjects[i].selected = userProjects[i].id == projectId
            if userProjects[i].selected {
                selectedProjectButton.setTitle(userProjects[i].projectName, for: .normal)
            }
        }
    }
    
    func animateProjectsList(toogle: Bool){
        UIView.animate(withDuration: 0.3, animations: {
            self.dropDownListProjectsTableView.isHidden = !toogle
        })
    }
    
    //MARK: - Selecting new project
    @IBAction func onClickSelectedProjectButton(_ sender: ActivityIndicatorButton) {
        animateProjectsList(toogle: dropDownListProjectsTableView.isHidden)
    }
  
    
    //MARK: - UI Buttons actions
    
    @IBAction func onClickAddTag(_ sender: UIButton) {
        if PhotoHandler.getAvailableTagsForCurrentProject() == 0 {
            let alert = UIAlertController(title: "Site Snap", message: "There are no tags available for this project.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "SetTagSegue", sender: sender)
        }
    }
    
    @IBAction func onClickAddFromGallery(_ sender: UIButton) {
        checkPermission()
    }
    @IBAction func onNext(_ sender: UIButton) {
         print("photos: \(photoObjects?.count ?? 0) = slides: \(slidesObjects.count)")
    }
    
    @IBAction func onClickTakePhoto(_ sender: UIButton) {
         self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onClickAddComment(_ sender: UIButton) {
        performSegue(withIdentifier: "AddCommentViewIdentifier", sender: sender)
    }
    
    
    @IBAction func onClickDeleteImageButton(_ sender: UIButton) {
        if self.imageControl.numberOfPages > 0 {
            let alert = UIAlertController(title: "Please confirm choice", message: "Are you sure you want to remove this photo?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                  self.removePhoto()
                })
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                print("cancel")
                })
            )
            self.present(alert, animated: true, completion: nil)
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
                self.slidesObjects[self.imageControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1, y: 1)
                if(self.imageControl.currentPage < self.slidesObjects.count - 1) {
                    self.slidesObjects[self.imageControl.currentPage + 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                    self.slidesObjects[self.imageControl.currentPage + 1].mainImage.alpha = self.minImageAlpha
                }
                if(self.imageControl.currentPage > 0) {
                    self.slidesObjects[self.imageControl.currentPage - 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                    self.slidesObjects[self.imageControl.currentPage - 1].mainImage.alpha = self.minImageAlpha
                }
                self.slidesObjects[self.imageControl.currentPage].mainImage.alpha = 1
                self.scrollView.layoutIfNeeded()
        }, completion: nil)
        updateCommentLabel()
        
    }
   
    @IBAction func onSwitchToAllComments(_ sender: CheckBox) {
        print(sender.isOn)
        if sender.isOn {
            let alert = UIAlertController(title: "Please confirm choice", message: "Are you sure you want to apply this comment to all photos?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.applyCommentToAllPhotos()
            })
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                print("cancel")
                self.sameCommentsToAll.isOn = false
            })
            )
            self.present(alert, animated: true, completion: nil)
        } else {
            self.resetCommentsToOriginalValues()
        }
    }
    
   
    //MARK: - reset all photos tags when user change the project
    func resetAllPhotosTags(oldProjectId: String, oldProjectName: String){
        let alertController = UIAlertController(title: "Please confirm choice",
                                                message: "If you change the project, all tags placed on the photos will be canceled because each project has its own set of available tags. Do you want that?",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                                                let tags = TagHandler.fetchObjects()
                                                for tag in tags! {
                                                    tag.photos = nil
                                                }
                                                if PhotoHandler.removeAllTags() {
                                                    print("original tags for photos was restablished")
                                                    self.tagNumberLabel.text = "0"
                                                }
                                            })
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            print("cancel")
            UserDefaults.standard.set(oldProjectId, forKey: "currentProjectId")
            UserDefaults.standard.set(oldProjectName, forKey: "currentProjectName")
            self.setProjectsSelected(projectId: oldProjectId)
        })
        )
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    //MARK: - Apply comment to all photos
    func applyCommentToAllPhotos(){
        if let comment = commentLabel.text {
            if PhotoHandler.updateAllComments(comment: comment) {
                print("All photos have same comment")
            }
        }
    }
    func resetCommentsToOriginalValues(){
        if PhotoHandler.resetComments() {
            print("Now photos have original comments")
        }
    }
    //MARK: - REMOVE Photo
    func removePhoto(){
        let page = imageControl.currentPage
        //#####################delete from core data
        let localIdentifier = slidesObjects[page].localIdentifier!
        //#########################
        
        imageControl.numberOfPages = imageControl.numberOfPages - 1
        if imageControl.numberOfPages > 0 {
            if page > 0 {
                imageControl.currentPage = page - 1
            }
        } else {
            // zero pages
        }
        slidesObjects[page].removeFromSuperview()
        slidesObjects.remove(at: page)
        setupSlideScrollView(slides: self.slidesObjects)
        if slidesObjects.count > 0 {
            onPageChange(imageControl)
        }
        //#######################
        if PhotoHandler.removePhoto(localIdentifier: localIdentifier) {
            photoObjects?.removeAll()
            if let saveToGallery = UserDefaults.standard.value(forKey: "saveToGallery") as? Bool {
                if !saveToGallery {
                   deleteAssets(withIdentifiers: [localIdentifier])
                }
            }
            photoObjects = PhotoHandler.fetchAllObjects()
        }
        //##################
  
       
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
    
    //MARK: - Setting up Slides and ScrollView content
    func createSlide(image: UIImage, localIdentifier: String) -> Slide {
        
        let slide:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide.mainImage.image = image
        slide.localIdentifier = localIdentifier
        return slide
    }

    func setupSlideScrollView(slides : [Slide]) {
        for i in 0 ..< slides.count {
            slides[i].removeFromSuperview()
        }
       
        scrollView.frame = CGRect(x: 0, y: 0, width: self.slidesContainer.frame.width, height: self.slidesContainer.frame.height)
        scrollView.contentSize = CGSize(width: self.slidesContainer.frame.width * (CGFloat(slides.count) / 2 + 0.5), height: self.slidesContainer.frame.height)
    
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: self.slidesContainer.frame.width * (CGFloat(2 * i + 1) * 0.25), y: 0, width: self.slidesContainer.frame.width / 2, height: self.slidesContainer.frame.height)
            //print("slide\(i).frame=\(slides[i].frame)")
            
            
            scrollView.addSubview(slides[i])
            if i > 0 {
                slides[i].mainImage.transform = CGAffineTransform(scaleX: minImageScale, y: minImageScale)
                slides[i].mainImage.alpha = minImageAlpha
            }
        }
        imageControl.numberOfPages = slides.count
        imagesDotsContainer.bringSubviewToFront(imageControl)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(inspectPhoto(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(tapGestureRecognizer)
//        for photo in photoObjects! {
//            print("\(photo.localIdentifierString)")
//        }
        print("photos: \(photoObjects?.count as Any) = slides: \(slides.count) in SETUP SCROLL VIEW")
    }
    
    @objc func inspectPhoto(_ sender: UITapGestureRecognizer){
        let slide = slidesObjects[imageControl.currentPage]
        performSegue(withIdentifier: "PhotoInspectorSegue", sender: slide)
    }
    
    func updateCommentLabel(){
        let page = imageControl.currentPage
        let localIdentifier = slidesObjects[page].localIdentifier!
        if let photo = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier){
            if let allComment = photo.allPhotosComment {
                addCommentButton.setImage(UIImage(named:"edit"), for: .normal)
                addCommentButton.backgroundColor = UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0) //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
                commentLabel.text = allComment
                stackViewAllComments.isHidden = false
            } else {
                if let comment = photo.individualComment {
                    addCommentButton.setImage(UIImage(named:"edit"), for: .normal)
                    addCommentButton.backgroundColor = UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0) //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
                    commentLabel.text = comment
                    stackViewAllComments.isHidden = false
                } else {
                    addCommentButton.setImage(UIImage(named:"one_comment"), for: .normal)
                    addCommentButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
                    commentLabel.text = "Tap here to add a comment"
                    stackViewAllComments.isHidden = true
                }
            }
        }
    }
    func updateTagNumber(){
        let page = imageControl.currentPage
        var photo: Photo!
        if slidesObjects.count > 0 {
            let localIdentifier = slidesObjects[page].localIdentifier!
            if PhotoHandler.allTagsWasSet(localIdentifier: localIdentifier) {
                let identifier = PhotoHandler.getAllTagsPhotoIdentifier(localIdentifier: localIdentifier)
                photo = PhotoHandler.getSpecificPhoto(localIdentifier: identifier!)
            } else {
                photo = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)
            }
            
            if let selectedPhoto = photo {
                tagNumberLabel.text = selectedPhoto.tags?.count.description
            }
        }
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
                let imageSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = true
                options.isNetworkAccessAllowed = true
                options.resizeMode = PHImageRequestOptionsResizeMode.exact
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    var assetAlreadyExist: Bool = false
                    for slide in self.slidesObjects{
                        if slide.localIdentifier == asset.localIdentifier {
                            assetAlreadyExist = true
                            break
                        }
                    }
                    if !assetAlreadyExist {
                        self.slidesObjects.append(self.createSlide(image: image!, localIdentifier: asset.localIdentifier))
                    }
                    
                })
            }
        }
        if self.slidesObjects.count > 0 {
            setupSlideScrollView(slides: self.slidesObjects)
        }
        onPageChange(imageControl)
    }
    
    //MARK: - Scroll View function from delegate
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        targetContentOffset.pointee = scrollView.contentOffset
       
        if scrollView == self.scrollView {
            let maxIndex = slidesObjects.count - 1
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
                    self.slidesObjects[self.imageControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1, y: 1)
                    if(self.imageControl.currentPage < self.slidesObjects.count - 1) {
                        self.slidesObjects[self.imageControl.currentPage + 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                        self.slidesObjects[self.imageControl.currentPage + 1].mainImage.alpha = self.minImageAlpha
                    }
                    if(self.imageControl.currentPage > 0) {
                        self.slidesObjects[self.imageControl.currentPage - 1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale, y: self.minImageScale)
                        self.slidesObjects[self.imageControl.currentPage - 1].mainImage.alpha = self.minImageAlpha
                    }
                    self.slidesObjects[self.imageControl.currentPage].mainImage.alpha = 1
                    scrollView.layoutIfNeeded()
            }, completion: { (finished: Bool) in 
                self.updateCommentLabel()
                self.updateTagNumber()
            })
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            let pageIndex = floor(scrollView.contentOffset.x * 2 / self.slidesContainer.frame.width)
            imageControl.currentPage = Int(pageIndex)
            
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
            let valueMin = CGFloat(imageControl.currentPage) / CGFloat(slidesObjects.count - 1)
            let valueMax = CGFloat(imageControl.currentPage + 1) / CGFloat(slidesObjects.count - 1)
            //print("\(valueMin) - \(valueMax) - percentage : \(percentageHorizontalOffset)")
            if(percentOffset.x > valueMin && percentOffset.x <= valueMax) {
                slidesObjects[imageControl.currentPage].mainImage.transform = CGAffineTransform(scaleX: 1 - (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin), y: 1 - (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin))
                slidesObjects[imageControl.currentPage].mainImage.alpha = 1 - (1 - self.minImageAlpha) * (percentOffset.x - valueMin) / (valueMax - valueMin)
                if imageControl.currentPage < slidesObjects.count - 1 {
                    slidesObjects[imageControl.currentPage+1].mainImage.transform = CGAffineTransform(scaleX: self.minImageScale + (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin) , y: self.minImageScale + (1 - self.minImageScale) * (percentOffset.x - valueMin) / (valueMax - valueMin))
                     slidesObjects[imageControl.currentPage + 1].mainImage.alpha = self.minImageAlpha + (1 - self.minImageAlpha) * (percentOffset.x - valueMin) / (valueMax - valueMin)
                }
            }
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            updateCommentLabel()
            updateTagNumber()
        }
    }
    
    // MARK: - Navigation
    @IBAction func unwindFromTagModal(segue: UIStoryboardSegue) {
        if let sourceViewController = segue.source as? TagsModalViewController {
            print(sourceViewController.description)
            updateTagNumber()
        }
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if  segue.identifier == "AddCommentViewIdentifier",
            let destination = segue.destination as? AddCommentsViewController {
            
            if commentLabel.text != "Tap here to add a comment" {
                destination.textForEdit = commentLabel.text!
            }
            destination.currentPhotoLocalIdentifier = self.slidesObjects[imageControl.currentPage].localIdentifier
            
        }
        if segue.identifier == "SetTagSegue",
            let destination = segue.destination as? TagsModalViewController {
            if PhotoHandler.allTagsWasSet(localIdentifier: self.slidesObjects[imageControl.currentPage].localIdentifier!)
            {
                let identifier = PhotoHandler.getAllTagsPhotoIdentifier(localIdentifier: self.slidesObjects[imageControl.currentPage].localIdentifier!)
                destination.currentPhotoLocalIdentifier = identifier
            } else {
                destination.currentPhotoLocalIdentifier = self.slidesObjects[imageControl.currentPage].localIdentifier
            }
        }
        
        if segue.identifier == "PhotoInspectorSegue",
            let destination = segue.destination as? PhotoInspectorViewController,
            let slide = sender! as? Slide {
            
            destination.localIdentifier = slide.localIdentifier
            
        }
    }
    
    
    //MARK: - delete hidden assets
    func deleteAssets(withIdentifiers identifiers: [String]) {
        let assetsToDelete : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers , options: nil)
        var validation: Bool = true
        assetsToDelete.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            //print(count)
            if object is PHAsset {
                let asset = object as! PHAsset
                validation = validation && asset.isHidden
            }
        }
        if validation {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assetsToDelete)
            })
        }
    }

    //MARK: -
}
extension PhotosViewController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {}
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {}
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        // do your job with selected assets
        var identifiers = [String]()
        for phAsset in assets {
            identifiers.append(phAsset.localIdentifier)
            var coordinates: CLLocationCoordinate2D!
            if let photoLocationCoordinate = phAsset.location?.coordinate {
                coordinates = photoLocationCoordinate
            } else {
                if let currentProject  = ProjectHandler.getCurrentProject() {
                    coordinates = CLLocationCoordinate2D(latitude: currentProject.latitude, longitude: currentProject.longitude)
                }
            }
            if PhotoHandler.savePhotoInMyDatabase(localIdentifier: phAsset.localIdentifier, creationDate: phAsset.creationDate!, latitude: coordinates.latitude, longitude: coordinates.longitude, isHidden: false) {
                print("photo saved in DataCore")
                loadImages(identifiers: identifiers)
                PhotoHandler.setFileSize(localIdentifiers: identifiers)
            }
        }
        
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

