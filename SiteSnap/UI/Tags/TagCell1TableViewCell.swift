//
//  TagCell1TableViewCell.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class TagCell1TableViewCell: UITableViewCell {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var tagText: PaddingLabel!
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
