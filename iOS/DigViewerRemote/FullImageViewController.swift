//
//  FullImageViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/23.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class FullImageViewController: UIViewController, DVRemoteClientDelegate, UIGestureRecognizerDelegate {

    fileprivate var targetDocument : String? = nil
    fileprivate var targetPath : [String]? = nil
    
    @IBOutlet weak var baseView: UIView? = nil
    @IBOutlet weak var imageView : UIImageView? = nil
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var LoadingLabel: UILabel!
    @IBOutlet weak var FailedLabel: UILabel!
    @IBOutlet weak var frontendView: UIView!
    @IBOutlet weak var pinchGestureRecognizer: UIPinchGestureRecognizer!
    @IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetImageTransform()
        
        let client = DVRemoteClient.shared()
        client?.add(self)

        self.setNavigator(true)
        let time = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time){
            [unowned self]() in
            self.setNavigator(false)
        }
        
        imageView!.alpha = 0
        
        if let meta = DVRemoteClient.shared().meta {
            targetDocument = meta[DVRCNMETA_DOCUMENT] as? String
            targetPath = meta[DVRCNMETA_ID]as? [String]
            navigationItem.title = targetPath![targetPath!.count - 1]
        }
        
        FailedLabel.alpha = 0;
        if let image = DVRemoteClient.shared().fullImage(forID: targetPath, inDocument: targetDocument, withMaxSize: 2048) {
            indicatorView.layer.isHidden = true;
            LoadingLabel.layer.isHidden = true;
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                [unowned self]() -> Void in
                applyImage(image, rotation: DVRemoteClient.shared().imageRotation, animation: false)
            })
        }else{
            indicatorView.layer.isHidden = false;
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
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Displaying Image
    //-----------------------------------------------------------------------------------------
    fileprivate var imageSize = CGSize.zero
    fileprivate var imageTransform = CGAffineTransform.identity
    fileprivate var imageRatio = 1.0
    fileprivate var pinchScale = 1.0
    fileprivate var panOffset = CGPoint.zero
    
    fileprivate func resetImageTransform() {
        pinchScale = 1.0
        panOffset = CGPoint.zero
    }

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
            UIView.animate(withDuration: 0.35){
                [unowned self] in
                self.imageView!.alpha = 1
                self.imageView!.image = image
            }
        }else{
            imageView!.alpha = 1
            imageView!.image = image
        }
    }
    
    fileprivate func applyTransform(_ viewSize : CGSize) {
        if imageSize.width > 0 && imageSize.height > 0 {
            let hRatio = viewSize.width / imageSize.width
            let vRatio = viewSize.height / imageSize.height
            imageRatio = min(hRatio, vRatio)
            let transform = imageTransform
                .translatedBy(x: panOffset.x, y: panOffset.y)
                .scaledBy(x: imageRatio, y: imageRatio)
                .scaledBy(x: pinchScale, y: pinchScale)
            imageView!.transform = transform
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Transform by gesture
    //-----------------------------------------------------------------------------------------
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        switch (gestureRecognizer, otherGestureRecognizer) {
        case (panGestureRecognizer, pinchGestureRecognizer),
             (pinchGestureRecognizer, panGestureRecognizer):
            return true
        default:
            return false
        }
    }
    
    @IBAction func recognizeGesture(_ sender : AnyObject){
        if let pan = sender as? UIPanGestureRecognizer{
            let offset = pan.translation(in: frontendView)
            panOffset.x += offset.x
            panOffset.y += offset.y
            pan.setTranslation(.zero, in: frontendView)
            applyTransform(imageView!.bounds.size)
        }else if let pinch = sender as? UIPinchGestureRecognizer{
            let location = pinch.location(in: frontendView)
            let pointInImage = pointInImage(from: location, in: frontendView)
            pinchScale *= pinch.scale
            anchorImage(point: pointInImage, to: location, in: frontendView)
            pinch.scale = 1.0
            applyTransform(imageView!.bounds.size)
        }
    }
    
    fileprivate func pointInImage(from point: CGPoint, in view: UIView) -> CGPoint{
        let viewSize = view.bounds.size
        let scale = 1.0 / (imageRatio * pinchScale)
        let x = (point.x - viewSize.width / 2 - panOffset.x) * scale
        let y = (point.y - viewSize.height / 2  - panOffset.y) * scale
        return CGPoint(x: x, y: y)
    }
    
    fileprivate func anchorImage(point imagePoint : CGPoint, to viewPoint : CGPoint, in view : UIView){
        let viewSize = view.bounds.size
        let scale = imageRatio * pinchScale
        let offset_x = imagePoint.x * scale - (viewPoint.x - viewSize.width / 2)
        let offset_y = imagePoint.y * scale - (viewPoint.y - viewSize.height / 2)
        panOffset = CGPoint(x: -offset_x, y: -offset_y)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Toggle navigation bar
    //-----------------------------------------------------------------------------------------
    @IBAction func tapImageView(_ sender: AnyObject){
        if let barState = self.navigationController?.isNavigationBarHidden {
            setNavigator(barState)
        }
    }
    
    func setNavigator(_ enabled: Bool){
        UIView.animate(withDuration: 0.2, animations:{
            [unowned self]()->Void in
            navigationController?.setNavigationBarHidden(!enabled, animated: true)
            baseView?.backgroundColor = enabled ? UIColor.systemBackground : UIColor.black
            indicatorAutoHidden = !enabled
            statusBarHidden = !enabled
            let labelColor = enabled ? UIColor.label : UIColor.white
            LoadingLabel.textColor = labelColor
            FailedLabel.textColor = labelColor
            indicatorView.color = labelColor
        }, completion:{
            [unowned self] (_) in
            UIView.animate(withDuration: 0.2){
                [unowned self] in
                applyTransform(imageView!.bounds.size)
            }
        })
    }
    
    private var indicatorAutoHidden:Bool = false {
        didSet {
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.indicatorAutoHidden
    }
    
    private var statusBarHidden:Bool = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - デバイス回転
    //-----------------------------------------------------------------------------------------
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        UIView.animate(withDuration: 0.2, animations: {
            [unowned self] in
            self.applyTransform(size)
        }, completion: {
            [unowned self] (_) in
            UIView.animate(withDuration: 0.2){
                [unowned self] in
                self.applyTransform(imageView?.bounds.size ?? CGSize())
            }
        })
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
            UIView.animate(withDuration: 0.35){
                [unowned self] in
                self.FailedLabel.alpha = 1
                self.LoadingLabel.alpha = 0
                self.indicatorView.stopAnimating()
                self.indicatorView.alpha = 0
            }
        }
    }
    
}
