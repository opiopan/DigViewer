//
//  DataSourceCell.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/15.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class DataSourceCell: UITableViewCell {

    @IBOutlet weak var iconImageVIew: UIImageView!
    @IBOutlet weak var dataSourceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!

    var detailTransitor : ((DataSourceCell) -> (Void))? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func onDetailButton(sender: AnyObject) {
        if detailTransitor != nil {
            detailTransitor!(self)
        }
    }
    
}
