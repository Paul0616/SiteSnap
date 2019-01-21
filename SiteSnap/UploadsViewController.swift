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

class UploadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    var images = [[ImageForUpload]]()
    let accesoryView = [UIImageView(image: UIImage(named: "cancel-80px")),
                        UIImageView(image: UIImage(named: "autorenew-80px")),
                        UIImageView(image: UIImage(named: "done-80px"))]
    
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var uploadingProcessRunning: Bool = false
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var time: Date!
    var currentUploadingLocalIdentifier: String!
    var sessionManager: SessionManager!
    
    //MARK: - view control load
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
        titleButton.layer.cornerRadius = 6
        titleButton.isEnabled = false
        // Do any additional setup after loading the view.
        let photos = PhotoHandler.fetchAllObjects()!
        var unprocessedImages = [ImageForUpload]()
        let currentProjectName = UserDefaults.standard.value(forKey: "currentProjectName")
        for photo in photos {
            let image = ImageForUpload(localIdentifier: photo.localIdentifierString!, projectName: currentProjectName as! String, estimatedTime: -1, fileSize: photo.fileSize, speed: 0, progress: 0, state: ImageForUpload.State.waiting)
            unprocessedImages.append(image!)
        }
        images.append(unprocessedImages)
        uploadingProcessRunning = true
        //testStartUpload(localIdentifier: images[0][0].localIdentifier)
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
            print("USER = CURRENT USER = \(String(describing: self.user?.username))")
        }
        currentUploadingLocalIdentifier = images[0][0].localIdentifier
        if images[0].count > 0  {
            prepareUploadPhoto(localIdentifier: currentUploadingLocalIdentifier)
        }
        //
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if images[0].count == 0 {
                print("disapear")
        }
    }
    
    //MARK: - UI Buttons click
    @IBAction func onBack(_ sender: Any) {
        
    }
    
    @IBAction func onClickDeleteFromQueue(_ sender: UIButton) {
        let localIdentifier = images[0][sender.tag].localIdentifier
        let state = images[0][sender.tag].state
        if state == .fail {
            showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", state: .waiting, localIdentifier: localIdentifier)
        }
    }
    @IBAction func onClickAccesories(_ sender: UIButton) {
        let localIdentifier = images[0][sender.tag].localIdentifier
        let state = images[0][sender.tag].state
        if sender.tag < images[0].count { //that means tapped button is in first section (.waiting, .inProgress or .fail)
            if state == .inProgress {
                showAlert(alertMsg: "Ask user if he want to cancel upload", message: "Are you sure you want to cancel the upload of this photo?", state: .inProgress, localIdentifier: localIdentifier)
            }
            if state == .waiting {
                showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", state: .waiting, localIdentifier: localIdentifier)
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
    private func removeImage(withIdentifier identifier: String) {
        if images[0].count > 0 {
            for index in 0...images[0].count-1 {
                if images[0][index].localIdentifier == identifier {
                    images[0].remove(at: index)
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
    }
    
    //MARK; - Prepare upload photo
    func prepareUploadPhoto(localIdentifier: String) {
        //let index = getIndexOfImage(withIdentifier: localIdentifier)
        let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as! String
        let latitude = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)?.latitude
        let longitude = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)?.longitude
        var comment: String = ""
        if let individualComment = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)?.individualComment {
            comment = individualComment
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        var myDate: String = formatter.string(from: Date())
        if let createdDate = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)?.createdDate {
            myDate = formatter.string(from:  createdDate as Date)
        }
        var tagIds:String = ""
        if let tags = PhotoHandler.getSpecificPhoto(localIdentifier: localIdentifier)?.tags {
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
        let parameters = [
            "forProject": currentProjectId,
            "gpsLocation": gpsLocation,
            "isPrivate": "false",
            "debug": "true",
            "comment": comment,
            "photoDate": myDate,
            "tags": tagIds,
            "appVersion": "1.0",
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
    private func showAlert(alertMsg: String, message: String, state: ImageForUpload.State, localIdentifier: String){
        let messageToShow = NSLocalizedString(message, comment: alertMsg)
        let alertController = UIAlertController(title: "Please confirm choice", message: messageToShow, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Confirm cancel upload"),
                                                style: .default,
                                                handler: { action in
                                                    self.changeState(fromState: state, localIdentifier: localIdentifier)
                                                }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Photo will continue to upload"),
                                                style: .cancel,
                                                handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - change state of an image
    private func changeState(fromState state: ImageForUpload.State, localIdentifier: String) {
        
        let state = getStateOfImage(withIdentifier: localIdentifier)
        switch state {
            case .inProgress:
               cancelUploadRequest(request: .UploadTask)
               setStateOfImage(withIdentifier: localIdentifier, state: .fail)
            break
            
            case .waiting:
                if PhotoHandler.removePhoto(localIdentifier: localIdentifier) {
                    removeImage(withIdentifier: localIdentifier)
                }
                if !uploadingProcessRunning {
                    prepareUploadPhoto(localIdentifier: localIdentifier)
                }
            break
            
            case .done:
            break
            
            case .fail:
                setStateOfImage(withIdentifier: localIdentifier, state: .waiting)
                if !uploadingProcessRunning {
                    prepareUploadPhoto(localIdentifier: localIdentifier)
                }
            break
            
            case .unknown:
            break
        }
    }
    
    //MARK:- URLSessionDelegate functions
//    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64){
//        //update progress view
//        let elapsedtime = abs(time.timeIntervalSinceNow)
//        let estimatedSpeed = Int(Double(totalBytesSent) / (elapsedtime * 1024))
//
//        let procent = CFloat(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
//        let remainingTime = round(Double((totalBytesExpectedToSend - totalBytesSent)) / Double(estimatedSpeed * 1024))
//        updateProgress(localIdentifier: currentUploadingLocalIdentifier, progress: procent, speed: estimatedSpeed, estimatedTime: Int(remainingTime))
//        print("\(estimatedSpeed) kb/
//        print("\(procent)")
//        print("\(remainingTime) s")
//        print("\(bytesSent) - \(totalBytesSent) - \(totalBytesExpectedToSend)")
//    }
   

    //MARK: - POST request
//    func postRequest(identifier: String, image: UIImage, parameters: Parameters) {
//        guard let mediaImage = Media(withImage: image, forKey: "image") else { return }
//        guard let url = URL(string: siteSnapBackendHost + "photo") else { return }
//        var request = URLRequest(url: url)
//        let boundary = generateBoundary()
//        request.httpMethod = "POST"
//        request.setValue("multipart/form-data;  boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        let tokenString = "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String)!
//        request.addValue(tokenString, forHTTPHeaderField: "Authorization")
//        request.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
//
//
//
//        let dataBody = createDataBody(withParameters: parameters, media: mediaImage, boundary: boundary)
//        request.httpBody = dataBody
//        let configuration = URLSessionConfiguration.default
//        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)//URLSession.shared
//        time = Date()
//
//        session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
//            if let httpResponse = response as? HTTPURLResponse {
//                print(httpResponse.statusCode)
//                self.uploadingProcessRunning = false
//                if httpResponse.statusCode != 200 || httpResponse.statusCode != 201 {
//                    let state = self.getStateOfImage(withIdentifier: identifier)
//                    self.changeState(fromState: state, localIdentifier: identifier)
//                    self.updateProgress(localIdentifier: identifier, progress: 0, speed: 0, estimatedTime: -1)
//                } else {
//                    self.makeImageDone(localIdentifier: identifier)
//                }
//
//            }
//
//        }).resume()
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
        time = Date()
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = TimeInterval(15.0)
        configuration.timeoutIntervalForRequest = TimeInterval(15.0)
        
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
                        self.uploadingProcessRunning = false
                        if let error = response.error {
                            print(error.localizedDescription)
                            let state = self.getStateOfImage(withIdentifier: identifier)
                            self.changeState(fromState: state, localIdentifier: identifier)
                            self.updateProgress(localIdentifier: identifier, progress: 0, speed: 0, estimatedTime: -1)
                        } else {
                            print(response.response?.statusCode as Any)
                            self.makeImageDone(localIdentifier: identifier)
                            self.tableView.reloadData()
                        }
                    }
                    .uploadProgress { progress in
                        print(progress.estimatedTimeRemaining ?? 0)
                        print(progress.fractionCompleted)
                        print("\(progress.completedUnitCount) - \(progress.totalUnitCount)")
                        let elapsedtime = abs(self.time.timeIntervalSinceNow)
                        let estimatedSpeed = Int(Double(progress.completedUnitCount) / (elapsedtime * 1024))
                        
                        let remainingTime = round(Double((progress.totalUnitCount - progress.completedUnitCount)) / Double(estimatedSpeed * 1024))
                        self.updateProgress(localIdentifier: identifier, progress: CFloat(progress.fractionCompleted), speed: estimatedSpeed, estimatedTime: Int(remainingTime))
                    }
            case .failure(let error):
                print("Error in upload: \(error.localizedDescription)")
                let state = self.getStateOfImage(withIdentifier: identifier)
                self.changeState(fromState: state, localIdentifier: identifier)
                self.updateProgress(localIdentifier: identifier, progress: 0, speed: 0, estimatedTime: -1)
                //onError?(error)
            }
        }
    }
    
    enum CancelRequestType: String {
        case DownloadTask = "DownloadTask"
        case DataTask = "DataTask"
        case UploadTask = "UploadTask"
        case ZeroTask = "Zero"
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
    
//    private func generateBoundary() -> String {
//        return "Boundary-\(NSUUID().uuidString))"
//    }
    
    
    typealias Parameters = [String: String]
   
//    private func createDataBody(withParameters params: Parameters?, media: Media?, boundary: String) -> Data {
//        var body = Data()
//        let lineBreak = "\r\n"
//        if let parameters = params {
//            for (key, value) in parameters {
//                body.append("--\(boundary + lineBreak)")
//                body.append("Content-Disposition:form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
//                body.append("\(value + lineBreak)")
//                //body.append("\(value)")
//            }
//        }
//        if let media = media {
//            body.append("--\(boundary + lineBreak)")
//            body.append("Content-Disposition:form-data; name=\"\(media.key)\"; filename=\"\(media.filename)\"\(lineBreak)")
//            body.append("Content-Type: \(media.mimeType + lineBreak + lineBreak)")
//            body.append(media.data)
//            body.append(lineBreak)
//        }
//
//        body.append("--\(boundary)--\(lineBreak)")
//        return body
//    }
    
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
                cell.projectNameAndTimeLabel.text = "\(images[indexPath.section][indexPath.row].projectName) - \(images[indexPath.section][indexPath.row].estimatedTime)s"
                cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(images[indexPath.section][indexPath.row].fileSize)) (\(images[indexPath.section][indexPath.row].speed) kb/s)"
            }
        
        
        cell.photoImage.loadImage(identifier: images[indexPath.section][indexPath.row].localIdentifier)
        cell.progressView.progress = images[indexPath.section][indexPath.row].progress
        print(images[indexPath.section][indexPath.row].progress)
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
    @objc func updateProgress(localIdentifier: String, progress: CFloat, speed: Int, estimatedTime: Int){
        //currentTime = currentTime + 1
        //var currentIdentifier = localIdentifier
        var shouldReturn = false
        for imagesUnloaded in images[0] {
            if imagesUnloaded.localIdentifier == localIdentifier {
                if imagesUnloaded.state != .fail {
                    imagesUnloaded.progress = progress//currentTime / MAX
                    imagesUnloaded.state = ImageForUpload.State.inProgress
                    imagesUnloaded.estimatedTime = estimatedTime
                    imagesUnloaded.speed = speed
                    break
                } else {
                    for image in images[0] {
                        if image.state != ImageForUpload.State.fail {
                            shouldReturn = true
                            currentUploadingLocalIdentifier = image.localIdentifier
                            prepareUploadPhoto(localIdentifier: currentUploadingLocalIdentifier)
                            break
                        }
                    }
                    break
                }
            }
        }
        
        
        //DispatchQueue.main.async {
            self.tableView.reloadData()
        //}
        if shouldReturn {
            return
        }
    }
    
    
    
    //MARK: load full image
    func loadImage(identifier: String!) -> UIImage! {
        
        //This will fetch all the assets in the collection
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier!] , options: nil)
        //print(assets)
        
        let imageManager = PHCachingImageManager()
        //Enumerating objects to get a chached image - This is to save loading time
        var loadedImage : UIImage! = nil
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
        return loadedImage
    }
    
   
    
}
extension UIImageView {
    //MARK: - Loading image
    func loadImage(identifier: String!) {
        
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

//MARK: - LOADING SAVING IMAGES in documentDirectory
extension UploadsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //obtaining saving path
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let imagePath = documentsPath?.appendingPathComponent("image.jpg")
        print(imagePath ?? "N0 imagePath found")
        // extract image from the picker and save it
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            let imageData = pickedImage.jpegData(compressionQuality: 0.75)
            try! imageData?.write(to: imagePath!)
        }
        
        let identifier = (info[UIImagePickerController.InfoKey.phAsset] as? PHAsset)?.localIdentifier
        print(identifier!)
        self.dismiss(animated: true, completion: nil)
    }
}

extension UIImage {
    
    func loadFromDocumentDirectory(image imageName: String) -> UIImage! {
        // declare image location
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).jpg"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)

        // check if the image is stored already
        if FileManager.default.fileExists(atPath: imagePath),
            let imageData: Data = try? Data(contentsOf: imageUrl),
            let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
            return image
        } else {
            return nil
        }
    }

    func saveToDocumentDirectory(image: UIImage, imageName: String) -> Bool {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).jpg"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        // image has not been created yet: create it, store it, return it

        if (try? image.jpegData(compressionQuality: 1.0)?.write(to: imageUrl)) != nil {
            
            return true
        } else {
            return false
        }

    }
    
    func remove(imageName: String) -> Bool {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
        do {
            try FileManager.default.removeItem(atPath: imagePath)
        } catch let error as NSError {
            print(error.debugDescription)
            return false
        }
        return true
    }
}
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
