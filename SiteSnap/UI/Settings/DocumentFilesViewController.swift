//
//  DocumentFilesViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14/02/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class DocumentFilesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var imagesDirectoryPath:String!
    var images:[UIImage]!
    var titles:[String]!
    @IBOutlet weak var back: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID", for: indexPath)
        cell.textLabel?.text = titles[indexPath.row]
        cell.imageView?.image = images[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let imagePath: String = imagesDirectoryPath.appending("/\(titles[indexPath.row])")
        do {
            try FileManager.default.removeItem(atPath: imagePath)
            refreshTable()
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    @IBAction func onTapBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        back.layer.cornerRadius = 20
        // Do any additional setup after loading the view.
        images = []
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        // Get the Document directory path
        let documentDirectorPath:String = paths[0]
        imagesDirectoryPath = documentDirectorPath
        // Create a new path for the new images folder
        refreshTable()
        //var objcBool:ObjCBool = true
        //let isExist = FileManager.default.fileExists(atPath: imagesDirectoryPath, isDirectory: &objcBool)
        // If the folder with the given path doesn't exist already, create it
//        if isExist == false {
//            do{
//                try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
//            }catch{
//                print("Something went wrong while creating a new folder")
//            }
//        }
    }


    func refreshTable(){
        do{
            images.removeAll()
            titles = try FileManager.default.contentsOfDirectory(atPath: imagesDirectoryPath)
            for image in titles {
                let data = FileManager.default.contents(atPath: imagesDirectoryPath.appending("/\(image)"))
                let image = UIImage(data: data!)
                images.append(image!)
            }
            self.tableView.reloadData()
        }catch{
            print("Error")
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
