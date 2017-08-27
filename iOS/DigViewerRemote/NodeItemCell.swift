//
//  NodeItemCelll.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/26.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class NodeItemCell: UITableViewCell {
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    var nodeID : [AnyObject]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
