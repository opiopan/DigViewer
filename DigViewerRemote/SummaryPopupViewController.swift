//
//  SummaryPopupViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/27.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class SummaryPopupViewController: UIViewController {
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var lensLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    var updateCount = 0
    
    var viewWidth:CGFloat = 350.0
    var viewHeight:CGFloat = 150.0

    override func viewDidLoad() {
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addToSuperView(parentView : UIView) {
        let childView = self.view
        childView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(childView)
        let viewDictionary = ["childView": childView, "parentView": parentView]
        let metricDictionary = ["viewWidth": Double(viewWidth), "viewHeight": Double(viewHeight)]
        let constraints = NSMutableArray()
        let constraintFormat1 =
        NSLayoutConstraint.constraintsWithVisualFormat(
            "H:[parentView]-(<=1)-[childView(==viewWidth)]",
            options : .AlignAllCenterY,
            metrics: metricDictionary,
            views: viewDictionary)
        constraints.addObjectsFromArray(constraintFormat1)
        let constraintFormat2 =
        NSLayoutConstraint.constraintsWithVisualFormat(
            "V:[parentView]-(<=1)-[childView(==viewHeight)]",
            options : .AlignAllCenterX,
            metrics: metricDictionary,
            views: viewDictionary)
        constraints.addObjectsFromArray(constraintFormat2)

        parentView.addConstraints((constraints as NSArray as? [NSLayoutConstraint])!)
    }
    
    func removeFromSuperView() {
        if view.superview != nil {
            view.removeFromSuperview()
            view.translatesAutoresizingMaskIntoConstraints = true
            var popupFrame = self.view.frame
            popupFrame.size.width = viewWidth
            popupFrame.size.height = viewHeight
            self.view.frame = popupFrame
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    

}
