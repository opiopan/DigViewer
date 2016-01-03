//
//  ActionViewController.swift
//  DVremoteExifAction
//
//  Created by Hiroshi Murayama on 2016/01/02.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import MobileCoreServices
import DVremoteCommonLib
import DVremoteCommonUI

class ActionViewController: ExifViewControllerBase {
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.
        
        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
        var imageFound = false
        for item: AnyObject in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: AnyObject in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    // This is an image. We'll load it, then place it in our image view.
//                    weak var weakImageView = self.imageView
                    itemProvider.loadItemForTypeIdentifier(kUTTypeImage as String, options: nil, completionHandler: {
                        [unowned self] (data, error) in
                        if let url = data as? NSURL {
                            let imageData = NSData(contentsOfFile: url.path!)
                            let name = ""
                            let type = NSLocalizedString("LS_IMAGE_TYPE_NAME", comment:"")
                            let meta = PortableImageMetadata(image: imageData, name: name, type: type)
                            let image = UIImage(contentsOfFile: url.path!)
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
                // We only handle one image, so stop looking for more.
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func done(sender: AnyObject) {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
    }

}
