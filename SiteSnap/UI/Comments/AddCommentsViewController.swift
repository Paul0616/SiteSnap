//
//  AddCommentsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 28/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import Photos
import CoreData

class AddCommentsViewController: UIViewController {

    @IBOutlet weak var back: UIButton!
    var currentPhotoLocalIdentifier: String?
    var keyboardHeight: CGFloat!
    let commentTextview = UITextView()
    var bottomConstratint: NSLayoutConstraint!
    var textForEdit: String = ""
    
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var currentImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        back.layer.cornerRadius = 20
        // Do any additional setup after loading the view.
        if let identifier = currentPhotoLocalIdentifier {
            loadImage(identifier: identifier)
        }
        
        addCommentButton.layer.cornerRadius = 25
        commentTextview.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        commentTextview.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        currentImageView.addSubview(commentTextview)
        addObserver()
        commentTextview.becomeFirstResponder()
        commentTextview.translatesAutoresizingMaskIntoConstraints = false
        [
            addCommentButton.bottomAnchor.constraint(equalTo: commentTextview.topAnchor, constant: 5),
            addCommentButton.trailingAnchor.constraint(equalTo: currentImageView.trailingAnchor, constant: -16),
            commentTextview.leadingAnchor.constraint(equalTo: currentImageView!.leadingAnchor),
            commentTextview.trailingAnchor.constraint(equalTo: currentImageView.trailingAnchor),
            commentTextview.heightAnchor.constraint(equalToConstant: 50)
            ].forEach{$0.isActive = true}
        bottomConstratint = commentTextview.bottomAnchor.constraint(equalTo: currentImageView.bottomAnchor, constant: 0)
        bottomConstratint.isActive = true
        commentTextview.font = UIFont.preferredFont(forTextStyle: .headline)
        commentTextview.delegate = self
        commentTextview.isScrollEnabled = false
        commentTextview.textColor = UIColor.white
        if textForEdit != "" {
            commentTextview.text = textForEdit
            textViewDidChange(commentTextview)
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        commentTextview.resignFirstResponder()
        addObserver()
        commentTextview.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    

    //MARK: - Install observer for keyboard show/hide
    func addObserver(){
        //keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    @objc func keyboardDidAppear(notification: NSNotification) {
        //print("Keyboard appeared")
        let keyboardSize:CGSize = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        //print("Keyboard size: \(keyboardSize)")
        
        keyboardHeight = min(keyboardSize.height, keyboardSize.width)
        //let width = max(keyboardSize.height, keyboardSize.width)
        bottomConstratint.constant = -keyboardHeight
        commentTextview.updateConstraints()
        
        print(keyboardHeight!)
        //print(width)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("Keyboard hidden")
    }
    //MARK: - UI Buttons actions
    @IBAction func onBack(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }
    @IBAction func onAddComment(_ sender: Any) {
        if let _ = currentPhotoLocalIdentifier {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
            fetchRequest.predicate = NSPredicate.init(format: "localIdentifierString=='\(currentPhotoLocalIdentifier!)'")
            do {
                let objects = try appDelegate.persistentContainer.viewContext.fetch(fetchRequest)
                for object in objects {
                    if !commentTextview.text.isEmpty {
                        object.individualComment = commentTextview.text
                    } else {
                         object.individualComment = nil
                    }
                }
                try appDelegate.persistentContainer.viewContext.save()
            
            } catch _ {
                // error handling
            }
            dismiss(animated: false, completion: nil)
        } else {
            performSegue(withIdentifier: "returnFromAddComment", sender: sender)
        }
    }
    
    //MARK: - Loading image
    func loadImage(identifier: String!) {
        let hiddenIdentifiers = PhotoHandler.photosDatabaseContainHidden(localIdentifiers: [identifier])
        if hiddenIdentifiers.count > 0 {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let imagePath: String = path.appending("/\(identifier!)")
            if FileManager.default.fileExists(atPath: imagePath),
                let imageData: Data = FileManager.default.contents(atPath: imagePath),  //try? Data(contentsOf: imageUrl),
                let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
                    self.currentImageView.image = image
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
                print(count)
                if object is PHAsset {
                    let asset = object as! PHAsset
                    //                print(asset)
                    
                    //let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    let imageSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                    
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .opportunistic
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    options.resizeMode = PHImageRequestOptionsResizeMode.exact
                    
                    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                        (image, info) -> Void in
                        //print(info!)
                        self.currentImageView.image = image
                        
                        /* The image is now available to us */
                        
                    })
                }
            }
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
extension AddCommentsViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: currentImageView.frame.width, height: 100)
        let estimatedSize = textView.sizeThatFits(size)
        textView.constraints.forEach{ (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = estimatedSize.height
            }
        }
    }
}
