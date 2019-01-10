//
//  UploadsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 09/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class UploadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var photos = [Photo]()
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
        titleButton.layer.cornerRadius = 6
        titleButton.isEnabled = false
        // Do any additional setup after loading the view.
        photos = PhotoHandler.fetchAllObjects()!
        
    }
    
    @IBAction func onBack(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
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
        return photos.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoUploadCellIdentifier", for: indexPath) as! UploadsTableViewCell
        cell.cellContainerView.layer.cornerRadius = 5
        //cell.textLabel?.textColor = UIColor.white
        let accesoryView = [UIImageView(image: UIImage(named: "cancel-80px")),
                            UIImageView(image: UIImage(named: "autorenew-80px")),
                            UIImageView(image: UIImage(named: "done-80px"))]
        //cell.accessoryView = accesoryView[indexPath.row % 3]
        cell.sizeAndSpeedLabel.text = "\(converByteToHumanReadable(photos[indexPath.row].fileSize)) (345 kb/s)"
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 132
    }
   
    
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 5
//    }
    
}

//MARK: - LOADING SAVING IMAGES in documentDirectory
//extension UIImage {
//    func load(image imageName: String) -> UIImage! {
//        // declare image location
//        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
//        let imageUrl: URL = URL(fileURLWithPath: imagePath)
//
//        // check if the image is stored already
//        if FileManager.default.fileExists(atPath: imagePath),
//            let imageData: Data = try? Data(contentsOf: imageUrl),
//            let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
//            return image
//        } else {
//            return nil
//        }
//    }
//
//    func save(image: UIImage, imageName: String) -> Bool {
//        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
//        let imageUrl: URL = URL(fileURLWithPath: imagePath)
//        // image has not been created yet: create it, store it, return it
//
//        if (try? image.pngData()?.write(to: imageUrl)) != nil {
//            return true
//        } else {
//            return false
//        }
//
//    }
//}

