//
//  LabelArrangableCell.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/22.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class LabelArrangableCell: UITableViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var textLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var subTextLabel: UILabel!
    @IBOutlet weak var cellHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    //-----------------------------------------------------------------------------------------
    // MARK: - テキストラベルの位置調整
    //-----------------------------------------------------------------------------------------
    var textLabelWidth : CGFloat = 32 {
        didSet {
            self.textLabelWidthConstraint!.constant = textLabelWidth
        }
    }
    
    var cellHeight : CGFloat = 16 {
        didSet {
            self.cellHeightConstraint!.constant = cellHeight
        }
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        if let width = textLabelWidth {
//            if let label = textLabel {
//                var labelFrame = label.frame
//                labelFrame.size.width = CGFloat(width)
//                textLabel!.frame = labelFrame
//                let xpos = labelFrame.origin.x + labelFrame.size.width + 4
//                var labelFrame2 = detailTextLabel!.frame
//                let delta = xpos - labelFrame2.origin.x
//                labelFrame2.origin.x += delta
//                //labelFrame2.size.width -= delta
//                detailTextLabel!.frame = labelFrame2
//            }
//        }
//    }
}
