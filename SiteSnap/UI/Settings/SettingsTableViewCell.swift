//
//  SettingsTableViewCell.swift
//  SiteSnap
//
//  Created by Paul Oprea on 21/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var settingLabel: UILabel!
    @IBOutlet weak var settingSubtitle: UILabel!
    @IBOutlet weak var checkBox: CheckBox!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
