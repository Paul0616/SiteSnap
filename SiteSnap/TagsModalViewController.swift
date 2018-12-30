//
//  TagsModalViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 30/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class TagsModalViewController: UIViewController {

    var currentPhotoLocalIdentifier: String?
    @IBOutlet weak var windowView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
//        let tag = TagHandler.getSpecificTag(text: "Bridge Superstructure")
//        let photo = PhotoHandler.getSpecificPhoto(localIdentifier: currentPhotoLocalIdentifier!)
//        tag?.addToPhotos(photo!)
  //      let tags = PhotoHandler.getTags(localIdentifier: currentPhotoLocalIdentifier!)
//        print(tags?.count as Any)
//        print(tags!)
        let tags = TagHandler.fetchObject()
        for tag in tags! {
            print("\(String(describing: tag.text)) - \(String(describing: tag.tagColor))")
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onClickClose(_ sender: UIButton) {
//        let color = UIColor(hexString: "#a6b012")
//        windowView.backgroundColor = color
        dismiss(animated: true, completion: nil)
       
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
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
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
