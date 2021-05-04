//
//  CompletedUploadsTableViewCell.swift
//  SiteSnap
//
//  Created by Paul Oprea on 27.03.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit

class CompletedUploadsTableViewCell: UITableViewCell {

    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var showRemoveButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var sizeAndDate: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
