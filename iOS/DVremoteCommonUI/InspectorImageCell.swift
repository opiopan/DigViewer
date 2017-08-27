//
//  InspectorImageCell.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/22.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

open class InspectorImageCell: UITableViewCell {

    override open func awakeFromNib() {
        super.awakeFromNib()
    }

    override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBOutlet open weak var thumbnailView: UIImageView!
    @IBOutlet open weak var mainLabel: UILabel!
    @IBOutlet open weak var subLabel: UILabel!
    @IBOutlet open weak var thumbnailHightConstraint: NSLayoutConstraint!
}
