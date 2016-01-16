//
//  ActionRequestHandler.swift
//  DVremoteOpenAction
//
//  Created by opiopan on 2016/01/10.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import MobileCoreServices
import DVremoteCommonLib
import DVremoteCommonUI

class ActionRequestHandler: NSObject, NSExtensionRequestHandling, NSURLSessionDelegate {

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
                    itemProvider.loadItemForTypeIdentifier(kUTTypeImage as String, options: nil){
                        [unowned self] (data, error) in
                        var imageData : NSData? = nil
                        if let url = data as? NSURL {
                            imageData = NSData(contentsOfFile: url.path!)
                        }else if let imageObject = data as? UIImage {
                            imageData = UIImagePNGRepresentation(imageObject)
                        }

                        let task = self.createURLSession()
                        task.resume()
                        
                        self.extensionContext!.completeRequestReturningItems(context.inputItems, completionHandler: nil)
                        self.extensionContext = nil
                    }
                    
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

    private func createURLSession() -> NSURLSessionTask {
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(DVremoteSharedSessionID)
        config.sharedContainerIdentifier = DVremoteAppGroupID
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let url = NSURL(string: "http://support-sp.apple.com/sp/product?cc=DR54")
        //let url = NSURL(string: "https://www.google.com/")
        return session.downloadTaskWithURL(url!)
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        NSLog("invalidate session")
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        NSLog("finish session")
    }
    
}
