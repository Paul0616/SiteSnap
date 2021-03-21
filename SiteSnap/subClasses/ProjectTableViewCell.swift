//
//  ProjectTableViewCell.swift
//  SiteSnap
//
//  Created by Paul Oprea on 25.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
//protocol ProjectTableViewCellDelegate {
//    func rowWasSelected(with row: Int)
//}
class ProjectTableViewCell: UITableViewCell {
//    var delegate: ProjectTableViewCellDelegate?
    
    @IBOutlet weak var projectTitleLabel: UILabel!
    @IBOutlet weak var roundCheckBox: RoundCheckBox!
    @IBOutlet weak var projectOwnerLabel: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
      //  roundCheckBox.isChecked = selected
      //  delegate?.rowWasSelected(with: roundCheckBox.tag)
    }

}