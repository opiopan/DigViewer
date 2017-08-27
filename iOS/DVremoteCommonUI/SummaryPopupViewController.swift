//
//  SummaryPopupViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/27.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

public enum SummaryPopupViewParentType : Int {
    case noLocationCover
    case pinnedBar
}

public enum SummaryPopupPinMode : Int {
    case off
    case toolbar
    case left
    case right
}

@objc public protocol SummaryPopupViewControllerDelegate {
    @objc optional func summaryPopupViewControllerPushedPinButton(_ controller : SummaryPopupViewController) -> Void
}

open class SummaryPopupViewController: UIViewController {
    @IBOutlet open weak var thumbnailView: UIImageView!
    @IBOutlet open weak var dateLabel: UILabel!
    @IBOutlet open weak var cameraLabel: UILabel!
    @IBOutlet open weak var lensLabel: UILabel!
    @IBOutlet open weak var conditionLabel: UILabel!
    @IBOutlet open weak var addressLabel: UILabel!
    @IBOutlet open var popupView: PopupView!
    
    open var updateCount = 0
    
    open var viewWidth:CGFloat = 350.0
    open var viewHeight:CGFloat = 150.0
    open var viewBaseHeight:CGFloat {
        get{
            return viewHeight - 16
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenBounds = UIScreen.main.bounds
        let widthLimit = min(screenBounds.height, screenBounds.width) - 10
        viewWidth = min(viewWidth, widthLimit)

        var popupFrame = self.view.frame
        popupFrame.size.width = viewWidth
        popupFrame.size.height = viewHeight
        self.view.frame = popupFrame
        
        let baseView = self.view as? PopupView
        baseView!.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        baseView!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        baseView!.isOpaque = false
        
        let textColor = UIColor(red: CGFloat(1), green: CGFloat(1), blue: CGFloat(1), alpha: CGFloat(1))
        dateLabel!.textColor = textColor
        cameraLabel!.textColor = textColor
        lensLabel!.textColor = textColor
        conditionLabel!.textColor = textColor
        addressLabel!.textColor = textColor
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open func addToSuperView(_ parentView : UIView, parentType : SummaryPopupViewParentType) {
        let childView = self.view
        childView?.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(childView!)
        
        let viewDictionary = ["childView": childView!, "parentView": parentView]
        let metricDictionary = ["viewWidth": Double(viewWidth), "viewHeight": Double(viewHeight)]
        let constraints = NSMutableArray()

        let constraintFormat1 = NSLayoutConstraint.constraints(
            withVisualFormat: "H:[parentView]-(<=1)-[childView(==viewWidth)]",
            options : .alignAllCenterY,
            metrics: metricDictionary,
            views: viewDictionary)
        constraints.addObjects(from: constraintFormat1)
        
        var option : NSLayoutFormatOptions
        var constraintString : String
        if parentType == .noLocationCover {
            option = .alignAllCenterX
            constraintString = "V:[parentView]-(<=1)-[childView(==viewHeight)]"
        }else{
            option = NSLayoutFormatOptions(rawValue: 0)
            constraintString = "V:[parentView]-100-[childView(==viewHeight)]"
        }
        let constraintFormat2 = NSLayoutConstraint.constraints(
            withVisualFormat: constraintString,
            options : option,
            metrics: metricDictionary,
            views: viewDictionary)
        constraints.addObjects(from: constraintFormat2)
        
        parentView.addConstraints((constraints as NSArray as? [NSLayoutConstraint])!)
    }
    
    open func removeFromSuperView() {
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
    open var delegate : SummaryPopupViewControllerDelegate? = nil
    
    @IBOutlet open weak var pinButton: UIButton!
    
    @IBAction open func onPinButton(_ sender: AnyObject) {
        delegate?.summaryPopupViewControllerPushedPinButton!(self)
    }
    
    open var pinMode : SummaryPopupPinMode = .off {
        didSet{
            if pinMode == .toolbar{
                pinButton.setImage(UIImage(named: "pin_on"), for: UIControlState())
                popupView.backgroundMode = .none
            }else if pinMode == .left || pinMode == .right {
                pinButton.setImage(UIImage(named: "pin_on"), for: UIControlState())
                popupView.backgroundMode = .rectangle
            }else{
                pinButton.setImage(UIImage(named: "pin_off"), for: UIControlState())
                popupView.backgroundMode = .balloon
            }
            popupView.setNeedsDisplay()
        }
    }

}
