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
                let time = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
                let weakSelf = self
                DispatchQueue.main.asyncAfter(deadline: time, execute: {[unowned weakSelf]() -> Void in
                    weakSelf.contentInset = insets
                })
            }
        }
    }
}
