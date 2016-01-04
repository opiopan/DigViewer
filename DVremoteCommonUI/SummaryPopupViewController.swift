//
//  SummaryPopupViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/27.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

public enum SummaryPopupViewParentType : Int {
    case NoLocationCover
    case PinnedBar
}

public enum SummaryPopupPinMode : Int {
    case Off
    case Toolbar
    case Left
    case Right
}

@objc public protocol SummaryPopupViewControllerDelegate {
    optional func summaryPopupViewControllerPushedPinButton(controller : SummaryPopupViewController) -> Void
}

public class SummaryPopupViewController: UIViewController {
    @IBOutlet public weak var thumbnailView: UIImageView!
    @IBOutlet public weak var dateLabel: UILabel!
    @IBOutlet public weak var cameraLabel: UILabel!
    @IBOutlet public weak var lensLabel: UILabel!
    @IBOutlet public weak var conditionLabel: UILabel!
    @IBOutlet public weak var addressLabel: UILabel!
    @IBOutlet public var popupView: PopupView!
    
    public var updateCount = 0
    
    public var viewWidth:CGFloat = 350.0
    public var viewHeight:CGFloat = 150.0
    public var viewBaseHeight:CGFloat {
        get{
            return viewHeight - 16
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenBounds = UIScreen.mainScreen().bounds
        let widthLimit = min(screenBounds.height, screenBounds.width) - 10
        viewWidth = min(viewWidth, widthLimit)

        var popupFrame = self.view.frame
        popupFrame.size.width = viewWidth
        popupFrame.size.height = viewHeight
        self.view.frame = popupFrame
        
        let baseView = self.view as? PopupView
        baseView!.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        baseView!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        baseView!.opaque = false
        
        let textColor = UIColor(red: CGFloat(1), green: CGFloat(1), blue: CGFloat(1), alpha: CGFloat(1))
        dateLabel!.textColor = textColor
        cameraLabel!.textColor = textColor
        lensLabel!.textColor = textColor
        conditionLabel!.textColor = textColor
        addressLabel!.textColor = textColor
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func addToSuperView(parentView : UIView, parentType : SummaryPopupViewParentType) {
        let childView = self.view
        childView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(childView)
        
        let viewDictionary = ["childView": childView, "parentView": parentView]
        let metricDictionary = ["viewWidth": Double(viewWidth), "viewHeight": Double(viewHeight)]
        let constraints = NSMutableArray()

        let constraintFormat1 = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:[parentView]-(<=1)-[childView(==viewWidth)]",
            options : .AlignAllCenterY,
            metrics: metricDictionary,
            views: viewDictionary)
        constraints.addObjectsFromArray(constraintFormat1)
        
        var option : NSLayoutFormatOptions
        var constraintString : String
        if parentType == .NoLocationCover {
            option = .AlignAllCenterX
            constraintString = "V:[parentView]-(<=1)-[childView(==viewHeight)]"
        }else{
            option = NSLayoutFormatOptions(rawValue: 0)
            constraintString = "V:[parentView]-100-[childView(==viewHeight)]"
        }
        let constraintFormat2 = NSLayoutConstraint.constraintsWithVisualFormat(
            constraintString,
            options : option,
            metrics: metricDictionary,
            views: viewDictionary)
        constraints.addObjectsFromArray(constraintFormat2)
        
        parentView.addConstraints((constraints as NSArray as? [NSLayoutConstraint])!)
    }
    
    public func removeFromSuperView() {
        if view.superview != nil {
            view.removeFromSuperview()
            view.translatesAutoresizingMaskIntoConstraints = true
            var popupFrame = self.view.frame
            popupFrame.size.width = viewWidth
            popupFrame.size.height = viewHeight
            self.view.frame = popupFrame
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ピン操作
    //-----------------------------------------------------------------------------------------
    public var delegate : SummaryPopupViewControllerDelegate? = nil
    
    @IBOutlet public weak var pinButton: UIButton!
    
    @IBAction public func onPinButton(sender: AnyObject) {
        delegate?.summaryPopupViewControllerPushedPinButton!(self)
    }
    
    public var pinMode : SummaryPopupPinMode = .Off {
        didSet{
            if pinMode == .Toolbar{
                pinButton.setImage(UIImage(named: "pin_on"), forState: UIControlState.Normal)
                popupView.backgroundMode = .None
            }else if pinMode == .Left || pinMode == .Right {
                pinButton.setImage(UIImage(named: "pin_on"), forState: UIControlState.Normal)
                popupView.backgroundMode = .Rectangle
            }else{
                pinButton.setImage(UIImage(named: "pin_off"), forState: UIControlState.Normal)
                popupView.backgroundMode = .Balloon
            }
            popupView.setNeedsDisplay()
        }
    }

}
