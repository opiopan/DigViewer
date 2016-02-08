//
//  InspectorImageCell.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/22.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

public class InspectorImageCell: UITableViewCell {

    override public func awakeFromNib() {
        super.awakeFromNib()
    }

    override public func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBOutlet public weak var thumbnailView: UIImageView!
    @IBOutlet public weak var mainLabel: UILabel!
    @IBOutlet public weak var subLabel: UILabel!
    @IBOutlet public weak var thumbnailHightConstraint: NSLayoutConstraint!
}
