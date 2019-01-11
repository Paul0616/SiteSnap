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
        testStartUpload()
    }
    
    @IBAction func onBack(_ sender: Any) {
        
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
        return images.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoUploadCellIdentifier", for: indexPath) as! UploadsTableViewCell
        cell.cellContainerView.layer.cornerRadius = 5
        //cell.textLabel?.textColor = UIColor.white
       
        cell.buttonAccessory.setImage(accesoryView[indexPath.row % 3].image, for: .normal)
        cell.projectNameAndTimeLabel.text = "\(images[indexPath.section][indexPath.row].projectName) - \(images[indexPath.section][indexPath.row].estimatedTime)s"
        cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(images[indexPath.section][indexPath.row].fileSize)) (\(images[indexPath.section][indexPath.row].speed) kb/s)"
        cell.photoImage.loadImage(identifier: images[indexPath.section][indexPath.row].localIdentifier)
        cell.progressView.progress = images[indexPath.section][indexPath.row].progress
        return cell
    }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 126
//    }
    
    
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 5
//    }
    let MAX: CFloat = 10.0
    var currentTime: CFloat = 0.0
    func testStartUpload() {
        
        perform(#selector(updateProgress), with: images[0][0].localIdentifier, afterDelay: 1)
    }
    @objc func updateProgress(localIdentifier: String){
        currentTime = currentTime + 1
       
        for imagesUnloaded in images[0] {
            if imagesUnloaded.localIdentifier == localIdentifier {
                imagesUnloaded.progress = currentTime / MAX
                break
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        if currentTime < MAX {
            perform(#selector(updateProgress), with: localIdentifier, afterDelay: 1)
        } else {
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
                    break
                }
                i = i + 1
            }
        }
    }
    func makeImageDone(){
        for imagesUnloaded in images[0] {
            
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
            print(count)
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

