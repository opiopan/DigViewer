//
//  SummarizedMeta.swift
//  DigViewerRemote
//
//  Created by opiopan on 2016/01/10.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonLib

public class SummarizedMeta: NSObject {
    public let date : String?
    public let camera : String?
    public let lens : String?
    public let condition : String?
    
    public init(meta : [NSObject : AnyObject]) {
        if let popupSummary = meta[DVRCNMETA_POPUP_SUMMARY] as! [ImageMetadataKV]? {
            if popupSummary.count > 0 {
                date = popupSummary[0].value
            }else{
                date = nil
            }
            if popupSummary.count > 2 {
                camera = popupSummary[2].value
            }else{
                camera = nil
            }
            if popupSummary.count > 3 {
                lens = popupSummary[3].value
            }else{
                lens = nil
            }
            var condition : String = ""
            if popupSummary.count > 5 {
                for i in 5 ..< popupSummary.count {
                    if condition == "" {
                        condition = popupSummary[i].value
                    }else if let value = popupSummary[i].value {
                        condition = condition + " " + value
                    }
                }
            }
            self.condition = condition
        }else{
            date = nil
            camera = nil
            lens = nil
            condition = nil
        }
    }
    
    public var summaryText : String {
        get{
            let attributes : [String?] = [date, camera, lens, condition]
            let summary = attributes.reduce(""){
                if $1 != nil {
                        return "\($0)\($1!)\n"
                }else{
                    return $0
                }
            }
            return summary
        }
    }
    
    public func copySummaryToPasteboard() {
        let pasteboard = UIPasteboard.generalPasteboard()
        pasteboard.setValue(self.summaryText, forPasteboardType: "public.text")
    }
    
}
