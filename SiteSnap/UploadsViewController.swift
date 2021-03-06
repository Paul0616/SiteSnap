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
class UploadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    var images = [[ImageForUpload]]()
    let accesoryView = [UIImageView(image: UIImage(named: "cancel")),
                        UIImageView(image: UIImage(named: "autorenew")),
                        UIImageView(image: UIImage(named: "done"))]
    
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var uploadingProcessRunning: Bool = false
    var appDidEnterBackground: Bool = false
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var time: Date!
    var currentUploadingLocalIdentifier: String!
    var sessionManager: SessionManager!
    var timer: Timer!
    
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
        
        backButton.layer.cornerRadius = 20
        titleButton.layer.cornerRadius = 6
        titleButton.isEnabled = false
        // Do any additional setup after loading the view.
        var photos = PhotoHandler.fetchAllObjects()!
        for photo in photos {
            let img = loadImage(identifier: photo.localIdentifierString)
            if let data = img!.jpegData(compressionQuality: 1.0) {
                PhotoHandler.updateFileSize(localIdentifier: photo.localIdentifierString!, size: Int64(data.count))
            }
        }
        photos = PhotoHandler.fetchAllObjects()!
        var unprocessedImages = [ImageForUpload]()
        let currentProjectName = UserDefaults.standard.value(forKey: "currentProjectName")
        
        for photo in photos {
           
            let image = ImageForUpload(localIdentifier: photo.localIdentifierString!, projectName: currentProjectName as! String, estimatedTime: -1, fileSize: photo.fileSize, speed: 0, progress: 0, state: ImageForUpload.State.waiting)
            unprocessedImages.append(image!)
        }
        images.append(unprocessedImages)
        
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
            print("USER = CURRENT USER = \(String(describing: self.user?.username))")
        }
        currentUploadingLocalIdentifier = images[0][0].localIdentifier
        uploadingProcessRunning = true
        startUploadingOneByOne()
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if images[0].count == 0 {
                print("disapear")
        }
    }
    //MARK: - Callback observers
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        print("App is active with notification \(notification.name.rawValue)")
        if NetworkState.isConnected() {
            uploadingProcessRunning = true
            appDidEnterBackground = false
            startUploadingOneByOne()
        } else {
          timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(retryUpload), userInfo: nil, repeats: false)
            
        }
    }
    @objc func retryUpload(){
        uploadingProcessRunning = true
        appDidEnterBackground = false
        startUploadingOneByOne()
        timer.invalidate()
    }
    @objc func applicationDidEnterBackground(notification: NSNotification) {
        print("App is enter in background notification \(notification.name.rawValue)")
        uploadingProcessRunning = false
        appDidEnterBackground = true
        failAllWaitingImages()
    }
    //MARK: - UI Buttons click
    @IBAction func onBack(_ sender: Any) {
        
    }
    
    @IBAction func onClickDeleteFromQueue(_ sender: UIButton) {
        let localIdentifier = images[0][sender.tag].localIdentifier
        let state = images[0][sender.tag].state
        if state == .fail {
            showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", state: .waiting, localIdentifier: localIdentifier, listRowNumberCheck: images[0].count)
        }
    }
    @IBAction func onClickAccesories(_ sender: UIButton) {
        let localIdentifier = images[0][sender.tag].localIdentifier
        let state = images[0][sender.tag].state
        if sender.tag < images[0].count { //that means tapped button is in first section (.waiting, .inProgress or .fail)
            if state == .inProgress {
                showAlert(alertMsg: "Ask user if he want to cancel upload", message: "Are you sure you want to cancel the upload of this photo?", state: .inProgress, localIdentifier: localIdentifier, listRowNumberCheck: images[0].count)
            }
            if state == .waiting {
                showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", state: .waiting, localIdentifier: localIdentifier, listRowNumberCheck: images[0].count)
                print(images[0].count)
                
            }
            if state == .fail {
                changeState(fromState: state, localIdentifier: localIdentifier)
            }
        }
    }
    
    
    //MARK: - get index of current image
    private func getStateOfImage(withIdentifier identifier: String) -> ImageForUpload.State {
    
        if images[0].count > 0 {
            for image in images[0] {
                if image.localIdentifier == identifier {
                    return image.state
                }
            }
        }
        return .unknown
    }
    
    private func setStateOfImage(withIdentifier identifier: String, state: ImageForUpload.State){
        if images[0].count > 0 {
            for image in images[0] {
                if image.localIdentifier == identifier {
                    image.state = state
                }
            }
        }
    }
    private func startUploadingOneByOne(){
        if images[0].count > 0  {
            setStateOfImage(withIdentifier: currentUploadingLocalIdentifier, state: .inProgress)
            prepareUploadPhoto(localIdentifier: currentUploadingLocalIdentifier)
        }
    }
    private func failAllWaitingImages(){
        if let _ = sessionManager{
            cancelUploadRequest(request: .UploadTask)
        }
        if images[0].count > 0 {
            for image in images[0] {
                image.state = .waiting
            }
        }
       // self.tableView.reloadData()
    }
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
    
    private func removeImageFromTableView(withIdentifier identifier: String) {
        if images[0].count > 0 {
            print(identifier)
            print(images[0].count)
            for index in 0...images[0].count-1 {
                if images[0][index].localIdentifier == identifier {
                    images[0].remove(at: index)
                    break
                }
            }
        }
    }
    
    private func makeImageDone(localIdentifier: String){
        var i: Int = 0
        for imagesUnloaded in images[0] {
            if imagesUnloaded.localIdentifier == localIdentifier {
                imagesUnloaded.state = ImageForUpload.State.done
                if images.count > 1 {
                    images[0].remove(at: i)
                    images[1].append(imagesUnloaded)
                } else {
                    images[0].remove(at: i)
                    images.append([imagesUnloaded])
                }
                images[1].last!.date = Date()
                
                break
            }
            i = i + 1
        }
        if PhotoHandler.updateSuccessfulyUploaded(localIdentifier: localIdentifier, succsessfuly: true) {
            print("was signaled upload in database")
        }
        
        if images[0].count > 0 {
            currentUploadingLocalIdentifier = images[0][0].localIdentifier
            updateProgressAndReloadData(localIdentifier: currentUploadingLocalIdentifier, progress: 0, speed: 0, estimatedTime: -1)
        } else {
            tableView.reloadData()
        }
        
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
            uploadingProcessRunning = true
            //postRequest(identifier: localIdentifier, image: image, parameters: parameters)
            postRequestWith(identifier: localIdentifier, image: image, parameters: parameters)
        }
    }
    
    //MARK: - Alert
    private func showAlert(alertMsg: String, message: String, state: ImageForUpload.State, localIdentifier: String, listRowNumberCheck: Int?){
        let messageToShow = NSLocalizedString(message, comment: alertMsg)
        let alertController = UIAlertController(title: "Please confirm choice", message: messageToShow, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Confirm cancel upload"),
                                                style: .default,
                                                handler: { action in
                                                    if let parameter = listRowNumberCheck {
                                                        if parameter == self.images[0].count && state == .waiting {
                                                            self.changeState(fromState: state, localIdentifier: localIdentifier)
                                                        }
                                                        if parameter == self.images[0].count && state == .inProgress {
                                                            self.cancelUploadRequest(request: .UploadTask)
                                                        }
                                                    }
                                                }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Photo will continue to upload"),
                                                style: .cancel,
                                                handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - change state of an image
    private func changeState(fromState state: ImageForUpload.State, localIdentifier: String) {
        
       // let state = getStateOfImage(withIdentifier: localIdentifier)
        switch state {
            case .inProgress:
              // cancelUploadRequest(request: .UploadTask)
               setStateOfImage(withIdentifier: localIdentifier, state: .fail)
               updateProgressAndReloadData(localIdentifier: localIdentifier, progress: 0, speed: 0, estimatedTime: -1)
            break
            
            case .waiting:
                if PhotoHandler.removePhoto(localIdentifier: localIdentifier) {
                    removeImageFromTableView(withIdentifier: localIdentifier)
                    deleteImageIfHidden(localIdentifier: localIdentifier)
                    tableView.reloadData()
                }
            break
            
            case .done:
            break
            
            case .fail:
                setStateOfImage(withIdentifier: localIdentifier, state: .waiting)
                if !uploadingProcessRunning {
                    setStateOfImage(withIdentifier: localIdentifier, state: .inProgress)
                    prepareUploadPhoto(localIdentifier: localIdentifier)
                }
            break
            
            case .unknown:
            break
        }
    }
    
   
   
    
    func postRequestWith(identifier: String, image: UIImage?, parameters: Parameters, onCompletion: ((JSON?) -> Void)? = nil, onError: ((Error?) -> Void)? = nil){
        var data: Data!
        var fileName: String = "image.jpg"
        var mimeType: String = "image/jpg"
        guard let url = URL(string: siteSnapBackendHost + "photo") else { return }
        if let image = image {
            guard let mediaImage = Media(withImage: image, forKey: "image") else { return }
            data = mediaImage.data
           // let bcf = ByteCountFormatter()
           // let s = bcf.string(fromByteCount: Int64(data.count)) //  Int64(bitPattern: UInt64(data.count))
            //PhotoHandler.updateFileSize(localIdentifier: identifier, size: Int64(data.count))
            fileName = mediaImage.filename
            mimeType = mediaImage.mimeType
        }
        
        let tokenString = "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String)!
        let headers: HTTPHeaders = [
            "Authorization": tokenString,
            "Content-type": "multipart/form-data"
        ]
        time = Date()
        
        let configuration = URLSessionConfiguration.default
        //configuration.timeoutIntervalForResource = TimeInterval(10.0)
        configuration.timeoutIntervalForRequest = TimeInterval(20.0)
        
        sessionManager = Alamofire.SessionManager(configuration: configuration)
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
                    .response { response in
                        if let error = response.error {
                            self.uploadingProcessRunning = false
                            print(error.localizedDescription)
                            if !self.appDidEnterBackground  {
                                let state = self.getStateOfImage(withIdentifier: identifier)
                                self.changeState(fromState: state, localIdentifier: identifier)
                            }
                           
                        } else {
                            self.uploadingProcessRunning = false
                            print(response.response?.statusCode as Any)
                            self.makeImageDone(localIdentifier: identifier)

                        }
                       
                        
                       
                    }
                    .uploadProgress { progress in
                       
                        //print(progress.fractionCompleted)
                        //print("\(progress.completedUnitCount) - \(progress.totalUnitCount)")
                        let elapsedtime = abs(self.time.timeIntervalSinceNow)
                        let estimatedSpeed = Int(Double(progress.completedUnitCount) / (elapsedtime * 1024))
                        
                        let remainingTime = round(Double((progress.totalUnitCount - progress.completedUnitCount)) / Double(estimatedSpeed * 1024))
                        self.updateProgressAndReloadData(localIdentifier: identifier, progress: CFloat(progress.fractionCompleted), speed: estimatedSpeed, estimatedTime: Int(remainingTime))
                    }
            case .failure(let error):
                self.uploadingProcessRunning = false
                print("Error in upload: \(error.localizedDescription)")
                let state = self.getStateOfImage(withIdentifier: identifier)
                self.changeState(fromState: state, localIdentifier: identifier)

            }
        }
    }
    
    
    
    func cancelUploadRequest(request: CancelRequestType) {
        sessionManager.session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            switch request {
            case .DataTask:
                dataTasks.forEach { $0.cancel() }
                print("- - - Data task was canceled!")
            case .UploadTask:
                uploadTasks.forEach { $0.cancel() }
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
        return images.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images[section].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoUploadCellIdentifier", for: indexPath) as! UploadsTableViewCell
        cell.cellContainerView.layer.cornerRadius = 5
        //cell.textLabel?.textColor = UIColor.white
        if indexPath.section == 1 {
            cell.buttonAccessory.setImage(accesoryView[2].image, for: .normal)
            cell.progressView.isHidden = true
            cell.deleteFromQueueButton.isHidden = true
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YY"
            let myDate = formatter.string(from: images[indexPath.section][indexPath.row].date)
            formatter.dateFormat = "HH:mma"
            let myTime = formatter.string(from: images[indexPath.section][indexPath.row].date)
            
            cell.projectNameAndTimeLabel.text = "\(myTime)          \(myDate)"
            cell.sizeAndSpeedLabel.text = "\(images[indexPath.section][indexPath.row].projectName)\n\(converByteToHumanReadable(images[indexPath.section][indexPath.row].fileSize))"
        } else
            if images[indexPath.section][indexPath.row].state == ImageForUpload.State.fail {
                cell.buttonAccessory.setImage(accesoryView[1].image, for: .normal)
                cell.buttonAccessory.tag = indexPath.row
                cell.progressView.isHidden = true
                cell.deleteFromQueueButton.isHidden = false
                cell.projectNameAndTimeLabel.text = "\(images[indexPath.section][indexPath.row].projectName)"
                cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(images[indexPath.section][indexPath.row].fileSize)) - FAILED\n(Tap to retry)"
            } else {
                cell.buttonAccessory.setImage(accesoryView[0].image, for: .normal)
                cell.buttonAccessory.tag = indexPath.row
                cell.progressView.isHidden = false
                cell.deleteFromQueueButton.isHidden = true
                cell.projectNameAndTimeLabel.text = "\(images[indexPath.section][indexPath.row].projectName)"
                if images[indexPath.section][indexPath.row].estimatedTime != -1 {
                   cell.projectNameAndTimeLabel.text = "\(images[indexPath.section][indexPath.row].projectName) - \(images[indexPath.section][indexPath.row].estimatedTime)s"
                }
                cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(images[indexPath.section][indexPath.row].fileSize)) (\(images[indexPath.section][indexPath.row].speed) kb/s)"
            }
        
        
        cell.photoImage.loadImage(identifier: images[indexPath.section][indexPath.row].localIdentifier)
        cell.progressView.progress = images[indexPath.section][indexPath.row].progress
        //print(images[indexPath.section][indexPath.row].progress)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "Completed Uploads" : ""
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(hexString: "#545454")//UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1)
        view.isOpaque = true//.clear //
        //view.backgroundColor = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1)
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.textAlignment = .center
        
        let headerFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body) //UIFont(name:  (header.textLabel?.font.fontName)!, size: 32) {//header.textLabel?.font
        header.textLabel?.font = headerFont.withSize(24)
        var lineExist = false
        for subview in view.subviews {
            if subview.frame.height == 1 {
                lineExist = true
                break
            }
        }
        if !lineExist {
            let lineView = UIView(frame: CGRect(x: 0, y: view.frame.height / 6, width: view.frame.width, height: 1))
            lineView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
            view.addSubview(lineView)
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 70
        } else {
            return 0
        }
    }

    //MARK: - update uploading progress
    @objc func updateProgressAndReloadData(localIdentifier: String, progress: CFloat, speed: Int, estimatedTime: Int){
        //IF localIdentifier is in progresss update progress else find next localidentifier and start uploading
        for imagesUnloaded in images[0] {
            if imagesUnloaded.localIdentifier == localIdentifier {
                if imagesUnloaded.state == .inProgress{
                    imagesUnloaded.progress = progress//currentTime / MAX
                    imagesUnloaded.state = ImageForUpload.State.inProgress
                    imagesUnloaded.estimatedTime = estimatedTime
                    imagesUnloaded.speed = speed
                    break
                } else {
                    for image in images[0] {
                        if image.state == ImageForUpload.State.waiting {
                            currentUploadingLocalIdentifier = image.localIdentifier
                            startUploadingOneByOne()
                            //setStateOfImage(withIdentifier: currentUploadingLocalIdentifier, state: .inProgress)
                            //prepareUploadPhoto(localIdentifier: currentUploadingLocalIdentifier)
                            break
                        }
                    }
                    break
                }
            }
        }
        self.tableView.reloadData()
      
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

