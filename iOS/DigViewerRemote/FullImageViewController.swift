//
//  FullImageViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/23.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class FullImageViewController: UIViewController, DVRemoteClientDelegate {

    fileprivate var targetDocument : String? = nil
    fileprivate var targetPath : [String]? = nil
    
    @IBOutlet weak var imageView : UIImageView? = nil
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var LoadingLabel: UILabel!
    @IBOutlet weak var FailedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let client = DVRemoteClient.shared()
        client?.add(self)

        navigationController?.hidesBarsOnTap = true
        let time = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time){
            [unowned self]() in
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
        
        imageView!.alpha = 0
        
        if let meta = DVRemoteClient.shared().meta {
            targetDocument = meta[DVRCNMETA_DOCUMENT] as? String
            targetPath = meta[DVRCNMETA_ID]as? [String]
            navigationItem.title = targetPath![targetPath!.count - 1]
        }
        
        FailedLabel.alpha = 0;
        if let image = DVRemoteClient.shared().fullImage(forID: targetPath, inDocument: targetDocument, withMaxSize: 2048) {
            indicatorView.layer.zPosition = -1;
            LoadingLabel.layer.zPosition = -1;
            applyImage(image, rotation: DVRemoteClient.shared().imageRotation, animation: false)
            let time = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {[unowned self]() -> Void in
                self.applyTransform(self.imageView!.bounds.size)
            })
        }else{
            indicatorView.layer.zPosition = 1;
            LoadingLabel.layer.zPosition = 1;
            indicatorView.startAnimating()
        }
    }
    
    deinit{
        DVRemoteClient.shared().remove(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    @IBAction func exitView(_ sender: AnyObject) {
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    fileprivate var imageSize : CGSize = CGSize(width: 0, height: 0)
    fileprivate var imageTransform :  CGAffineTransform = CGAffineTransform.identity
    
    fileprivate func applyImage(_ image : UIImage?, rotation : Int, animation : Bool) {
        imageSize = image!.size
        imageTransform = CGAffineTransform.identity
        if (rotation == 5 || rotation == 8){
            /* 90 degrees rotation */
            imageTransform = imageTransform.rotated(by: CGFloat(Double.pi / 2 * 3));
            imageSize = CGSize(width: image!.size.height, height: image!.size.width)
        }else if (rotation == 3 || rotation == 4){
            /* 180 degrees rotation */
            imageTransform = imageTransform.rotated(by: CGFloat(Double.pi));
        }else if (rotation == 6 || rotation == 7){
            /* 270 degrees rotation */
            imageTransform = imageTransform.rotated(by: CGFloat(Double.pi / 2));
            imageSize = CGSize(width: image!.size.height, height: image!.size.width)
        }
        applyTransform(imageView!.bounds.size)
        if (animation){
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.35)
            imageView!.alpha = 1
            imageView!.image = image
            UIView.commitAnimations()
        }else{
            imageView!.alpha = 1
            imageView!.image = image
        }
    }
    
    fileprivate func applyTransform(_ viewSize : CGSize) {
        let hRatio = viewSize.width / imageSize.width
        let vRatio = viewSize.height / imageSize.height
        let ratio = min(hRatio, vRatio)
        let transform = imageTransform.scaledBy(x: ratio, y: ratio)
        imageView!.transform = transform
    }
    //-----------------------------------------------------------------------------------------
    // MARK: - デバイス回転
    //-----------------------------------------------------------------------------------------
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.2)
        applyTransform(size)
        UIView.commitAnimations()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(_ client: DVRemoteClient!, didRecieveFullImage image: UIImage!, ofId nodeId: [Any]!, inDocument documentName: String!, withRotation rotation: Int) {
        var isSame = true
        if targetDocument == documentName && targetPath != nil && targetPath!.count == nodeId.count {
            for i in 0 ..< nodeId.count {
                if nodeId[i] as! String != targetPath![i] {
                    isSame = false
                    break
                }
            }
        }
        if (isSame){
            LoadingLabel.alpha = 0
            indicatorView.stopAnimating()
            indicatorView.alpha = 0
            applyImage(image, rotation: rotation, animation: true)
        }
    }
    
    func dvrClient(_ client: DVRemoteClient!, change state: DVRClientState) {
        if (state == DVRClientState.disconnected){
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.35)
            FailedLabel.alpha = 1
            LoadingLabel.alpha = 0
            indicatorView.stopAnimating()
            indicatorView.alpha = 0
            UIView.commitAnimations()
        }
    }
    
}
