//
//  ActionRequestHandler.swift
//  DVremoteCopySummaryAction
//
//  Created by opiopan on 2016/01/10.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import MobileCoreServices
import DVremoteCommonLib
import DVremoteCommonUI

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    func beginRequestWithExtensionContext(context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        
        var imageFound = false
        for item: AnyObject in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: AnyObject in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    itemProvider.loadItemForTypeIdentifier(kUTTypeImage as String, options: nil, completionHandler: {
                        [unowned self](data, error) in
                        var imageData : NSData? = nil
                        var image : UIImage? = nil
                        if let url = data as? NSURL {
                            imageData = NSData(contentsOfFile: url.path!)
                            image = UIImage(contentsOfFile: url.path!)
                        }else if let imageObject = data as? UIImage {
                            image = imageObject
                            imageData = UIImagePNGRepresentation(imageObject)
                        }
                        let name = ""
                        let type = NSLocalizedString("LS_IMAGE_TYPE_NAME", comment:"")
                        if imageData != nil && image != nil {
                            let meta = PortableImageMetadata(image: imageData, name: name, type: type)
                            let summary = SummarizedMeta(meta: meta.portableData())
                            summary.copySummaryToPasteboard()
                        }
                        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
                        self.extensionContext = nil
                    })
                    
                    imageFound = true
                    break
                }
            }
            
            if imageFound {
                break
            }
        }
        
        if !imageFound {
            self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
            self.extensionContext = nil
        }
    }

}
