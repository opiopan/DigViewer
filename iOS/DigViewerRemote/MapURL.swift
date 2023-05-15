//
//  MapURL.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/12/26.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI

class MapURL: NSObject, UIActivityItemSource {
    fileprivate let url : URL
    fileprivate let title : String
    fileprivate let vcfData : Data
    
    init(geometry : MapGeometry, title : String) {
        self.title = title
        let lat = geometry.latitude
        let lng = geometry.longitude
        let urlString = "http://maps.apple.com/maps?address=&ll=\(lat),\(lng)&q=\(lat),\(lng)&t=m"
        url = URL(string: urlString)!
        
        let vcfString = "BEGIN:VCARD\nVERSION:3.0\n   N:;\(title);;;\n   FN:Shared Location\n" +
            "item1.URL;type=pref:http://maps.apple.com/?ll=\(lat),\(lng)\n" +
        "item1.X-ABLabel:map url\nEND:VCARD"
        vcfData = vcfString.data(using: String.Encoding.utf8)!
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - UIActivityItemSourceプロトコル
    //-----------------------------------------------------------------------------------------
    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any {
        return url
    }
    
    func activityViewController(_ controller: UIActivityViewController, itemForActivityType type: UIActivity.ActivityType?) -> Any? {
        return url
    }
    
    func activityViewController(_ controller: UIActivityViewController, dataTypeIdentifierForActivityType type: UIActivity.ActivityType?) -> String {
        return "public.url"
    }
    
    func activityViewController(_ controller: UIActivityViewController, subjectForActivityType type: UIActivity.ActivityType?) -> String {
        return ""
    }
    
    func activityViewController(_ controller: UIActivityViewController, thumbnailImageForActivityType type: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return nil
    }

}
