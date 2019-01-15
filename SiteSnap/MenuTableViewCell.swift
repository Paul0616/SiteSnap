//
//  MenuTableViewCell.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

    @IBOutlet weak var menuItemIcon: UIImageView!
    @IBOutlet weak var menuItemTitle: UILabel!
    @IBOutlet weak var menuItemDescription: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
