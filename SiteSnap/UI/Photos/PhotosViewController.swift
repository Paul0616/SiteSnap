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

class PhotosViewController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate, BackendConnectionDelegate {

    //@IBOutlet weak var dropDownListProjectsTableView: UITableView!
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
    @IBOutlet weak var commentsContainer: UIView!
    
//    //this reference is used to know if cameraViewController 
//    var cameraViewController: CameraViewController?
   
    var userProjects = [ProjectModel]()
    var photoObjects: [Photo]?
    var slidesObjects:[Slide] = [];
    var oldProjectSelectedId: String!
    var oldProjectSelectedName: String!
    var lastLocation: CLLocation!
    var locationManager: CLLocationManager!
    var selectedFromGallery: Bool = false
    var timerBackend: Timer!
    var wasCalledFromImageSharing: Bool = false
    
   
    var timerCanBeInvalidatedIfViewDissapear: Bool = true
    
    let minImageScale: CGFloat = 0.75
    let minImageAlpha: CGFloat = 0.2
    let darkBlue: UIColor = UIColor(red: 17/255, green: 15/255, blue: 62/255, alpha: 1.0)
    let systemGray6: UIColor = .systemGray6 //UIColor(red: 242/256, green: 242/256, blue: 247/256, alpha: 1.0)
    var firstTime: Bool = true
    var projectWasSelected: Bool = false
    private var locationSetupResult: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
    
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        selectedProjectButton.backgroundColor = darkBlue
       
        //imageControl.customPageController(dotFillColor: darkBlue, dotBorderColor: darkBlue, dotBorderwidth: 2)
        
        commentScrollView.backgroundColor = .white
        commentsContainer.layer.cornerRadius = 8
        commentScrollView.layer.cornerRadius = 8
        commentsContainer.layer.shadowColor = UIColor.gray.cgColor
        commentsContainer.layer.shadowOpacity = 0.5
        commentsContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        commentsContainer.layer.shadowRadius = 5
      
        commentLabel.textColor = darkBlue
        takePhotoButton.layer.cornerRadius = 6
        takePhotoButton.titleLabel?.lineBreakMode = .byWordWrapping
        takePhotoButton.titleLabel?.numberOfLines = 2
        takePhotoButton.titleLabel?.textAlignment = .center
        addFromGalleryButton.layer.cornerRadius = 6
        addFromGalleryButton.titleLabel?.lineBreakMode = .byWordWrapping
        addFromGalleryButton.titleLabel?.numberOfLines = 2
        addFromGalleryButton.titleLabel?.textAlignment = .center
        nextButton.layer.cornerRadius = 6
        
        takePhotoButton.isEnabled = !wasCalledFromImageSharing
       
        addTagButton.layer.cornerRadius = 25
    
        tagNumberLabel.layer.cornerRadius = 15
        tagNumberLabel.textColor = darkBlue
        tagNumberLabel.layer.backgroundColor = systemGray6.cgColor//UIColor(red:0.19, green:0.44, blue:0.90, alpha:1.0).cgColor // blue
        tagNumberLabel.layer.borderColor = darkBlue.cgColor//UIColor.white.cgColor
        tagNumberLabel.layer.borderWidth = 1
        deleteImageButton.layer.cornerRadius = 25
        addCommentButton.layer.cornerRadius = 25
        stackViewAllComments.isHidden = true
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.bottomAnchor.constraint(equalTo: commentScrollView.bottomAnchor, constant: 0).isActive = true
        checkLocationAuthorization()
        if let currentPrj = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            oldProjectSelectedId = currentPrj
        }
        if let currentPrj = UserDefaults.standard.value(forKey: "currentProjectName") as? String {
            oldProjectSelectedName = currentPrj
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleLabelCommentTap(_:)))
        commentLabel.isUserInteractionEnabled = true
        commentLabel.addGestureRecognizer(tap)
        commentsContainer.addGestureRecognizer(tap)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let image = UIImage.outlinedEllipse(size: CGSize(width: 7.0, height: 7.0), color: darkBlue, lineWidth: 0.5)
        
    
        imageControl.currentPageIndicatorTintColor = darkBlue
        imageControl.pageIndicatorTintColor = UIColor.init(patternImage: image!)//darkBlue.withAlphaComponent(0.3)
        if #available(iOS 14.0, *){
    
            //imageControl.preferredIndicatorImage = UIImage(systemName: "multiply.circle.fill")
            //imageControl.currentPageIndicatorTintColor = darkBlue
            imageControl.backgroundStyle = .prominent
            imageControl.pageIndicatorTintColor = darkBlue.withAlphaComponent(0.3)
            //imageControl.sizeToFit()
        }
        imageControl.transform = CGAffineTransform(scaleX: 2, y: 2)
        
        photoObjects = PhotoHandler.fetchAllObjects(excludeUploaded: true)
        if slidesObjects.count != 0 && slidesObjects.count != photoObjects?.count ?? 0 {
            var identifiers = [String]()
            for photo in photoObjects! {
                identifiers.append(photo.localIdentifierString!)
            }
//            firstTime = false
//            loadImages(identifiers: identifiers)
            slidesObjects.removeAll(where: {!identifiers.contains($0.localIdentifier!)})
            if self.slidesObjects.count > 0 {
                self.setupSlideScrollView(slides: self.slidesObjects)
                self.onPageChange(self.imageControl)
            }
        }
        
        if !firstTime {
            updateCommentLabel()
            updateTagNumber()
        }
        
        //dropDownListProjectsTableView.isHidden = true
        if let prjWasSelected = UserDefaults.standard.value(forKey: "projectWasSelected") as? Bool {
            projectWasSelected = prjWasSelected
        }
        loadingProjectIntoList()
        
        BackendConnection.shared.delegate = self
        if timerCanBeInvalidatedIfViewDissapear {
            if timerBackend == nil || !timerBackend.isValid {
                timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
                print("TIMER STARTED - photos")
            }
        }
        print("photos: \(photoObjects?.count ?? 0) = slides: \(slidesObjects.count)")
//        if LocationManager.locationServicesEnabled() && !LocationManager.shared.isUpdatingLocation {
//            locationManager.startUpdatingLocation()
//        }
    }
    override func viewDidLayoutSubviews() {
//        if photoObjects?.count != slidesObjects.count {
//            firstTime = true
//        }
        if firstTime {
            var identifiers = [String]()
            for photo in photoObjects! {
                identifiers.append(photo.localIdentifierString!)
            }
            firstTime = false
            loadImages(identifiers: identifiers)
        }
        print("######################################>> viewDidLayoutSubviews")
         updateTagNumber()
        self.addTagButton.isHidden = false
        self.deleteImageButton.isHidden = false
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if timerCanBeInvalidatedIfViewDissapear {
            timerBackend.invalidate()
            print("TIMER INVALID - photos")
        }
//        locationManager.stopUpdatingLocation()
    }
    
    
    //MARK: - The called function for the timer
    @objc func callBackendConnection(){
        BackendConnection.shared.attemptSignInToSiteSnapBackend(projectWasSelected: projectWasSelected, lastLocation: lastLocation)
    }
    //MARK: - Authorization for location
    func checkLocationAuthorization() {
        locationManager = LocationManager.shared
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 35.0
        locationManager.delegate = self
        switch locationSetupResult {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            break
        default:
            locationSetupResult = .denied
        }
        
        if LocationManager.locationServicesEnabled() && !LocationManager.shared.isUpdatingLocation {
            locationManager.startUpdatingLocation()
        }
    }
    
    //MARK: - CLLocationManagerDelegate functions
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationSetupResult = status
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        lastLocation = userLocation
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.

        manager.stopUpdatingLocation()
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    //MARK: - Connect to SITESnap function DELEGATE
    func displayMessageFromServer(_ message: String?) {
        if let message = message{
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(
                    title: nil,
                    message: message,
                    preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    // do something when user press OK button
                }
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    func treatErrorsApi(_ json: NSDictionary?) {
        
    }
    
    func treatErrors(_ error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            if let err = error as? URLError {
                switch err.code {
                case .notConnectedToInternet:
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "SiteSnap server access",
                            message:"Not Connected To The Internet",
                            preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case .timedOut:
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "SiteSnap server access",
                            message:"Request Timed Out",
                            preferredStyle: .alert)
                        
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                case .networkConnectionLost:
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(
                            title: "SiteSnap server access",
                            message:"Lost Connection to the Network",
                            preferredStyle: .alert)
                        
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            // do something when user press OK button
                        }
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    })
                default:
                    print("Default Error")
                    print(err)
                }
            }
        }
    }
    
    func noProjectAssigned() {
        timerBackend.invalidate()
        performSegue(withIdentifier: "NoProjectsAssigned", sender: nil)
        //return
    }
    
    func userNeedToCreateFirstProject() {
    
    }
    
    func databaseUpdateFinished() {
        loadingProjectIntoList()
        
        print("---->> databaseUpdateFinished")
        updateTagNumber()
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
        //if project list is opened should not refresh projects
//        if !dropDownListProjectsTableView.isHidden {
//            return
//        }
        self.userProjects.removeAll()
        let projects = ProjectHandler.fetchAllProjects()
        for item in projects! {
            var tagIds = [String]()
            for tag in item.availableTags! {
                let t = tag as! Tag
                tagIds.append(t.id!)
            }
            guard let projectModel = ProjectModel(id: item.id!, projectName: item.name!, projectOwnerName: item.projectOwnerName!, latitudeCenterPosition: item.latitude, longitudeCenterPosition: item.longitude, tagIds: tagIds) else {
                fatalError("Unable to instantiate ProductModel")
            }
            self.userProjects += [projectModel]
        }
    
        self.selectedProjectButton.hideLoading(buttonText: nil)
        
        if let currentPrj = UserDefaults.standard.value(forKey: "currentProjectId") as? String {
            
            self.setProjectsSelected(projectId: currentPrj)
            //----------------
            if oldProjectSelectedId != nil, oldProjectSelectedId != currentPrj {
                let alertController = UIAlertController(title: "Project no longer available",
                                                        message: "You no longer have access to the project \(oldProjectSelectedName ?? ""), either because you have been removed from it or the project has been removed by an administrator.\r\n\r\nAnother project has been selected automatically, but please confirm this is the correct project you wish to upload the photo(s) to before continuing",
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    print("New project automatically selected")
                })
                )
                
                self.present(alertController, animated: true, completion: nil)
            }
            //-----------------
        } else {
            self.showProjectLoadingIndicator()
        }
    }

    
    func setProjectsSelected(projectId: String){
        if userProjects.count == 0 {
            return
        }
        for i in 0...userProjects.count-1 {
            //userProjects[i].selected = userProjects[i].id == projectId
            if userProjects[i].id == projectId {
                selectedProjectButton.setTitle(userProjects[i].projectName, for: .normal)
                if oldProjectSelectedId == nil {
                    oldProjectSelectedId = userProjects[i].id
                    oldProjectSelectedName = userProjects[i].projectName
                }
                break
            }
        }
    }
    
//    func animateProjectsList(toogle: Bool){
//        UIView.animate(withDuration: 0.3, animations: {
//            self.dropDownListProjectsTableView.isHidden = !toogle
//        })
//    }
    
    //MARK: - Selecting new project
    @IBAction func onClickSelectedProjectButton(_ sender: ActivityIndicatorButton) {
       // animateProjectsList(toogle: dropDownListProjectsTableView.isHidden)
    }
  
    
    //MARK: - UI Buttons actions
    
    @IBAction func onClickAddTag(_ sender: UIButton) {
//        if PhotoHandler.getAvailableTagsForCurrentProject() == 0 {
//            let alert = UIAlertController(title: "Site Snap", message: "There are no tags available for this project.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        } else {
            //performSegue(withIdentifier: "SetTagSegue", sender: sender)
            performSegue(withIdentifier: "NewTagsSegue", sender: sender)
//        }
    }
    
    @IBAction func onClickAddFromGallery(_ sender: UIButton) {
        timerCanBeInvalidatedIfViewDissapear = false
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
    
    
    @objc func handleLabelCommentTap(_ sender: UITapGestureRecognizer) {
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
    @IBAction func onClickNewTags(_ sender: Any) {
        performSegue(withIdentifier: "NewTagsSegue", sender: sender)
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
                                                self.oldProjectSelectedId = UserDefaults.standard.value(forKey: "currentProjectId") as? String
                                                self.oldProjectSelectedName = UserDefaults.standard.value(forKey: "currentProjectName") as? String
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
            photoObjects = PhotoHandler.fetchAllObjects(excludeUploaded: true)
            if photoObjects?.count == 0 {
                self.dismiss(animated: false, completion: nil)
            }
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
        case .limited:
            break
        @unknown default:
            print("unknown")
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
        print("photos: \(photoObjects?.count ?? 0) = slides: \(slides.count) in SETUP SCROLL VIEW")
    }
    
    @objc func inspectPhoto(_ sender: UITapGestureRecognizer){
        let slide = slidesObjects[imageControl.currentPage]
        performSegue(withIdentifier: "PhotoInspectorSegue", sender: slide)
    }
    
    func updateCommentLabel(){
        if slidesObjects.count == 0 {
            return
        }
        let page = imageControl.currentPage
        let localIdentifier = slidesObjects[page].localIdentifier!
        if let photo = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier){
            if let allComment = photo.allPhotosComment {
                addCommentButton.setImage(UIImage(named:"edit"), for: .normal)
                addCommentButton.backgroundColor = darkBlue //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
                commentLabel.text = allComment
                stackViewAllComments.isHidden = false
            } else {
                if let comment = photo.individualComment {
                    addCommentButton.setImage(UIImage(named:"edit"), for: .normal)
                    addCommentButton.backgroundColor = darkBlue //UIColor(red:0.76, green:0.40, blue:0.86, alpha:1.0)
                    commentLabel.text = comment
                    commentLabel.textColor = darkBlue
                    stackViewAllComments.isHidden = false
                } else {
                    addCommentButton.setImage(UIImage(named:"add_comment"), for: .normal)
                    
                    addCommentButton.backgroundColor = darkBlue//UIColor(red: 0, green: 0, blue: 0, alpha: 1)
                    commentLabel.text = "Tap here to add a comment"
                    commentLabel.textColor = .systemGray2
                    stackViewAllComments.isHidden = true
                }
            }
        }
    }
    func updateTagNumber(){
        let page = imageControl.currentPage
        var photo: Photo!
        if photoObjects?.count == 0 {
            self.dismiss(animated: false, completion: nil)
            return
        }
        if photoObjects?.count != slidesObjects.count {
//            var identifiers = [String]()
//            for photo in photoObjects! {
//                identifiers.append(photo.localIdentifierString!)
//            }
//            firstTime = false
//            loadImages(identifiers: identifiers)
            
            return
        }
        if slidesObjects.count > 0 {
            let localIdentifier = slidesObjects[page].localIdentifier!
            
            //allTagsWasSet means 'apply tag to all photos' is checked
            if PhotoHandler.allTagsWasSet(localIdentifier: localIdentifier) {
                let identifier = PhotoHandler.getAllTagsPhotoIdentifier(localIdentifier: localIdentifier)
                photo = PhotoHandler.getSpecificPhoto(localIdentifier: identifier!)
            } else {
                photo = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)
                print("\(photo == nil ? "NIL \(localIdentifier)" : localIdentifier)")
            }
            
            if let selectedPhoto = photo {
                if let tags = selectedPhoto.tags, tags.count.description == "0" {
                    tagNumberLabel.isHidden = true
                } else {
                    tagNumberLabel.isHidden = false
                }
                tagNumberLabel.text = selectedPhoto.tags?.count.description
                print("-------------")
                for t in selectedPhoto.tags! {
                    let tag = t as! Tag
                    print("TAG-urile pozei: \(tag.text!)")
                }
               // print("#############")
            }
        }
    }
    
    
    //MARK: - Loading images into SLIDES
    func loadImages(identifiers: [String]!) {
        let hiddenIdentifiers = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: identifiers)
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
        if hiddenIdentifiers.count > 0 {
            let imageSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            for identifier in hiddenIdentifiers {
                let imagePath: String = path.appending("/\(identifier)")
                if FileManager.default.fileExists(atPath: imagePath),
                    let imageData: Data = FileManager.default.contents(atPath: imagePath),
                    let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
                    self.slidesObjects.append(self.createSlide(image: image.resizeImage(targetSize: imageSize), localIdentifier: identifier))
                }
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
    
//        if scrollView == dropDownListProjectsTableView as UIScrollView {
//            return
//        }
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
                print("---->> scrollViewWillEndDragging")
                self.updateTagNumber()
                self.deleteImageButton.isHidden = false
                self.addTagButton.isHidden = false
                
            })
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        deleteImageButton.isHidden = true
        addTagButton.isHidden = true
        tagNumberLabel.isHidden = true
//        if scrollView == dropDownListProjectsTableView as UIScrollView {
//            return
//        }
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
    
//        if scrollView == dropDownListProjectsTableView as UIScrollView {
//            return
//        }
        if scrollView == self.scrollView {
            updateCommentLabel()
            print("---->> scrollViewDidEndDecelerating")
            updateTagNumber()
        }
    }
    
    // MARK: - Navigation
    @IBAction func unwindFromTagModal(segue: UIStoryboardSegue) {
        
        if let sourceViewController = segue.source as? BrowseTagsViewController {
            print(sourceViewController.description)
            print("---->> unwindFromTagModal")
            updateTagNumber()
            if timerBackend == nil || !timerBackend.isValid {
                timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
                print("TIMER STARTED - photos")
            }
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
        if segue.identifier == "projectsListSegueFromPhotos", let destination = segue.destination as? ProjectsListViewController {
            destination.delegate = self
        }

        
        if segue.identifier == "PhotoInspectorSegue",
            let destination = segue.destination as? PhotoInspectorViewController,
            let slide = sender! as? Slide {
            
            destination.localIdentifier = slide.localIdentifier
            
        }
        if  segue.identifier == "ConfirmLocationSegue",
            let destination = segue.destination as? ConfirmLocationViewController {
            destination.lastLocation = lastLocation
            
        }
        
        if  segue.identifier == "NewTagsSegue",
            let destination = segue.destination as? BrowseTagsViewController {
            if PhotoHandler.allTagsWasSet(localIdentifier: self.slidesObjects[imageControl.currentPage].localIdentifier!)
            {
                let identifier = PhotoHandler.getAllTagsPhotoIdentifier(localIdentifier: self.slidesObjects[imageControl.currentPage].localIdentifier!)
                destination.currentPhotoLocalIdentifier = identifier
            } else {
                destination.currentPhotoLocalIdentifier = self.slidesObjects[imageControl.currentPage].localIdentifier
            }
            destination.lastLocation = lastLocation
            
            timerBackend.invalidate()
            
            print("TIMER INVALID - photos")
            
        }
    }
    
    
    //MARK: - delete hidden assets
    func deleteAssets(withIdentifiers identifiers: [String]) {
//        let assetsToDelete : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers , options: nil)
//        var validation: Bool = true
//        assetsToDelete.enumerateObjects{(object: AnyObject!,
//            count: Int,
//            stop: UnsafeMutablePointer<ObjCBool>) in
//            //print(count)
//            if object is PHAsset {
//                let asset = object as! PHAsset
//                validation = validation && asset.isHidden
//            }
//        }
//        if validation {
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.deleteAssets(assetsToDelete)
//            })
//        }
        for identifier in identifiers {
            let imagePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0].appending("/\(identifier)")
            do {
                try FileManager.default.removeItem(atPath: imagePath)
            } catch let error as NSError {
                print(error.debugDescription)
            }
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
        timerCanBeInvalidatedIfViewDissapear = true
        for phAsset in assets {
            identifiers.append(phAsset.localIdentifier)
            var coordinates: CLLocationCoordinate2D?
            if let photoLocationCoordinate = phAsset.location?.coordinate {
                coordinates = photoLocationCoordinate
            } else {
                if let currentProject  = ProjectHandler.getCurrentProject() {
                    coordinates = CLLocationCoordinate2D(latitude: currentProject.latitude, longitude: currentProject.longitude)
                }
            }
            if !PhotoHandler.identifierAlreadyUploaded(localIdentifier: phAsset.localIdentifier) {
                if PhotoHandler.savePhotoInMyDatabase(localIdentifier: phAsset.localIdentifier, creationDate: phAsset.creationDate ?? Date(), latitude: coordinates?.latitude, longitude: coordinates?.longitude, isHidden: false) {
                    print("photo saved in DataCore")
                    
                    loadImages(identifiers: identifiers)
                    photoObjects = PhotoHandler.fetchAllObjects(excludeUploaded: true)
                    PhotoHandler.setFileSize(localIdentifiers: identifiers)
                }
            } else {
                assetsPickerDidCancel(controller: controller)
                let alertController = UIAlertController(title: "SiteSnap", message: "This photo has already been uploaded before. Do you want to upload it again?.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                        style: .default,
                                                        handler: {action in
                                                            let _ = PhotoHandler.removePhoto(localIdentifier: phAsset.localIdentifier)
                                                            if PhotoHandler.savePhotoInMyDatabase(localIdentifier: phAsset.localIdentifier, creationDate: phAsset.creationDate ?? Date(), latitude: coordinates?.latitude, longitude: coordinates?.longitude, isHidden: false) {
                                                                print("photo saved in DataCore")
                                                                self.loadImages(identifiers: identifiers)
                                                                PhotoHandler.setFileSize(localIdentifiers: [phAsset.localIdentifier])
                                                            }
                                                        }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"),
                                                        style: .cancel,
                                                        handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
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

extension UIPageControl {
    
    func customPageController(dotFillColor: UIColor, dotBorderColor: UIColor, dotBorderwidth: CGFloat){
        for(pageIndex, dotView) in self.subviews.enumerated() {
            if self.currentPage == pageIndex {
                dotView.backgroundColor = dotFillColor
                dotView.layer.cornerRadius = dotView.frame.size.height / 2
            } else {
                dotView.backgroundColor = .clear
                dotView.layer.cornerRadius = dotView.frame.size.height / 2
                dotView.layer.borderColor = dotBorderColor.cgColor
                dotView.layer.borderWidth = dotBorderwidth
            }
        }
    }
}
extension UIImage {
    /// Creates a circular outline image.
    class func outlinedEllipse(size: CGSize, color: UIColor, lineWidth: CGFloat = 1.0) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
                return nil
        }
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        // Inset the rect to account for the fact that strokes are
        // centred on the bounds of the shape.
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5)
        context.addEllipse(in: rect)
        context.strokePath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension PhotosViewController: ProjectListViewControllerDelegate {
    func projectWasSelectedFromOutside(projectId: String) {
        
        UserDefaults.standard.set(projectId, forKey: "currentProjectId")
        if let project = ProjectHandler.getCurrentProject() {
            UserDefaults.standard.set(project.name, forKey: "currentProjectName")
            //animateProjectsList(toogle: false)
            setProjectsSelected(projectId: projectId)
            projectWasSelected = true
            UserDefaults.standard.set(projectWasSelected, forKey: "projectWasSelected")
            resetAllPhotosTags(oldProjectId: oldProjectSelectedId, oldProjectName: oldProjectSelectedName)
        }
        BackendConnection.shared.delegate = self
    }
    
    func projectsPopoverWasDismissed() {
        BackendConnection.shared.delegate = self
    }
}
