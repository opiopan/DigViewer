//
//  InspectorTableView.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/21.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class InspectorTableView: UITableView {
    override var contentInset: UIEdgeInsets {
        didSet {
            if (contentInset.top != 0){
                let insets = oldValue
                let time = dispatch_time(DISPATCH_TIME_NOW, 0)
                let weakSelf = self
                dispatch_after(time, dispatch_get_main_queue(), {[unowned weakSelf]() -> Void in
                    weakSelf.contentInset = insets
                })
            }
        }
    }
}
