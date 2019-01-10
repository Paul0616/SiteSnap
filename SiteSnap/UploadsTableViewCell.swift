//
//  UploadsTableViewCell.swift
//  SiteSnap
//
//  Created by Paul Oprea on 09/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import UIKit

class UploadsTableViewCell: UITableViewCell {

    @IBOutlet weak var cellContainerView: UIView!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var projectNameAndTimeLabel: UILabel!
    @IBOutlet weak var sizeAndSpeedLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        //Uplloads
        // Configure the view for the selected state
    }

    
}
