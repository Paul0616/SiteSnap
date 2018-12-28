//
//  AddCommentsViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 28/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import Photos

class AddCommentsViewController: UIViewController {

    @IBOutlet weak var back: UIButton!
    var currentPhotoLocalIdentifier: String?
    var keyboardHeight: CGFloat!
    let commentTextview = UITextView()
    var bottomConstratint: NSLayoutConstraint!
    
    @IBOutlet weak var currentImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        back.layer.cornerRadius = 20
        // Do any additional setup after loading the view.
        guard let identifier = currentPhotoLocalIdentifier else {
            return
        }
        loadImage(identifier: identifier)
        
        
        commentTextview.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        commentTextview.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        currentImageView.addSubview(commentTextview)
        addObserver()
        commentTextview.becomeFirstResponder()
        commentTextview.translatesAutoresizingMaskIntoConstraints = false
        [
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
       
        
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        commentTextview.resignFirstResponder()
        addObserver()
        commentTextview.becomeFirstResponder()
    }
    
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
        
        print(keyboardHeight)
        //print(width)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("Keyboard hidden")
    }

    @IBAction func onBack(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }
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
                
                let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = true
                options.isNetworkAccessAllowed = true
                
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    //print(info!)
                    self.currentImageView.image = image
                    
                    /* The image is now available to us */
                    
                })
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
