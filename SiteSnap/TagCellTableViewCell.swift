//
//  TagCellTableViewCell.swift
//  SiteSnap
//
//  Created by Paul Oprea on 31/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit

class TagCellTableViewCell: UITableViewCell {

    @IBOutlet weak var tagStackView: UIStackView!
    @IBOutlet weak var tagContainer: UIView!
    @IBOutlet weak var tagText: UILabel!
    @IBOutlet weak var tagImage: UIView!
   
    @IBOutlet weak var tagCheckBox: CheckBox!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
