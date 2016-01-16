//
//  ActionViewController.swift
//  DVremoteLocationAction
//
//  Created by opiopan on 2016/01/06.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import MobileCoreServices
import DVremoteCommonLib
import DVremoteCommonUI

class LocationActionViewController: MapViewControllerBase {

    override func viewDidLoad() {
        super.viewDidLoad()
        super.isLocalSession = true
    
        var imageFound = false
        for item: AnyObject in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: AnyObject in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    itemProvider.loadItemForTypeIdentifier(kUTTypeImage as String, options: nil, completionHandler: {
                        [unowned self] (data, error) in
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
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                [unowned self] () in
                                self.meta = meta!.portableData()
                                self.thumbnail = image!
                            }
                        }
                        })
                    
                    imageFound = true
                    break
                }
            }
            
            if (imageFound) {
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func done(sender: AnyObject) {
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
    }

    @IBAction func showConfig(sender: AnyObject) {
    }
    
}
