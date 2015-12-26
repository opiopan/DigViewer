//
//  CustomActivity.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/12/26.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class CustomActivity: UIActivity {
    private let type : String
    private let title : String
    private let icon : UIImage
    private let action : (() -> Void)?
    
    init(key : String, icon : UIImage, action : (() -> Void)?){
        self.type = key
        self.icon = icon
        self.title = NSLocalizedString(key, comment: "")
        self.action = action
    }
    
    override func activityType() -> String? {
        return type
    }
    
    override func activityTitle() -> String? {
        return title
    }
    
    override func activityImage() -> UIImage? {
        return icon
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        super.prepareWithActivityItems(activityItems)
    }
    
    override func activityViewController() -> UIViewController? {
        return nil
    }
    
    override func performActivity() {
        if let action = self.action {
            action()
        }
    }
    
}
