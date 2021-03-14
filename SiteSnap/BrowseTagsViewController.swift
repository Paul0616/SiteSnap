//
//  BrowseTagsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import CoreLocation

class BrowseTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, BackendConnectionDelegate {
    
    var currentPhotoLocalIdentifier: String?
    var tags: [TagModel]!
    var tagsUnselected: [TagModel]!
    var tagsSelected: [TagModel]!
    var searchTagsUnselected: [TagModel]!
    var searchTagsSelected: [TagModel]!
    var searchFlag: Bool = false
    var projectWasSelected: Bool = false
    var lastLocation: CLLocation!
    var timerBackend: Timer!
    

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var alltagsCheck: CheckBox!
    // var tagsApplied = 1
    
    @IBOutlet weak var allTagsTableView: UITableView!
    @IBOutlet weak var tagsAppliedStackView: UIStackView!
    @IBOutlet weak var applyTagLabel: UILabel!
    @IBOutlet weak var tblView1: UITableView!
    @IBOutlet weak var tblView2: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alltagsCheck.isOn = PhotoHandler.allTagsWasSet(localIdentifier: currentPhotoLocalIdentifier!)
        // Do any additional setup after loading the view.
        makeTagArray()
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
        tagsSelected = [TagModel]()
        tagsUnselected = [TagModel]()
        for tag in tags {
            if tag.selected {
                tagsSelected.append(tag)
            } else {
                tagsUnselected.append(tag)
            }
        }
        
        //tagsWithSections = [tagsSelected, tagsUnselected]
    }
    
    override func viewDidLayoutSubviews() {
        if self.view.safeAreaLayoutGuide.layoutFrame.size.width > self.view.safeAreaLayoutGuide.layoutFrame.size.height {
            print("landscape")
            tagsAppliedStackView.isHidden = false
            applyTagLabel.isHidden = true
        } else {
            print("portrait")
            applyTagLabel.isHidden = false
            if tagsSelected?.count == 0 {
                tagsAppliedStackView.isHidden = true
            } else {
                tagsAppliedStackView.isHidden = false
            }
        }
    }


    @IBAction func onBack(_ sender: Any) {
        //dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: "unwindToPhotos", sender: sender)
    }
  
    @IBAction func allTagsCheck(_ sender: CheckBox) {
        if sender.isOn {
            if PhotoHandler.addAllTags(currentLocalIdentifier: currentPhotoLocalIdentifier!) {
                print("current tags was applied to all photos")
            }
        } else {
            if PhotoHandler.removeAllTags() {
                print("original tags for photos was restablished")
                performSegue(withIdentifier: "unwindToPhotos", sender: sender)
            }
        }
    }
    @IBAction func onCheckTag1(_ sender: CheckBox) {
        let index = sender.tag
        let tagId = tagsUnselected[index].tag.id
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
    @IBAction func onCheckTag2(_ sender: CheckBox) {
        let index = sender.tag
        let tagId = tagsSelected[index].tag.id
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
    
    func reloadTagsIntoTables(){
        tagsAppliedStackView.isHidden = tagsSelected?.count == 0
        tblView1.reloadData()
        tblView2.reloadData()
    }
    
    //MARK: - Tables delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case tblView1:
            if !searchFlag {
                return tagsUnselected.count
            } else {
                return searchTagsUnselected?.count ?? 0
            }
        case tblView2:
            if !searchFlag {
                return tagsSelected.count
            } else {
                return searchTagsSelected?.count ?? 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case tblView1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell1", for: indexPath) as! TagCell1TableViewCell
            if !searchFlag {
                cell.tagText.text = tagsUnselected[indexPath.row].tag.text
                cell.tagCheckBox.isOn = tagsUnselected[indexPath.row].selected
                cell.tagCheckBox.tag = indexPath.row
                if tagsUnselected[indexPath.row].tag.tagColor != nil {
                    cell.container.backgroundColor = UIColor(hexString: tagsUnselected[indexPath.row].tag.tagColor!)
                }
            } else {
                cell.tagText.text = searchTagsUnselected[indexPath.row].tag.text
                cell.tagCheckBox.isOn = searchTagsUnselected[indexPath.row].selected
                cell.tagCheckBox.tag = indexPath.row
                if searchTagsUnselected[indexPath.row].tag.tagColor != nil {
                    cell.container.backgroundColor = UIColor(hexString: searchTagsUnselected[indexPath.row].tag.tagColor!)
                }
            }
            return cell
        case tblView2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell2", for: indexPath) as! TagCell2TableViewCell
            if !searchFlag {
                cell.tagText.text = tagsSelected[indexPath.row].tag.text
                cell.tagCheckBox.isOn = tagsSelected[indexPath.row].selected
                cell.tagCheckBox.tag = indexPath.row
                if tagsSelected[indexPath.row].tag.tagColor != nil {
                    cell.container.backgroundColor = UIColor(hexString: tagsSelected[indexPath.row].tag.tagColor!)
                }
            } else {
                cell.tagText.text = searchTagsSelected[indexPath.row].tag.text
                cell.tagCheckBox.isOn = searchTagsSelected[indexPath.row].selected
                cell.tagCheckBox.tag = indexPath.row
                if searchTagsSelected[indexPath.row].tag.tagColor != nil {
                    cell.container.backgroundColor = UIColor(hexString: searchTagsSelected[indexPath.row].tag.tagColor!)
                }
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tags = PhotoHandler.getTags(localIdentifier: currentPhotoLocalIdentifier!)
        
        tags = self.tags.sorted(by: { $0.selected && !$1.selected})
        if searchText != "" {
            let searchValues = tags.filter { (dataArray:TagModel) -> Bool in
                return ((dataArray.tag.text?.lowercased().contains(searchText.lowercased()))!
                )}
        
            searchTagsUnselected = [TagModel]()
            searchTagsSelected = [TagModel]()
            for tag in searchValues {
                if tag.selected {
                    searchTagsSelected.append(tag)
                } else {
                    searchTagsUnselected.append(tag)
                }
            }
            searchFlag = true
        } else {
            searchFlag = false
        }
        
        reloadTagsIntoTables()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: - The called function for the timer
    
    //MARK: - Backend delegate
    @objc func callBackendConnection(){
        let backendConnection = BackendConnection(projectWasSelected: projectWasSelected, lastLocation: lastLocation)
        backendConnection.delegate = self
        backendConnection.attemptSignInToSiteSnapBackend()
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
        tblView1.reloadData()
        tblView2.reloadData()
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

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        //Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
