//
//  NamedColorCell.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/07.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class NamedColorCell: UITableViewCell {
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var colorNameLabel: UILabel!
    
    var color: UIColor = UIColor.black {
        didSet {
            colorView.backgroundColor = color
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            colorView.backgroundColor = color
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            colorView.backgroundColor = color
        }
    }

}
