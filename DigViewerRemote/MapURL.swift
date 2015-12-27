//
//  MapURL.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/12/26.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class MapURL: NSObject, UIActivityItemSource {
    private let url : NSURL
    private let title : String
    private let vcfData : NSData
    
    init(geometry : MapGeometry, title : String) {
        self.title = title
        let lat = geometry.latitude
        let lng = geometry.longitude
        let urlString = "http://maps.apple.com/maps?address=&ll=\(lat),\(lng)&q=\(lat),\(lng)&t=m"
        url = NSURL(string: urlString)!
        
        let vcfString = "BEGIN:VCARD\nVERSION:3.0\n   N:;\(title);;;\n   FN:Shared Location\n" +
            "item1.URL;type=pref:http://maps.apple.com/?ll=\(lat),\(lng)\n" +
        "item1.X-ABLabel:map url\nEND:VCARD"
        vcfData = vcfString.dataUsingEncoding(NSUTF8StringEncoding)!
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - UIActivityItemSourceプロトコル
    //-----------------------------------------------------------------------------------------
    func activityViewControllerPlaceholderItem(controller: UIActivityViewController) -> AnyObject {
        return url
    }
    
    func activityViewController(controller: UIActivityViewController, itemForActivityType type: String) -> AnyObject? {
        return url
    }
    
    func activityViewController(controller: UIActivityViewController, dataTypeIdentifierForActivityType type: String?) -> String {
        return "public.url"
    }
    
    func activityViewController(controller: UIActivityViewController, subjectForActivityType type: String?) -> String {
        return ""
    }
    
    func activityViewController(controller: UIActivityViewController, thumbnailImageForActivityType type: String?, suggestedSize size: CGSize) -> UIImage? {
        return nil
    }

}
