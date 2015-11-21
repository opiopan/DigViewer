//
//  DataSourceDetailContentView.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/21.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class DataSourceDetailContentView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        (superview as! UIScrollView).contentSize = bounds.size
    }

}
