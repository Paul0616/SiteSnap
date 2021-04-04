//
//  UploadsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 09/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import Photos
import AWSCognitoIdentityProvider
import Alamofire
import SwiftyJSON

enum CancelRequestType: String {
    case DownloadTask = "DownloadTask"
    case DataTask = "DataTask"
    case UploadTask = "UploadTask"
    case ZeroTask = "Zero"
}
enum UploadsState {
    case paused
    case running
}

class UploadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    var images = [ImageForUpload]()
//    var uploadedImages = [ImageForUpload]()
//    subscript(index: Int) -> String? {
//        guard let projectName = uploadingImages?[index] else {
//            return nil
//        }
//        return coordinate
//    }
    
    @IBOutlet weak var backButton: UIButton!

    @IBOutlet weak var removeAllUploadedHistoryButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView1: UITableView!
    @IBOutlet weak var tableView2: UITableView!
    @IBOutlet weak var lowerTableStackView: UIStackView!
    @IBOutlet weak var lowerTableHeaderView: UIView!
    @IBOutlet weak var pauseResumeAllButton: UIButton!
    @IBOutlet weak var retryAllButton: UIButton!
    @IBOutlet weak var table2HeaderLabel: UILabel!
    //var uploadingProcessRunning: Bool = false
    var appDidEnterBackground: Bool = false
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var currentUploadingLocalIdentifier: String!
    var sessionManager: SessionManager!
    var timer: Timer!
    var isPortrait: Bool?
    var currentUploadsState: UploadsState = .paused
    var alertAlreadyDisplayed: Bool = false
    
    var sameHeightTablesConstraint: NSLayoutConstraint?
    var lowerTableZeroHightConstraint: NSLayoutConstraint?
    var lowerTableHeaderHeightConstraint: NSLayoutConstraint?
    var removeHistoryHeightConstraint: NSLayoutConstraint?
    var removeHistoryZeroHeightConstraint: NSLayoutConstraint?
    
    
    
    //MARK: - view control load
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(notification:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        setUploadingState()
        backButton.layer.cornerRadius = 20
        
        var photos = PhotoHandler.fetchAllObjects()!
        for photo in photos {
            let img = loadImage(identifier: photo.localIdentifierString)
            if let data = img!.jpegData(compressionQuality: 1.0) {
                PhotoHandler.updateFileSize(localIdentifier: photo.localIdentifierString!, size: Int64(data.count))
            }
        }
        photos = PhotoHandler.fetchAllObjects()!
        //var unprocessedImages = [ImageForUpload]()
        let currentProjectName = UserDefaults.standard.value(forKey: "currentProjectName")
        
        for photo in photos {
            
            let image = ImageForUpload(localIdentifier: photo.localIdentifierString!, projectName: currentProjectName as! String, estimatedTime: -1, fileSize: photo.fileSize, speed: 0, progress: 0, state: photo.successfulUploaded ? .done : .waiting)
            images.append(image!)
        }
        //uploadingImages.append(unprocessedImages)
        setConstraints()
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
            print("USER = CURRENT USER = \(String(describing: self.user?.username))")
        }
        currentUploadingLocalIdentifier = images[0].localIdentifier
        //uploadingProcessRunning = true
        //startUploadingOneByOne()
      
    }
    
    override func viewDidLayoutSubviews() {
        if self.view.safeAreaLayoutGuide.layoutFrame.size.width > self.view.safeAreaLayoutGuide.layoutFrame.size.height {
            print("landscape")
            isPortrait = false
        } else {
            print("portrait")
            isPortrait = true
        }
        uploadedImagesTableConstraints()
        pauseResumeAllButtonUpdateForOrientation()
    }
    
    func setConstraints(){
        lowerTableStackView.translatesAutoresizingMaskIntoConstraints = false
        lowerTableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        removeAllUploadedHistoryButton.translatesAutoresizingMaskIntoConstraints = false
        removeHistoryHeightConstraint = removeAllUploadedHistoryButton.heightAnchor.constraint(equalToConstant: 40)
        removeHistoryZeroHeightConstraint = removeAllUploadedHistoryButton.heightAnchor.constraint(equalToConstant: 0)
        sameHeightTablesConstraint = lowerTableStackView.heightAnchor.constraint(equalTo: tableView1.heightAnchor, multiplier: 0.8)
        lowerTableZeroHightConstraint = lowerTableStackView.heightAnchor.constraint(equalToConstant: 0)
        lowerTableHeaderHeightConstraint = lowerTableHeaderView.heightAnchor.constraint(equalToConstant: 56)
    }
    
    func uploadedImagesTableConstraints(){
        if let isPortrait = isPortrait, !isPortrait {
            sameHeightTablesConstraint?.isActive = false
            lowerTableHeaderHeightConstraint?.isActive = true
            removeHistoryHeightConstraint?.isActive = true
            removeHistoryZeroHeightConstraint?.isActive = false
            lowerTableZeroHightConstraint?.isActive = false
            return
        }
        
        if images.filter({$0.state == .done}).count == 0 {
            sameHeightTablesConstraint?.isActive = false
            lowerTableHeaderHeightConstraint?.isActive = false
            lowerTableZeroHightConstraint?.isActive = true
            removeHistoryHeightConstraint?.isActive = false
            removeHistoryZeroHeightConstraint?.isActive = true
            table2HeaderLabel.isHidden = true
        } else {
            sameHeightTablesConstraint?.isActive = true
            lowerTableHeaderHeightConstraint?.isActive = true
            lowerTableZeroHightConstraint?.isActive = false
            removeHistoryZeroHeightConstraint?.isActive = false
            removeHistoryHeightConstraint?.isActive = true
            table2HeaderLabel.isHidden = false
        }
    }
    
    func pauseResumeAllButtonUpdateForOrientation() {
        if let isPortrait = isPortrait{
            if isPortrait {
                pauseResumeAllButton.layer.cornerRadius = 8
                retryAllButton.setTitle("   RETRY\n   ALL UPLOADS", for: .normal)
            } else {
                pauseResumeAllButton.setTitle(nil, for: .normal)
                retryAllButton.setTitle(nil, for: .normal)
                pauseResumeAllButton.layer.cornerRadius = 30
            }
            setUploadingState()
        }
    }
    
    
    func setUploadingState(){
        let darkBlue: UIColor = UIColor(hexString: "#110F3E").adjustedColor(percent: 1.2)
        let lightBlue: UIColor = UIColor(hexString: "#4BBDE9").adjustedColor(percent: 1.1)
        
        switch currentUploadsState {
        case .paused:
            titleLabel.text = "Uploads - paused"
            if let isPortrait = isPortrait, isPortrait {
                self.pauseResumeAllButton.setTitle("   RESUME\n   ALL UPLOADS", for: .normal)
                self.pauseResumeAllButton.backgroundColor = lightBlue
                self.pauseResumeAllButton.tintColor = darkBlue
            } else {
                pauseResumeAllButton.setTitle(nil, for: .normal)
                pauseResumeAllButton.backgroundColor = .clear
                self.pauseResumeAllButton.tintColor = .white
            }
            self.pauseResumeAllButton.setTitleColor(darkBlue, for: .normal)
            self.pauseResumeAllButton.setImage(UIImage(named: "play"), for: .normal)
            return
        case .running:
            titleLabel.text = "Uploads"
            if let isPortrait = isPortrait, isPortrait {
                self.pauseResumeAllButton.setTitle("   PAUSE\n   ALL UPLOADS", for: .normal)
                self.pauseResumeAllButton.backgroundColor = darkBlue
            } else {
                pauseResumeAllButton.setTitle(nil, for: .normal)
                pauseResumeAllButton.backgroundColor = .clear
            }
            self.pauseResumeAllButton.tintColor = .white
            self.pauseResumeAllButton.setTitleColor(.white, for: .normal)
            self.pauseResumeAllButton.setImage(UIImage(named: "pause"), for: .normal)
            return
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        if images.count == 0 {
                print("disapear")
        }
    }
    
    
    //MARK: - Callback observers
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        print("App is active with notification \(notification.name.rawValue)")
        if NetworkState.isConnected() {
           // uploadingProcessRunning = true
            appDidEnterBackground = false
            //startUploadingOneByOne()
        } else {
          timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(retryUpload), userInfo: nil, repeats: false)
            
        }
    }
    
//    @objc func viewFailReason(_ sender: Any) {
//        if let codeFail = sender as? Int {
//            showErrorMessage(errorCode: codeFail)
//        }
//    }
    
    @objc func retryUpload(){
      //  uploadingProcessRunning = true
        appDidEnterBackground = false
        //startUploadingOneByOne()
        timer.invalidate()
    }
    @objc func applicationDidEnterBackground(notification: NSNotification) {
        print("App is enter in background notification \(notification.name.rawValue)")
     //   uploadingProcessRunning = false
        appDidEnterBackground = true
        //failAllWaitingImages()
    }
    
    
    func createSessionManager() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(100.0)
        sessionManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    //MARK: - UI Buttons click
    @IBAction func onRetryAll(_ sender: Any) {
        let list = images.filter({$0.state == .fail})
        guard list.count > 0 else {
            return
        }
        if sessionManager == nil {
            createSessionManager()
        }
        for image in list{
            image.state = .inProgress
            prepareUploadPhoto(localIdentifier: image.localIdentifier)
        }
        tableView1.reloadData()
    }
    
    @IBAction func onPauseResumeAll(_ sender: Any) {
        if currentUploadsState == .paused {
            currentUploadsState = .running
        } else {
            currentUploadsState = .paused
        }
        setUploadingState()
        if currentUploadsState == .running {
            if sessionManager == nil {
                createSessionManager()
            }
            for image in images.filter({$0.state == .waiting}){
                image.state = .inProgress
                prepareUploadPhoto(localIdentifier: image.localIdentifier)
            }
            tableView1.reloadData()
        }
        if currentUploadsState == .paused {
            cancelUploadRequest(request: .UploadTask)
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onClickShowRemove(_ sender: UIButton) {
        let list = images.filter({$0.state == .done})
        guard list.count > 0 else {
            return
        }
        list[sender.tag].showRemoveFlag = true
        tableView2.reloadData()
    }
    
    @IBAction func onClickRemove(_ sender: UIButton) {
    }
    
    
    @IBAction func onClickDeleteFromQueue(_ sender: UIButton) {
        let list = images.filter({$0.state != .done})
        guard list.count > 0 else {
            return
        }
        let localIdentifier = list[sender.tag].localIdentifier
        if list[sender.tag].state == .inProgress  {
            cancelUploadRequest(request: .UploadTask, localIdentifier: localIdentifier)
        } else if list[sender.tag].state == .fail || list[sender.tag].state == .waiting {
            if !alertAlreadyDisplayed {
                showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", localIdentifier: localIdentifier)
            }
        }
    }
    
    @IBAction func onClickRetry(_ sender: UIButton) {
        let list = images.filter({$0.state != .done})
        guard list.count > 0 else {
            return
        }
        let localIdentifier = list[sender.tag].localIdentifier
        if list[sender.tag].state == .fail {
            if sessionManager == nil {
                createSessionManager()
            }
            list[sender.tag].state = .inProgress
            prepareUploadPhoto(localIdentifier: localIdentifier)
            tableView1.reloadData()
        }
    }
    
    
    //MARK: - get index of current image
//    private func getStateOfImage(withIdentifier identifier: String) -> ImageForUpload.State {
//        let list = images.filter({$0.state != .done && $0.localIdentifier == identifier})
//        if list.count > 0 {
//            return list.first!.state
//        }
//        return .unknown
//    }
//
//    private func setStateOfImage(withIdentifier identifier: String, state: ImageForUpload.State){
//        if images.count > 0 {
//            for image in images {
//                if image.localIdentifier == identifier {
//                    image.state = state
//                }
//            }
//        }
//    }
//    private func startUploadingOneByOne(){
//        if images.count > 0  {
//            setStateOfImage(withIdentifier: currentUploadingLocalIdentifier, state: .inProgress)
//            prepareUploadPhoto(localIdentifier: currentUploadingLocalIdentifier)
//        }
//    }
//    private func failAllWaitingImages(){
//        if let _ = sessionManager{
//            cancelUploadRequest(request: .UploadTask)
//        }
//        if images.count > 0 {
//            for image in images {
//                image.state = .waiting
//            }
//        }
//       // self.tableView.reloadData()
//    }
    private func deleteImageIfHidden(localIdentifier: String){
        let hiddenIdentifiers = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: [localIdentifier])
        if hiddenIdentifiers.count > 0 {
            let imagePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0].appending("/\(localIdentifier)")
            do {
                try FileManager.default.removeItem(atPath: imagePath)
            } catch let error as NSError {
                print(error.debugDescription)
            }
        }
    }
    
//    private func removeImageFromTableView(withIdentifier identifier: String) {
//        if images.count > 0 {
//            print(identifier)
//            print(images.count)
//            for index in 0...images.count-1 {
//                if images[index].localIdentifier == identifier {
//                    images.remove(at: index)
//                    break
//                }
//            }
//        }
//    }
    
    private func makeImageDone(localIdentifier: String){
        //var i: Int = 0
        let list = images.filter({$0.localIdentifier == localIdentifier})
        if list.count > 0 {
            list.first?.state = .done
            list.first?.date = Date()
        }
        
//        for imagesUnloaded in images {
//            if imagesUnloaded.localIdentifier == localIdentifier {
//                imagesUnloaded.state = ImageForUpload.State.done
//
//                imagesUnloaded.date = Date()
//                break
//            }
//        }
        if PhotoHandler.updateSuccessfulyUploaded(localIdentifier: localIdentifier, succsessfuly: true) {
            print("was signaled upload in database")
        }
        
//        let list = images.filter({$0.state == .waiting})
//        if list.count > 0 {
//            currentUploadingLocalIdentifier = list.first?.localIdentifier
//            updateProgressAndReloadData(localIdentifier: currentUploadingLocalIdentifier, progress: 0, speed: 0, estimatedTime: -1)
//        }
        tableView1.reloadData()
        tableView2.reloadData()

    }
    
    //MARK; - Prepare upload photo
    func prepareUploadPhoto(localIdentifier: String) {
        //let index = getIndexOfImage(withIdentifier: localIdentifier)
        let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as! String
        let photo = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)
        let latitude = photo?.latitude
        let longitude = photo?.longitude
        
        var comment: String = ""
        if let allComment = photo?.allPhotosComment {
            comment = allComment
        } else {
            if let individualComment = photo?.individualComment {
                comment = individualComment
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        var myDate: String = formatter.string(from: Date())
        if let createdDate = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)?.createdDate {
            myDate = formatter.string(from:  createdDate as Date)
        }
        var tagIds:String = ""
        
        let tagsForAllPicturesFlag = photo?.allTagsWasSet ?? false
        var identifierUsedForGetTags = localIdentifier
        if tagsForAllPicturesFlag {
            identifierUsedForGetTags = photo?.localIdentifierForAllTags ?? localIdentifier
        }
        if let tags = PhotoHandler.getSpecificPhoto(localIdentifier: identifierUsedForGetTags)?.tags {
            for tag in tags {
                let tag = tag as? Tag
                if let tagId = tag!.id {
                    if tagId != "" {
                        tagIds += tagId + ","
                    }
                }
            }
        }
       
        tagIds = String(tagIds.dropLast())
        let gpsLocation: String = String("\(latitude!),\(longitude!)")
        var deviceId: String = ""
        if let devId = user?.deviceId {
            deviceId = devId
        }
        var debug: String
       
        if let statusDebug = UserDefaults.standard.value(forKey: "debugMode") as? Bool {
            debug = "\(statusDebug)"
        } else {
            debug = "false"
        }
        debug = "true"
        var version: String
        if let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String {
            version = appVersion
        } else {
            version = "1.0"
        }
        let parameters = [
            "forProject": currentProjectId,
            "gpsLocation": gpsLocation,
            "isPrivate": "false",
            "debug": debug,
            "comment": comment,
            "photoDate": myDate,
            "tags": tagIds,
            "appVersion": version,
            "deviceId": deviceId,
            "addDevice": "iOS",
            ]
        if let image = loadImage(identifier: localIdentifier) {
          //  uploadingProcessRunning = true
            //postRequest(identifier: localIdentifier, image: image, parameters: parameters)
            postRequestWith(identifier: localIdentifier, image: image, parameters: parameters)
        }
    }
    
    //MARK: - Alert
    private func showAlert(alertMsg: String, message: String, localIdentifier: String){
        let messageToShow = NSLocalizedString(message, comment: alertMsg)
        let alertController = UIAlertController(title: "Please confirm choice", message: messageToShow, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Confirm cancel upload"),
                                                style: .default,
                                                handler: { action in
                                                    self.alertAlreadyDisplayed = false
                                                    let result = PhotoHandler.photosDeleteBatch(identifiers: [localIdentifier])
                                                    if !result {
                                                        return
                                                    }
                                                    var i: Int = 0
                                                    for image in self.images {
                                                        if image.localIdentifier == localIdentifier {
                                                            self.images.remove(at: i)
                                                            break
                                                        }
                                                        i += 1
                                                    }
                                                    self.tableView1.reloadData()
                                                    
                                                }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Photo will continue to upload"),
                                                style: .cancel,
                                                handler: {action in self.alertAlreadyDisplayed = false}))
        alertAlreadyDisplayed = true
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showErrorMessage(errorCode: Int?){
        guard let errorCode = errorCode else {return}
        var messageToShow: String = ""
        var secondAction: String?
        switch(errorCode){
        case 1:
            messageToShow = "The version of SiteSnap you are running is too old. Please go to the App Store and update to a newer version to continue uploading photos."
            secondAction = "GO TO APPLE STORE"
        case 8:
            messageToShow = "The version of SiteSnap you are running is too old. Please go to the App Store and update to a newer version to continue uploading photos."
            secondAction = "GO TO APPLE STORE"
        case 2:
            messageToShow = "You are uploading from an unsupported device. Please upload photos from a different supported device."
        case 3:
            messageToShow = "You have too many devices signed into the same account at the same time. You can sign out of all of your devices with the Sign Out button below. You will then need to sign in again on this device to resume uploading photos."
            secondAction = "sign out completely".uppercased()
        case 4:
            messageToShow = "The project you are attempting to upload to does not exist or you no longer have permission to upload to it."
        case 5:
            if UserDefaults.standard.value(forKey: "isAdmin") as! Bool {
                messageToShow = "The project you are uploading to is archived, and as such no changes may be made to it including photo uploads. Please un-archive the project through the web app if you want to upload photos to it."
            } else if UserDefaults.standard.value(forKey: "isRunningSiteSnapFree") as! Bool {
                messageToShow = "The project you are uploading to is archived, and as such no changes may be made to it including photo uploads. Please contact the owner of the project to un-archive the project if you need to upload photos to it."
            } else {
                messageToShow = "The project you are uploading to is archived, and as such no changes may be made to it including photo uploads. Please contact your SiteSnap administrator to un-archive the project if you need to upload photos to it."
            }
        case 6...7:
            messageToShow = "The project you are uploading to has been deleted. As such, you cannot upload photos to it."
        case 9:
            messageToShow = "SiteSnap does not support this image format. You can upload JPEG, PNG and GIF files. Please try a different image."
        case 10:
            messageToShow = "Something went wrong uploading your image to SiteSnap, error number 1. Please contact SiteSnap Support if this problem persists."
        case 11:
            messageToShow = "Something went wrong uploading your image to SiteSnap, error number 2. Please contact SiteSnap Support if this problem persists."
        case 12:
            messageToShow = "Something went wrong uploading your image to SiteSnap, error number 3. Please contact SiteSnap Support if this problem persists."
        case 13:
            messageToShow = "Something went wrong uploading your image to SiteSnap, error number 4. Please contact SiteSnap Support if this problem persists."
        case 14:
            messageToShow = "Something went wrong uploading your image to SiteSnap, error number 5. Please wait a minute and try again."
        case 15:
            messageToShow = "Something went wrong uploading your image to SiteSnap, error number 6. Please wait a minute and try again."
        case 16:
            if UserDefaults.standard.value(forKey: "isRunningSiteSnapFree") as! Bool {
                messageToShow = "Your account is no longer active. Please go to sitesnap.com.au and recreate your account."
            } else {
                messageToShow = "Your account is no longer active. Please contact your SiteSnap administrator."
            }
        case 17:
            messageToShow = "Something went wrong uploading your image to SiteSnap, error number 7. Please wait a minute and try again."
        case 18:
            messageToShow = "You have run out of space in your account to upload this photo. Please clear space by deleting photos through the web app or by upgrading your account to include more storage."
            secondAction = "show account options".uppercased()
        default:
            messageToShow = "\(errorCode)"
        }

        let alertController = UIAlertController(title: "Error uploading photo", message: messageToShow, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in self.alertAlreadyDisplayed = false}))
        if let title = secondAction {
            alertController.addAction(UIAlertAction(title: title, style: .default, handler: { action in
                                                        self.alertAlreadyDisplayed = false
                                                        print("DO SOMETHING") }))
        }
        alertAlreadyDisplayed = true
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - change state of an image
//    private func changeState(fromState state: ImageForUpload.State, localIdentifier: String) {
//
//       // let state = getStateOfImage(withIdentifier: localIdentifier)
//        switch state {
//            case .inProgress:
//              // cancelUploadRequest(request: .UploadTask)
//               setStateOfImage(withIdentifier: localIdentifier, state: .fail)
//               updateProgressAndReloadData(localIdentifier: localIdentifier, progress: 0, speed: 0, estimatedTime: -1)
//            break
//
//            case .waiting:
//                if PhotoHandler.removePhoto(localIdentifier: localIdentifier) {
//                    removeImageFromTableView(withIdentifier: localIdentifier)
//                    deleteImageIfHidden(localIdentifier: localIdentifier)
//                    tableView1.reloadData()
//                }
//            break
//
//            case .done:
//            break
//
//            case .fail:
//                setStateOfImage(withIdentifier: localIdentifier, state: .waiting)
////                if !uploadingProcessRunning {
////                    setStateOfImage(withIdentifier: localIdentifier, state: .inProgress)
////                    prepareUploadPhoto(localIdentifier: localIdentifier)
////                }
//            break
//
//            case .unknown:
//            break
//        }
//    }
    
   
   
    
    func postRequestWith(identifier: String, image: UIImage?, parameters: Parameters, onCompletion: ((JSON?) -> Void)? = nil, onError: ((Error?) -> Void)? = nil){
        var data: Data!
        var fileName: String = "image.jpg"
        var mimeType: String = "image/jpg"
        guard let url = URL(string: siteSnapBackendHost + "photo") else { return }
        if let image = image {
            guard let mediaImage = Media(withImage: image, forKey: "image") else { return }
            data = mediaImage.data
            fileName = mediaImage.filename
            mimeType = mediaImage.mimeType
        }
        
        let tokenString = "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String)!
        let headers: HTTPHeaders = [
            "Authorization": tokenString,
            "Content-type": "multipart/form-data"
        ]
        //time = Date()
        if let image = images.filter({$0.localIdentifier == identifier}).first {
            image.startUploadingDate = Date()
        }

        guard let sessionManager = sessionManager else { return }
        sessionManager.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in parameters {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            
            if let data = data{
                multipartFormData.append(data, withName: "image", fileName: fileName, mimeType: mimeType)
            }
        
            
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { (result) in
            switch result{
            case .success(let upload, _, _):
                upload
                    .validate(statusCode: 200 ..< 300)
                    .response { [self] response in
                        if let error = response.error {
                           // self.uploadingProcessRunning = false
                            
//                            if !self.appDidEnterBackground  {
//                                let state = self.getStateOfImage(withIdentifier: identifier)
//                                self.changeState(fromState: state, localIdentifier: identifier)
//                            }
                            print(response.response?.statusCode as Any)
                            if let statusCode = response.response?.statusCode {
                                if !alertAlreadyDisplayed {
                                    if statusCode == 401 {
                                        //SHOW message "Network connection failure. Please make sure you have a reliable connection to the internet and try uploading again."
                                        cancelUploadRequest(request: .UploadTask)
                                    } else {
                                        //SHOW message Http status code error \(statusCode)
                                        cancelUploadRequest(request: .UploadTask)
                                    }
                                }
                                //cancelUploadRequest(request: .UploadTask, localIdentifier: identifier)
                            } else {
                                if error.localizedDescription == "cancelled" {
                                    print(error.localizedDescription)
                                }
                                if error.localizedDescription == "Internet appear to be offline." {
                                    print(error.localizedDescription)
                                    //SHOW message "Network connection failure. Please make sure you have a reliable connection to the internet and try uploading again."
                                    cancelUploadRequest(request: .UploadTask)
                                }
                            }
                            
                        } else {
                            
                           // self.uploadingProcessRunning = false
                            
                            if let data = String(data: response.data!, encoding: .utf8){
                                print(Int(data) ?? -1)
                                let image = images.filter({$0.localIdentifier == identifier}).first
                                if let image = image {
                                    if (Int(data) ?? -1) != 0 {
                                        image.failCode = Int(data) ?? -1
                                        image.state = .fail
                                    } else {
                                        image.state = .done
                                        tableView2.reloadData()
                                    }
                                    tableView1.reloadData()
                                }
                            }
                           // self.makeImageDone(localIdentifier: identifier)

                        }
                       
                        
                       
                    }
                    .uploadProgress { progress in
                        if let image = self.images.filter({$0.localIdentifier == identifier}).first {
                            let elapsedtime = abs(image.startUploadingDate.timeIntervalSinceNow)
                            let estimatedSpeed = Int(Double(progress.completedUnitCount) / (elapsedtime * 1024))
                            
                            let remainingTime = round(Double((progress.totalUnitCount - progress.completedUnitCount)) / Double(estimatedSpeed * 1024))
                            self.updateProgressAndReloadData(localIdentifier: identifier, progress: CFloat(progress.fractionCompleted), speed: estimatedSpeed, estimatedTime: Int(remainingTime))
                        }
                    }
                self.images.filter({$0.localIdentifier == identifier}).first!.uploadingTaskIdentifier = upload.task?.taskIdentifier
               
            case .failure(let error):
             //   self.uploadingProcessRunning = false
                print("Error in upload: \(error.localizedDescription)")
            
//                let state = self.getStateOfImage(withIdentifier: identifier)
//                self.changeState(fromState: state, localIdentifier: identifier)

            }
        }
    }
    
    
    
    func cancelUploadRequest(request: CancelRequestType, localIdentifier: String? = nil) {
        guard let sessionManager = sessionManager else { return }
        sessionManager.session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            switch request {
            case .DataTask:
                dataTasks.forEach {  $0.cancel() }
                print("- - - Data task was canceled!")
            case .UploadTask:
                if let identifier = localIdentifier {
                    if let taskIdentifier = self.images.filter({$0.localIdentifier == identifier}).first!.uploadingTaskIdentifier {
                        print("Task identifier: \(taskIdentifier)")
                        let tasks = uploadTasks.filter({$0.taskIdentifier == taskIdentifier})
                        if tasks.count > 0 {
                            tasks.first!.cancel()
                        }
                        DispatchQueue.main.async {
                            self.images.filter({$0.localIdentifier == identifier}).first!.state = .waiting
                            self.tableView1.reloadData()
                        }
                    }
                } else {
                    uploadTasks.forEach { $0.cancel() }
                    DispatchQueue.main.async {
                        self.images.filter({$0.state == .inProgress}).forEach({image in
                            image.state = .waiting
                        })
                        self.tableView1.reloadData()
                        self.sessionManager = nil
                    }
                }
                print("- - - Upload task was canceled!")
            case .DownloadTask:
                downloadTasks.forEach { $0.cancel() }
                print("- - - Download task was canceled!")
            case .ZeroTask:
                print("- - - Zero tasks was found!")
            }
        }
    }

    typealias Parameters = [String: String]
 
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do.a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if  segue.identifier == "backToCameraSegue",
            let destination = segue.destination as? CameraViewController {
            destination.photoDatabaseShouldBeDeleted = true
            
        }
    }
    
    //MARK: -
    func converByteToHumanReadable(_ bytes:Int64) -> String {
        let formatter:ByteCountFormatter = ByteCountFormatter()
        formatter.countStyle = ByteCountFormatter.CountStyle.binary

        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    //MARK: - UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
            case tableView1:
                return images.filter({$0.state != .done}).count
            case tableView2:
                return images.filter({$0.state == .done}).count
            default:
                return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableView {
        case tableView1:
            let uploadingImages = images.filter({$0.state != .done})
            let cell = tableView.dequeueReusableCell(withIdentifier: "UploadingCellIdentifier", for: indexPath) as! UploadsTableViewCell
            cell.cellContainerView.layer.cornerRadius = 5
            cell.playRetryButton.tag = indexPath.row
            cell.deleteFromQueueButton.tag = indexPath.row
            switch uploadingImages[indexPath.row].state {
            case .fail:
                cell.playRetryButton.setImage(UIImage(named: "refresh_small"), for: .normal)
                cell.playRetryButton.isHidden = false
                cell.deleteFromQueueButton.isHidden = false
                cell.progressView.isHidden = true
                cell.bouncingProgressView.isHidden = true
                cell.bouncingProgressView.stopAnimate()
                cell.projectNameAndTimeLabel.text = "\(uploadingImages[indexPath.row].projectName)"
                cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(uploadingImages[indexPath.row].fileSize)) - FAILED\n(Tap to retry)"
//                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewFailReason(uploadingImages[indexPath.row].failCode as Any)))
//                cell.cellContainerView.addGestureRecognizer(tapGesture)
            case .waiting:
                //TODO: need to make progress bounce here
                cell.playRetryButton.setImage(UIImage(named: "play"), for: .normal)
                cell.progressView.isHidden = true
                cell.bouncingProgressView.isHidden = false
                cell.bouncingProgressView.startAnimate()
                cell.playRetryButton.isHidden = false
                cell.deleteFromQueueButton.isHidden = false
                cell.projectNameAndTimeLabel.text = "\(uploadingImages[indexPath.row].projectName)"
                cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(uploadingImages[indexPath.row].fileSize)) (0 kb/s)"
            case .inProgress:
                cell.progressView.isHidden = false
                cell.bouncingProgressView.isHidden = true
                cell.bouncingProgressView.stopAnimate()
                cell.playRetryButton.isHidden = true
                cell.deleteFromQueueButton.isHidden = false
                cell.projectNameAndTimeLabel.text = "\(images[indexPath.row].projectName)"
                if images[indexPath.row].estimatedTime != -1 {
                   cell.projectNameAndTimeLabel.text = "\(uploadingImages[indexPath.row].projectName) - \(uploadingImages[indexPath.row].estimatedTime)s"
                }
                cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(uploadingImages[indexPath.row].fileSize)) (\(uploadingImages[indexPath.row].speed) kb/s)"
            default:
                cell.playRetryButton.isHidden = true
                cell.deleteFromQueueButton.isHidden = true
                cell.progressView.isHidden = true
                cell.projectNameAndTimeLabel.text = "\(uploadingImages[indexPath.row].projectName)"
                cell.sizeAndSpeedLabel.text = ""
            }
            cell.photoImage.loadImage(identifier: uploadingImages[indexPath.row].localIdentifier)
            cell.progressView.progress = uploadingImages[indexPath.row].progress
           
           
            return cell
        case tableView2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UploadedCellIdentifier", for: indexPath) as! CompletedUploadsTableViewCell
            let uploadedImages = images.filter({$0.state == .done})
            cell.photoImage.loadImage(identifier: uploadedImages[indexPath.row].localIdentifier)
            cell.showRemoveButton.tag = indexPath.row
            cell.removeButton.tag = indexPath.row
            cell.showRemoveButton.isHidden = uploadedImages[indexPath.row].showRemoveFlag
            cell.removeButton.isHidden = !cell.showRemoveButton.isHidden
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YY"
            let myDate = formatter.string(from: uploadedImages[indexPath.row].date)
            formatter.dateFormat = "HH:mma"
            let myTime = formatter.string(from: uploadedImages[indexPath.row].date)
            cell.sizeAndDate.text = "\(myTime)          \(myDate)"
            cell.projectNameLabel.text = "\(uploadedImages[indexPath.row].projectName)\n\(converByteToHumanReadable(uploadedImages[indexPath.row].fileSize))"
            return cell
        default:
            return UITableViewCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let list = images.filter({$0.state != .done})
        if tableView == tableView1, list.count > indexPath.row , list[indexPath.row].state == .fail {
            if !alertAlreadyDisplayed {
                showErrorMessage(errorCode: list[indexPath.row].failCode)
            }
            
        }
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return section == 1 ? "Completed Uploads" : ""
//    }
//    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        view.tintColor = UIColor(hexString: "#545454")
//        view.isOpaque = true//.clear //
//        //view.backgroundColor = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1)
//        let header = view as! UITableViewHeaderFooterView
//        header.textLabel?.textColor = UIColor.white
//        header.textLabel?.textAlignment = .center
//
//        let headerFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body) //UIFont(name:  (header.textLabel?.font.fontName)!, size: 32) {//header.textLabel?.font
//        header.textLabel?.font = headerFont.withSize(24)
//        var lineExist = false
//        for subview in view.subviews {
//            if subview.frame.height == 1 {
//                lineExist = true
//                break
//            }
//        }
//        if !lineExist {
//            let lineView = UIView(frame: CGRect(x: 0, y: view.frame.height / 6, width: view.frame.width, height: 1))
//            lineView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
//            view.addSubview(lineView)
//        }
//    }
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        if section == 1 {
//            return 70
//        } else {
//            return 0
//        }
//    }

    //MARK: - update uploading progress
    @objc func updateProgressAndReloadData(localIdentifier: String, progress: CFloat, speed: Int, estimatedTime: Int){
        //IF localIdentifier is in progresss update progress else find next localidentifier and start uploading
        for imagesUnloaded in images {
            if imagesUnloaded.localIdentifier == localIdentifier {
                if imagesUnloaded.state == .inProgress{
                    imagesUnloaded.progress = progress//currentTime / MAX
                    imagesUnloaded.state = ImageForUpload.State.inProgress
                    imagesUnloaded.estimatedTime = estimatedTime
                    imagesUnloaded.speed = speed
                    break
                } else {
//                    for image in images {
//                        if image.state == ImageForUpload.State.waiting {
//                            currentUploadingLocalIdentifier = image.localIdentifier
//                            startUploadingOneByOne()
//                            //setStateOfImage(withIdentifier: currentUploadingLocalIdentifier, state: .inProgress)
//                            //prepareUploadPhoto(localIdentifier: currentUploadingLocalIdentifier)
//                            break
//                        }
//                    }
                    break
                }
            }
        }
        self.tableView1.reloadData()
    
    }
    
    
    
    //MARK: load full image
    func loadImage(identifier: String!) -> UIImage! {
        var loadedImage : UIImage! = nil
        let hiddenIdentifiers = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: [identifier])
        if hiddenIdentifiers.count > 0 {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let imagePath: String = path.appending("/\(identifier!)")
            if FileManager.default.fileExists(atPath: imagePath),
                let imageData: Data = FileManager.default.contents(atPath: imagePath),  //try? Data(contentsOf: imageUrl),
                let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
                loadedImage = image
            }
        } else {
            //This will fetch all the assets in the collection
            let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier!] , options: nil)
            //print(assets)
            
            let imageManager = PHCachingImageManager()
            //Enumerating objects to get a chached image - This is to save loading time
            
            assets.enumerateObjects{(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                //print(count)
            
                if object is PHAsset {
                    let asset = object as! PHAsset
                    //                print(asset)
                   //asset.mediaType
                    //let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    //PHAssetResource.assetResources(for: asset).first?.originalFilename
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .opportunistic
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    options.resizeMode = PHImageRequestOptionsResizeMode.exact
                    
                    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFit, options: options, resultHandler: {
                        (image, info) -> Void in
                        print(info!)
                        loadedImage = image
                        //image?.save(image: image!, imageName: asset.localIdentifier)
                        /* The image is now available to us */
                        
                    })
                }
            }
        }
        return loadedImage
    }
    
    
    
}
extension UIImageView {
    //MARK: - Loading image
    func loadImage(identifier: String!) {
        
        let hiddenIdentifiers = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: [identifier])
        if hiddenIdentifiers.count > 0 {
            let imageSize = CGSize(width: 100, height: 100)
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let imagePath: String = path.appending("/\(identifier!)")
            if FileManager.default.fileExists(atPath: imagePath),
                let imageData: Data = FileManager.default.contents(atPath: imagePath),  //try? Data(contentsOf: imageUrl),
                let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
                self.image = image.resizeImage(targetSize: imageSize)
            }
        } else {
            //This will fetch all the assets in the collection
            let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier!] , options: nil)
            //print(assets)
            
            let imageManager = PHCachingImageManager()
            //Enumerating objects to get a chached image - This is to save loading time
            
            assets.enumerateObjects{(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                //print(count)
                if object is PHAsset {
                    let asset = object as! PHAsset
                    //                print(asset)
                    
                    //let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    let imageSize = CGSize(width: 100, height: 100)
                    
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .opportunistic
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    options.resizeMode = PHImageRequestOptionsResizeMode.exact
                    
                    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFit, options: options, resultHandler: {
                        (image, info) -> Void in
                        //print(info!)
                        self.image = image
                        //image?.save(image: image!, imageName: asset.localIdentifier)
                        /* The image is now available to us */
                        
                    })
                }
            }
        }
        
    }
}

//MARK: - LOADING SAVING IMAGES in documentDirectory
//extension UploadsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//
//        //obtaining saving path
//        let fileManager = FileManager.default
//        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
//        let imagePath = documentsPath?.appendingPathComponent("image.jpg")
//        print(imagePath ?? "N0 imagePath found")
//        // extract image from the picker and save it
//        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
//
//            let imageData = pickedImage.jpegData(compressionQuality: 0.75)
//            try! imageData?.write(to: imagePath!)
//        }
//
//        let identifier = (info[UIImagePickerController.InfoKey.phAsset] as? PHAsset)?.localIdentifier
//        print(identifier!)
//        self.dismiss(animated: true, completion: nil)
//    }
//}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

