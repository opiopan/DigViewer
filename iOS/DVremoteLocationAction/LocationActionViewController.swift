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
        for item: Any in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: Any in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: {
                        [unowned self] (data, error) in
                        var imageData : Data? = nil
                        var image : UIImage? = nil
                        if let url = data as? URL {
                            imageData = try? Data(contentsOf: URL(fileURLWithPath: url.path))
                            image = UIImage(contentsOfFile: url.path)
                        }else if let imageObject = data as? UIImage {
                            image = imageObject
                            imageData = imageObject.pngData()
                        }
                        let name = ""
                        let type = NSLocalizedString("LS_IMAGE_TYPE_NAME", comment:"")
                        if imageData != nil && image != nil {
                            let meta = PortableImageMetadata(image: imageData, name: name, type: type)
                            OperationQueue.main.addOperation {
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

    @IBAction func done(_ sender: AnyObject) {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

    @IBAction func showConfig(_ sender: AnyObject) {
    }
    
}
