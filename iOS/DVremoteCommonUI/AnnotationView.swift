//
//  AnnotationView.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/27.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

open class AnnotationView: MKPinAnnotationView {
    
    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open var calloutViewController : SummaryPopupViewController? {
        didSet{
//            if let controller = oldValue {
//                if oldValue != calloutViewController && controller.view.superview != nil {
//                    controller.view.removeFromSuperview()
//                }
//            }
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var hitView = super.hitTest(point, with: event)
        if hitView == nil && self.isSelected {
            if let calloutView = calloutViewController?.view {
                let pointInCalloutView = self.convert(point, to: calloutView)
                hitView = calloutView.hitTest(pointInCalloutView, with: event)
            }
        }
        return hitView
    }
    
    fileprivate var envelopeView : UIView? = nil
    
    open override var isSelected : Bool {
        didSet{
            if calloutViewController != nil {
                let calloutView = calloutViewController!.view
                if isSelected {
                    var frame = calloutView?.frame
                    frame?.origin.x = 0
                    frame?.origin.y = 0
                    calloutView?.frame = frame!
                    envelopeView = UIView(frame: frame!)
                    if calloutView?.superview != nil {
                        calloutViewController!.updateCount += 1
                        calloutViewController!.removeFromSuperView()
                    }
                    envelopeView!.addSubview(calloutView!)
                    
                    let annotationViewBounds = self.bounds
                    var calloutViewFrame = calloutView?.frame
                    calloutViewFrame?.origin.x = -((calloutViewFrame?.size.width)! - annotationViewBounds.size.width) * 0.5 - 8.0
                    calloutViewFrame?.origin.y = -(calloutViewFrame?.size.height)!
                    envelopeView!.frame = calloutViewFrame!;
                    envelopeView!.alpha = 0.0
                    addSubview(envelopeView!)
                    UIView.animate(withDuration: 0.2, animations: {[unowned self]() -> Void in
                        self.envelopeView!.alpha = 1.0
                        })
                }else{
                    if let targetView = envelopeView {
                        envelopeView = nil
                        let updateCount = calloutViewController!.updateCount
                        UIView.animate(withDuration: 0.2, animations: {() -> Void in
                            targetView.alpha = 0.0
                        }, completion: {[unowned self](flag : Bool) -> Void in
                            targetView.removeFromSuperview()
                            if self.calloutViewController != nil && self.calloutViewController!.updateCount == updateCount {
                                //self.calloutViewController!.removeFromSuperView()
                            }
                        })
                    }
                }
            }
        }
    }

}
