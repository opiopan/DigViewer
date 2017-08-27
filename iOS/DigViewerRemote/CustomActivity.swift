//
//  CustomActivity.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/12/26.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class CustomActivity: UIActivity {
    fileprivate let type : String
    fileprivate let title : String
    fileprivate let icon : UIImage
    fileprivate let action : (() -> Void)?
    
    init(key : String, icon : UIImage, action : (() -> Void)?){
        self.type = key
        self.icon = icon
        self.title = NSLocalizedString(key, comment: "")
        self.action = action
    }
    
    override var activityType : UIActivityType? {
        return UIActivityType(type)
    }
    
    override var activityTitle : String? {
        return title
    }
    
    override var activityImage : UIImage? {
        return icon
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        super.prepare(withActivityItems: activityItems)
    }
    
    override var activityViewController : UIViewController? {
        return nil
    }
    
    override func perform() {
        if let action = self.action {
            action()
        }
    }
    
}
