//
//  TagsModalViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 30/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import CoreLocation

class TagsModalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, BackendConnectionDelegate {
   // DELETE THIS VIEW CONTROLLER - not used anymore
    

    var currentPhotoLocalIdentifier: String?
    var tags: [TagModel]!
    var tagsWithSections: [[TagModel]]!
    var searchTags: [[TagModel]]!
    var searchFlag: Bool = false
    var timerBackend: Timer!
    var projectWasSelected: Bool = false
    var lastLocation: CLLocation!
    
    @IBOutlet weak var alltagsCheck: CheckBox!
   
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var windowView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        alltagsCheck.isOn = PhotoHandler.allTagsWasSet(localIdentifier: currentPhotoLocalIdentifier!)
        
        makeTagArray()
        // Do any additional setup after loading the view.
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.unwindToPhotosViewController(_:))))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let prjWasSelected = UserDefaults.standard.value(forKey: "projectWasSelected") as? Bool {
            projectWasSelected = prjWasSelected
        }
        if timerBackend == nil || !timerBackend.isValid {
            timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
            print("TIMER STARTED - tags")
        }
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timerBackend.invalidate()
        print("TIMER INVALID - tags")
    }
    //MARK: - make tags array
    func makeTagArray(){
        tags = PhotoHandler.getTags(localIdentifier: currentPhotoLocalIdentifier!)
        tags = self.tags.sorted(by: { $0.selected && !$1.selected})
        var tagsSelected = [TagModel]()
        var tagsUnselected = [TagModel]()
        for tag in tags {
            if tag.selected {
                tagsSelected.append(tag)
            } else {
                tagsUnselected.append(tag)
            }
        }
        
        tagsWithSections = [tagsSelected, tagsUnselected]
    }
    //MARK: - The called function for the timer
    @objc func callBackendConnection(){
        let backendConnection = BackendConnection.shared
        backendConnection.delegate = self
        backendConnection.attemptSignInToSiteSnapBackend(projectWasSelected: projectWasSelected, lastLocation: lastLocation)
    }
    
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
    
    func treatErrors(_ error: Error?) {
        print(error!)
    }
    
    func noProjectAssigned() {
        timerBackend.invalidate()
        print("TIMER INVALID - tags")
        performSegue(withIdentifier: "NoProjectsAssigned", sender: nil)
    }
    
    func userNeedToCreateFirstProject() {
        
    }
    
    func databaseUpdateFinished() {
        makeTagArray()
        tblView.reloadData()
    }
    @objc func unwindToPhotosViewController(_ sender:UITapGestureRecognizer){
        onClickClose(nil)
    }
    @IBAction func onClickClose(_ sender: UIButton?) {
//        let color = UIColor(hexString: "#a6b012")
//        windowView.backgroundColor = color
//        dismiss(animated: true, completion: nil)
       performSegue(withIdentifier: "unwindToPhotosViewController", sender: sender)
    }
    
    @IBAction func onCheckAllTags(_ sender: CheckBox) {
        if sender.isOn {
            if PhotoHandler.addAllTags(currentLocalIdentifier: currentPhotoLocalIdentifier!) {
                print("current tags was applied to all photos")
            }
        } else {
            if PhotoHandler.removeAllTags() {
                print("original tags for photos was restablished")
                performSegue(withIdentifier: "unwindToPhotosViewController", sender: sender)
            }
        }
    }
  
    
    @IBAction func onCheckTag(_ sender: CheckBox) {
        let index = sender.tag
        let tagId = tags[index].tag.id
        let photo = PhotoHandler.getSpecificPhoto(localIdentifier: currentPhotoLocalIdentifier!)
        let tag = TagHandler.getSpecificTag(id: tagId!)
        for t in (photo?.tags)! {
            let tg = t as! Tag
            print("current photo contain \(tg.text ?? "nil")")
        }
        for a in (tag?.photos)! {
            let pa = a as! Photo
            print("\(pa.localIdentifierString ?? "nil")")
        }
      
        if sender.isOn {
            tag?.addToPhotos(photo!)
            photo?.addToTags(tag!)
        } else {
            tag?.removeFromPhotos(photo!)
            photo?.removeFromTags(tag!)
        }
        for t in (photo?.tags)! {
            let tg = t as! Tag
            print("current photo contain \(tg.text ?? "nil")")
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if !searchFlag {
            return tagsWithSections.count
        } else {
            return searchTags.count
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !searchFlag{
            return tagsWithSections[section].count
        } else {
            return searchTags[section].count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath) as! TagCellTableViewCell
        cell.tagContainer.layer.cornerRadius = 10
        if !searchFlag {
            cell.tagText.text = tagsWithSections[indexPath.section][indexPath.row].tag.text
            //cell.tagSwitch.isOn = tagsWithSections[indexPath.section][indexPath.row].selected
            cell.tagCheckBox.isOn = tagsWithSections[indexPath.section][indexPath.row].selected
            if indexPath.section == 0 {
                cell.tagCheckBox.tag = indexPath.row
            } else {
                cell.tagCheckBox.tag = indexPath.section * tagsWithSections[indexPath.section - 1].count + indexPath.row
            }
            
            if tagsWithSections[indexPath.section][indexPath.row].tag.tagColor != nil {
                cell.tagContainer.backgroundColor = UIColor(hexString: tagsWithSections[indexPath.section][indexPath.row].tag.tagColor!)
            }
        } else {
            cell.tagText.text = searchTags[indexPath.section][indexPath.row].tag.text
            cell.tagCheckBox.isOn = searchTags[indexPath.section][indexPath.row].selected
            if indexPath.section == 0 {
                cell.tagCheckBox.tag = indexPath.row
            } else {
               
                cell.tagCheckBox.tag = indexPath.section * searchTags[indexPath.section - 1].count + indexPath.row
            }
            
            if searchTags[indexPath.section][indexPath.row].tag.tagColor != nil {
                cell.tagContainer.backgroundColor = UIColor(hexString: searchTags[indexPath.section][indexPath.row].tag.tagColor!)
               
                
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 5
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tags = PhotoHandler.getTags(localIdentifier: currentPhotoLocalIdentifier!)
        
        tags = self.tags.sorted(by: { $0.selected && !$1.selected})
        if searchText != "" {
            let searchValues = tags.filter { (dataArray:TagModel) -> Bool in
                return ((dataArray.tag.text?.lowercased().contains(searchText.lowercased()))!
                )}
        
            var tagsSelected = [TagModel]()
            var tagsUnselected = [TagModel]()
            for tag in searchValues {
                if tag.selected {
                    tagsSelected.append(tag)
                } else {
                    tagsUnselected.append(tag)
                }
            }
            searchTags = [tagsSelected, tagsUnselected]
            searchFlag = true
        } else {
            searchFlag = false
        }
    
        tblView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
   
}
//extension UIColor {
//    convenience init(hexString: String) {
//        let hex = hexString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
//        var int = UInt64()
//        Scanner(string: hex).scanHexInt64(&int)
//        //Scanner(string: hex).scanHexInt32(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (255, 0, 0, 0)
//        }
//        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
//    }
//}
extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
