//
//  BrowseTagsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import CoreLocation



class BrowseTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, BackendConnectionDelegate, AddNewTagViewControllerDelegate {
    
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
    var isPortrait: Bool?
    

    var sameHeightTablesConstraint: NSLayoutConstraint?
    var lowerTableZeroHightConstraint: NSLayoutConstraint?
    var lowerTableHeaderHeightConstraint: NSLayoutConstraint?
    var lowerTableHeaderZeroHeightConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var alltagsCheck: CheckBox!
    // var tagsApplied = 1
    
    @IBOutlet weak var allTagsTableView: UITableView!
    @IBOutlet weak var allTagsStackView: UIStackView!
    @IBOutlet weak var tagsAppliedStackView: UIStackView!
    @IBOutlet weak var tagsAppliedhHeaderView: UIView!
    @IBOutlet weak var applyTagLabel: UILabel!
    @IBOutlet weak var tblView1: UITableView!
    @IBOutlet weak var tblView2: UITableView!
    @IBOutlet weak var allTagsCheckStackView: UIStackView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentPhotoLocalIdentifier = currentPhotoLocalIdentifier {
            alltagsCheck.isOn = PhotoHandler.allTagsWasSet(localIdentifier: currentPhotoLocalIdentifier)
            allTagsCheckStackView.isHidden = false
            makeTagArray()
        } else {
            allTagsCheckStackView.isHidden = true
            makeTagArrayWithNoCurrentPhoto()
        }
        setConstraints()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let prjWasSelected = UserDefaults.standard.value(forKey: "projectWasSelected") as? Bool, let _ =  currentPhotoLocalIdentifier {
            projectWasSelected = prjWasSelected
        }
        BackendConnection.shared.delegate = self
        if timerBackend == nil || !timerBackend.isValid {
            timerBackend = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(callBackendConnection), userInfo: nil, repeats: true)
            print("TIMER STARTED - tags")
        }
        BackendConnection.shared.delegate = self
        

    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timerBackend.invalidate()
        print("TIMER INVALID - tags")
    }
    
    
    //MARK: - make tags array
    func makeTagArray(){
        print("^^^^^^^^^^^^^^^^MAKE TAG ARRAY")
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
    }
    
    func makeTagArrayWithNoCurrentPhoto(){
       
        if let _ = tags {
            tagsSelected = [TagModel]()
            tagsUnselected = [TagModel]()
            for tag in tags {
                if tag.selected {
                    tagsSelected.append(tag)
                } else {
                    tagsUnselected.append(tag)
                }
            }
        }
    }
    
    func syncTags(){
        let currentProjectId = UserDefaults.standard.value(forKey: "currentProjectId") as! String
        let project = ProjectHandler.getSpecificProject(id: currentProjectId)
        print(project?.name)
        let newTags  = ProjectHandler.getTagsForProject(projectId: currentProjectId)
        
        var tempList: [TagModel] = []
        for tag in tags {
            print("old tag \(tag.tag.text) with id \(tag.tag.id)")
            print("\(newTags.filter({$0.tag == tag.tag}).count)")
            if !newTags.filter({$0.tag == tag.tag}).isEmpty {
                tempList.append(tag)
            }
        }
        let oldTagsIds : [Tag] = tags.map {$0.tag}
        let _newTags = newTags.filter({!oldTagsIds.contains($0.tag)})
        tempList.append(contentsOf: _newTags)
        tags = tempList
        makeTagArrayWithNoCurrentPhoto()
    }
    
    override func viewDidLayoutSubviews() {
        if self.view.safeAreaLayoutGuide.layoutFrame.size.width > self.view.safeAreaLayoutGuide.layoutFrame.size.height {
            print("landscape")
            isPortrait = false
            tagsAppliedStackView.isHidden = false
            applyTagLabel.isHidden = true
        } else {
            print("portrait")
            isPortrait = true
            applyTagLabel.isHidden = false
            if tagsSelected?.count == 0 {
                tagsAppliedStackView.isHidden = true
            } else {
                tagsAppliedStackView.isHidden = false
            }
        }
        tagsAppliedConstraints()
    }
    
    func setConstraints(){
        tagsAppliedStackView.translatesAutoresizingMaskIntoConstraints = false
        tagsAppliedhHeaderView.translatesAutoresizingMaskIntoConstraints = false
        sameHeightTablesConstraint = tagsAppliedStackView.heightAnchor.constraint(equalTo: allTagsStackView.heightAnchor, multiplier: 1)
        lowerTableZeroHightConstraint = tagsAppliedStackView.heightAnchor.constraint(equalToConstant: 0)
        
        lowerTableHeaderHeightConstraint = tagsAppliedhHeaderView.heightAnchor.constraint(equalToConstant: 56)
        lowerTableHeaderZeroHeightConstraint = tagsAppliedhHeaderView.heightAnchor.constraint(equalToConstant: 0)
    }
    
    func tagsAppliedConstraints(){
        if let isPortrait = isPortrait, !isPortrait {
            sameHeightTablesConstraint?.isActive = true
            lowerTableZeroHightConstraint?.isActive = false
            
            lowerTableHeaderHeightConstraint?.isActive = true
            lowerTableHeaderZeroHeightConstraint?.isActive = false
            return
        }
        
        if tagsSelected.count == 0 {
            sameHeightTablesConstraint?.isActive = false
            lowerTableZeroHightConstraint?.isActive = true
            
            lowerTableHeaderHeightConstraint?.isActive = false
            lowerTableHeaderZeroHeightConstraint?.isActive = true
        } else {
            sameHeightTablesConstraint?.isActive = true
            lowerTableZeroHightConstraint?.isActive = false
            
            lowerTableHeaderHeightConstraint?.isActive = true
            lowerTableHeaderZeroHeightConstraint?.isActive = false
        }
    }


    @IBAction func onBack(_ sender: Any) {
        //dismiss(animated: true, completion: nil)
        if let _ = currentPhotoLocalIdentifier{
            performSegue(withIdentifier: "unwindToPhotos", sender: sender)
        } else {
            performSegue(withIdentifier: "unwindToShareImages", sender: sender)
        }
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
        if let _ = currentPhotoLocalIdentifier{
            let photo = PhotoHandler.getSpecificPhoto(localIdentifier: currentPhotoLocalIdentifier!)
            let tag = TagHandler.getSpecificTag(id: tagId!)
    //        for t in (photo?.tags)! {
    //            let tg = t as! Tag
    //            print("current photo contain \(tg.text ?? "nil")")
    //        }
    //        for a in (tag?.photos)! {
    //            let pa = a as! Photo
    //            print("\(pa.localIdentifierString ?? "nil")")
    //        }
          
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
        } else {
            let tag = TagHandler.getSpecificTag(id: tagId!)
            if sender.isOn {
                tags.filter({$0.tag == tag}).first!.selected = true
                makeTagArrayWithNoCurrentPhoto()
            }
        }
        databaseUpdateFinished()
    }
    
    @IBAction func onCheckTag2(_ sender: CheckBox) {
        let index = sender.tag
        let tagId = tagsSelected[index].tag.id
        if let _ = currentPhotoLocalIdentifier{
            let photo = PhotoHandler.getSpecificPhoto(localIdentifier: currentPhotoLocalIdentifier!)
            let tag = TagHandler.getSpecificTag(id: tagId!)
    //        for t in (photo?.tags)! {
    //            let tg = t as! Tag
    //            print("current photo contain \(tg.text ?? "nil")")
    //        }
    //        for a in (tag?.photos)! {
    //            let pa = a as! Photo
    //            print("\(pa.localIdentifierString ?? "nil")")
    //        }
          
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
        } else {
            let tag = TagHandler.getSpecificTag(id: tagId!)
            if !sender.isOn {
                tags.filter({$0.tag == tag}).first!.selected = false
                makeTagArrayWithNoCurrentPhoto()
            }
        }
        databaseUpdateFinished()
    }
    
    func reloadTagsIntoTables(){
        tagsAppliedStackView.isHidden = tagsSelected?.count == 0
        tagsAppliedConstraints()
        tblView1.reloadData()
        tblView2.reloadData()
    }
    
    //MARK: - AddNewTagDelegate
    func tagWasAdded() {
        BackendConnection.shared.delegate = self
    }
    func addNewTagwasDismissed() {
        BackendConnection.shared.delegate = self
        databaseUpdateFinished()
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
                    cell.container.backgroundColor = UIColor(hexString: tagsUnselected[indexPath.row].tag.tagColor!).adjustedColor(percent: 1.2).withAlphaComponent(0.7)
                }
            } else {
                cell.tagText.text = searchTagsUnselected[indexPath.row].tag.text
                cell.tagCheckBox.isOn = searchTagsUnselected[indexPath.row].selected
                cell.tagCheckBox.tag = indexPath.row
                if searchTagsUnselected[indexPath.row].tag.tagColor != nil {
                    cell.container.backgroundColor = UIColor(hexString: searchTagsUnselected[indexPath.row].tag.tagColor!).adjustedColor(percent: 1.2).withAlphaComponent(0.7)
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
                    cell.container.backgroundColor = UIColor(hexString: tagsSelected[indexPath.row].tag.tagColor!).adjustedColor(percent: 1.2).withAlphaComponent(0.7)
                }
            } else {
                cell.tagText.text = searchTagsSelected[indexPath.row].tag.text
                cell.tagCheckBox.isOn = searchTagsSelected[indexPath.row].selected
                cell.tagCheckBox.tag = indexPath.row
                if searchTagsSelected[indexPath.row].tag.tagColor != nil {
                    cell.container.backgroundColor = UIColor(hexString: searchTagsSelected[indexPath.row].tag.tagColor!).adjustedColor(percent: 1.2).withAlphaComponent(0.7)
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
        if let _ = currentPhotoLocalIdentifier{
            tags = PhotoHandler.getTags(localIdentifier: currentPhotoLocalIdentifier!)
            
            tags = self.tags.sorted(by: { $0.selected && !$1.selected})
        }
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
    
    
    //MARK: - Backend delegate
    @objc func callBackendConnection(){
        BackendConnection.shared.attemptSignInToSiteSnapBackend(projectWasSelected: projectWasSelected, lastLocation: lastLocation)
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
    func treatErrorsApi(_ json: NSDictionary?) {
    }
    
    func noProjectAssigned() {
        timerBackend.invalidate()
        print("TIMER INVALID - tags")
        performSegue(withIdentifier: "NoProjectsAssigned", sender: nil)
    }
    
    func userNeedToCreateFirstProject() {
        
    }
    
    func databaseUpdateFinished() {
        if let _ = currentPhotoLocalIdentifier {
            makeTagArray()
        } else {
            syncTags()
        }
        tblView1.reloadData()
        tblView2.reloadData()
        tagsAppliedConstraints()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "addNewTagSegue", let destination = segue.destination as? AddNewTagViewController {
            destination.delegate = self
        }
    }
   

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
    
    func adjustedColor(percent: CGFloat) -> UIColor {
        var _percent = percent
        if _percent < 0 {
            _percent = 0
        }
        
        var r,g,b,a: CGFloat
        r = 0.0
        g = 0.0
        b = 0.0
        a = 0.0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: max(r * _percent, 0.0), green: max(g * _percent, 0.0), blue: max(b * _percent, 0.0), alpha: a)
        }
        return UIColor()
    }
}
