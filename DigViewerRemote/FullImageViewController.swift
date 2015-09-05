//
//  FullImageViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/23.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class FullImageViewController: UIViewController, DVRemoteClientDelegate {

    private var targetDocument : String? = nil
    private var targetPath : [String]? = nil
    
    @IBOutlet weak var imageView : UIImageView? = nil
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var LoadingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let client = DVRemoteClient.sharedClient()
        client.addClientDelegate(self)

        navigationController?.hidesBarsOnTap = true
        
        if let meta = DVRemoteClient.sharedClient().meta {
            targetDocument = meta[DVRCNMETA_DOCUMENT] as? String
            targetPath = meta[DVRCNMETA_ID]as? [String]
            navigationItem.title = targetPath![targetPath!.count - 1]
        }
        
        if let image = DVRemoteClient.sharedClient().fullImageForID(targetPath, inDocument: targetDocument, withMaxSize: 2048) {
            indicatorView.layer.zPosition = -1;
            LoadingLabel.layer.zPosition = -1;
            applyImage(image, rotation: DVRemoteClient.sharedClient().imageRotation)
            let time = dispatch_time(DISPATCH_TIME_NOW, 0)
            dispatch_after(time, dispatch_get_main_queue(), {[unowned self]() -> Void in
                self.applyTransform(self.imageView!.bounds.size)
            })
        }else{
            indicatorView.layer.zPosition = 1;
            LoadingLabel.layer.zPosition = 1;
            indicatorView.startAnimating()
        }
    }
    
    deinit{
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func exitView(sender: AnyObject) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    private var imageSize : CGSize = CGSizeMake(0, 0)
    private var imageTransform :  CGAffineTransform = CGAffineTransformIdentity
    
    private func applyImage(image : UIImage?, rotation : Int) {
        imageSize = image!.size
        imageTransform = CGAffineTransformIdentity
        if (rotation == 5 || rotation == 8){
            /* 90 degrees rotation */
            imageTransform = CGAffineTransformRotate(imageTransform, CGFloat(M_PI_2 * 3));
            imageSize = CGSizeMake(image!.size.height, image!.size.width)
        }else if (rotation == 3 || rotation == 4){
            /* 180 degrees rotation */
            imageTransform = CGAffineTransformRotate(imageTransform, CGFloat(M_PI));
        }else if (rotation == 6 || rotation == 7){
            /* 270 degrees rotation */
            imageTransform = CGAffineTransformRotate(imageTransform, CGFloat(M_PI_2));
            imageSize = CGSizeMake(image!.size.height, image!.size.width)
        }
        self.imageView!.image = image
        applyTransform(imageView!.bounds.size)
    }
    
    private func applyTransform(viewSize : CGSize) {
        let hRatio = viewSize.width / imageSize.width
        let vRatio = viewSize.height / imageSize.height
        let ratio = min(hRatio, vRatio)
        let transform = CGAffineTransformScale(imageTransform, ratio, ratio)
        imageView!.transform = transform
    }
    //-----------------------------------------------------------------------------------------
    // MARK: - デバイス回転
    //-----------------------------------------------------------------------------------------
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        applyTransform(size)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, didRecieveFullImage image: UIImage!, ofId nodeId: [AnyObject]!, inDocument documentName: String!, withRotation rotation: Int) {
        var isSame = true
        if targetDocument == documentName && targetPath != nil && targetPath!.count == nodeId.count {
            for var i = 0; i < nodeId.count; i++ {
                if nodeId[i] as! String != targetPath![i] {
                    isSame = false
                    break
                }
            }
        }
        if (isSame){
            LoadingLabel.layer.zPosition = -1;
            indicatorView.stopAnimating()
            indicatorView.layer.zPosition = -1;
            applyImage(image, rotation: rotation)
        }
    }
    
}
