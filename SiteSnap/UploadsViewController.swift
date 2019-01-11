//
//  UploadsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 09/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit
import Photos

class UploadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var images = [[ImageForUpload]]()
    let accesoryView = [UIImageView(image: UIImage(named: "cancel-80px")),
                        UIImageView(image: UIImage(named: "autorenew-80px")),
                        UIImageView(image: UIImage(named: "done-80px"))]
    
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var uploadingProcessRunning: Bool = false
   
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
        titleButton.layer.cornerRadius = 6
        titleButton.isEnabled = false
        // Do any additional setup after loading the view.
        let photos = PhotoHandler.fetchAllObjects()!
        var unprocessedImages = [ImageForUpload]()
        for photo in photos {
            let image = ImageForUpload(localIdentifier: photo.localIdentifierString!, projectName: "WESTGATE TUNNEL", estimatedTime: 25.0, fileSize: photo.fileSize, speed: 345, progress: 0, state: ImageForUpload.State.waiting)
            unprocessedImages.append(image!)
        }
        images.append(unprocessedImages)
        uploadingProcessRunning = true
        testStartUpload()
    }
    
    @IBAction func onBack(_ sender: Any) {
        
    }
    
    @IBAction func onClickDeleteFromQueue(_ sender: UIButton) {
        if images[0][sender.tag].state == .fail {
            showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", state: .waiting, tag: sender.tag)
        }
    }
    @IBAction func onClickAccesories(_ sender: UIButton) {
        if sender.tag < images[0].count { //that means tapped button is in first section (.waiting, .inProgress or .fail)
            if images[0][sender.tag].state == .inProgress {
                showAlert(alertMsg: "Ask user if he want to cancel upload", message: "Are you sure you want to cancel the upload of this photo?", state: .inProgress, tag: sender.tag)
            }
            if images[0][sender.tag].state == .waiting {
                showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", state: .waiting, tag: sender.tag)
            }
            if images[0][sender.tag].state == .fail {
                showAlert(alertMsg: "Ask user if he want to remove photo", message: "Are you sure you want to permanently cancel the upload of this photo? (this cannot be undone)", state: .fail, tag: sender.tag)
            }
        }
    }
    
    
    //MARK: - Alert
    private func showAlert(alertMsg: String, message: String, state: ImageForUpload.State, tag: Int){
        let messageToShow = NSLocalizedString(message, comment: alertMsg)
        let alertController = UIAlertController(title: "Please confirm choice", message: messageToShow, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Confirm cancel upload"),
                                                style: .default,
                                                handler: { action in
                                                    self.cancelUpload(state: state, tag: tag)
                                                }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Photo will continue to upload"),
                                                style: .cancel,
                                                handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func cancelUpload(state: ImageForUpload.State, tag: Int) {
        if state == .inProgress {
            images[0][tag].state = .fail
            currentTime = 0.0
        }
        if state == .fail {
            images[0][tag].state = .waiting
            currentTime = 0.0
        }
        if state == .waiting {
            if PhotoHandler.removePhoto(localIdentifier: images[0][tag].localIdentifier) {
                images[0].remove(at: tag)
            }
            if !uploadingProcessRunning {
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
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
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 126
//    }
    
    
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 5
//    }
    let MAX: CFloat = 10.0
    var currentTime: CFloat = 0.0
    var delay: TimeInterval = 0.2
    func testStartUpload() {
        perform(#selector(updateProgress), with: images[0][0].localIdentifier, afterDelay: delay)
    }
    
    @objc func updateProgress(localIdentifier: String){
        currentTime = currentTime + 1
        //var currentIdentifier = localIdentifier
        var shouldReturn = false
        for imagesUnloaded in images[0] {
            
            if imagesUnloaded.localIdentifier == localIdentifier {
                if imagesUnloaded.state != .fail {
                    imagesUnloaded.progress = currentTime / MAX
                    imagesUnloaded.state = ImageForUpload.State.inProgress
                    break
                } else {
                    for image in images[0] {
                        if image.state != ImageForUpload.State.fail {
                            shouldReturn = true
                            perform(#selector(updateProgress), with: image.localIdentifier, afterDelay: delay)
                            break
                        }
                    }
                    break
                }
            }
        }
        
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        if shouldReturn {
            return
        }
        
        if currentTime < MAX {
            perform(#selector(updateProgress), with: localIdentifier, afterDelay: delay)
        } else {
            makeImageDone(localIdentifier: localIdentifier)
            if images[0].count > 0 {
                var nextLocalIdentifier: String!
                for image in images[0] {
                    if image.state != ImageForUpload.State.fail {
                        nextLocalIdentifier = image.localIdentifier
                        currentTime = 0.0
                        break
                    }
                }
                if nextLocalIdentifier != nil {
                    perform(#selector(updateProgress), with: nextLocalIdentifier, afterDelay: delay)
                } else {
                    uploadingProcessRunning = false
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
extension UIImage {
    func load(image imageName: String) -> UIImage! {
        // declare image location
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
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

    func save(image: UIImage, imageName: String) -> Bool {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        // image has not been created yet: create it, store it, return it

        if (try? image.pngData()?.write(to: imageUrl)) != nil {
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

