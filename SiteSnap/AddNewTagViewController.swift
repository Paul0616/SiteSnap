//
//  AddNewTagViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 15.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class AddNewTagViewController: UIViewController, CircleCheckBoxDelegate {
    func circleButtonTapped(sender: CircleCheckBox) {
        stackView1.arrangedSubviews.forEach { (view) in
            if let view = view as? CircleCheckBox, view != sender {
                view.isOn = false
            }
        }
        print(sender.tag)
        print(sender.isOn)
        print(sender.hexColor!)
    }
    
    @IBOutlet weak var stackView1: UIStackView!
    
    @IBOutlet weak var b1: CircleCheckBox!
    @IBOutlet weak var b2: CircleCheckBox!
    @IBOutlet weak var b3: CircleCheckBox!
    @IBOutlet weak var b4: CircleCheckBox!
    @IBOutlet weak var b5: CircleCheckBox!
    
    @IBOutlet weak var b6: CircleCheckBox!
    @IBOutlet weak var b7: CircleCheckBox!
    @IBOutlet weak var b8: CircleCheckBox!
    @IBOutlet weak var b9: CircleCheckBox!
    @IBOutlet weak var b10: CircleCheckBox!
    
    @IBOutlet weak var b11: CircleCheckBox!
    @IBOutlet weak var b12: CircleCheckBox!
    @IBOutlet weak var b13: CircleCheckBox!
    @IBOutlet weak var b14: CircleCheckBox!
    @IBOutlet weak var b15: CircleCheckBox!
    
    @IBOutlet weak var b16: CircleCheckBox!
    @IBOutlet weak var b17: CircleCheckBox!
    @IBOutlet weak var b18: CircleCheckBox!
    @IBOutlet weak var b19: CircleCheckBox!
    
    @IBAction func onCancelTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        b1.delegate = self
        b1.tag = 1
        b1.hexColor = "#be3436"
        b2.delegate = self
        b2.tag = 2
        b2.hexColor = "#bc145c"
        b3.delegate = self
        b3.tag = 3
        b3.hexColor = "#7d00a1"
        b4.delegate = self
        b4.tag = 4
        b4.hexColor = "#5912a7"
        b5.delegate = self
        b5.tag = 5
        b5.hexColor = "#3f339e"
        
        b6.delegate = self
        b6.tag = 6
        b6.hexColor = "#406dd0"
        b7.delegate = self
        b7.tag = 7
        b7.hexColor = "#3a82d0"
        b8.delegate = self
        b8.tag = 8
        b8.hexColor = "#2e96a6"
        b9.delegate = self
        b9.tag = 9
        b9.hexColor = "#1c796b"
        b10.delegate = self
        b10.tag = 10
        b10.hexColor = "#3b913d"
        
        b11.delegate = self
        b11.tag = 6
        b11.hexColor = "#67a23b"
        b12.delegate = self
        b12.tag = 7
        b12.hexColor = "#aab832"
        b13.delegate = self
        b13.tag = 8
        b13.hexColor = "#f4c538"
        b14.delegate = self
        b14.tag = 9
        b14.hexColor = "#f7a51e"
        b15.delegate = self
        b15.tag = 10
        b15.hexColor = "#ed801a"
        
        b16.delegate = self
        b16.tag = 6
        b16.hexColor = "#de4e24"
        b17.delegate = self
        b17.tag = 7
        b17.hexColor = "#5b4138"
        b18.delegate = self
        b18.tag = 8
        b18.hexColor = "#616161"
        b19.delegate = self
        b19.tag = 9
        b19.hexColor = "#485964"
        // Do any additional setup after loading the view.
//        let buttonRow1 = UIStackView()
//        buttonRow1.axis = NSLayoutConstraint.Axis.horizontal
//        buttonRow1.distribution = UIStackView.Distribution.fill
//        buttonRow1.alignment = UIStackView.Alignment.fill
//        buttonRow1.spacing = 8
//        buttonRow1.isUserInteractionEnabled = true
//
//        let b1 = CircleCheckBox()
//        b1.backgroundColor = .red
//        b1.tag = 1
//        b1.delegate = self
//        b1.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        b1.heightAnchor.constraint(equalToConstant: 30).isActive = true
//        b1.superview?.setNeedsDisplay()
//
//        let b2 = CircleCheckBox()
//        b2.backgroundColor = .yellow
//        b1.tag = 2
//        b2.delegate = self
//        b2.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        b2.heightAnchor.constraint(equalToConstant: 30).isActive = true
//
//        let b3 = CircleCheckBox()
//        b3.backgroundColor = .orange
//        b3.tag = 3
//        b1.delegate = self
//        b3.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        b3.heightAnchor.constraint(equalToConstant: 30).isActive = true
//
//        let b4 = CircleCheckBox()
//        b4.backgroundColor = .green
//        b1.tag = 4
//        b4.delegate = self
//        b4.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        b4.heightAnchor.constraint(equalToConstant: 30).isActive = true
//
//        let b5 = CircleCheckBox()
//        b5.backgroundColor = .brown
//        b1.tag = 5
//        b5.delegate = self
//        b5.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        b5.heightAnchor.constraint(equalToConstant: 30).isActive = true
//
//        buttonRow1.addArrangedSubview(b1)
//        buttonRow1.addArrangedSubview(b2)
//        buttonRow1.addArrangedSubview(b3)
//        buttonRow1.addArrangedSubview(b4)
//        buttonRow1.addArrangedSubview(b5)
//        buttonRow1.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(buttonRow1)
//        buttonRow1.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
//        buttonRow1.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
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

extension UIStackView {
    func removeFullyAllArrangedSubviews() {
            arrangedSubviews.forEach { (view) in
                removeFully(view: view)
            }
        }
    func removeFully(view: UIView) {
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
}
