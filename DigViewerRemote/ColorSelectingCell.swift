//
//  ColorSelectingCell.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/07.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class ColorSelectingCell: UITableViewCell {
    override func setSelected(selected: Bool, animated: Bool) {
        if selected {
            beginUpdateSubview()
        }
        super.setSelected(selected, animated: animated)
        if selected {
            endUpdateSubview()
        }
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        if highlighted {
            beginUpdateSubview()
        }
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            endUpdateSubview()
        }
    }
    
    var savedColor : UIColor = UIColor.blackColor()
    
    private func beginUpdateSubview() {
        for subview in self.contentView.subviews {
            if subview.tag != 0 {
                savedColor = subview.backgroundColor!
                break;
            }
        }
    }

    private func endUpdateSubview() {
        for subview in self.contentView.subviews {
            if subview.tag != 0 {
                subview.backgroundColor = savedColor
            }
        }
    }
}
