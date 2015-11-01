//
//  PopupView.swift
//  DigViewerRemote
//
//  Created by Hiroshi Murayama on 2015/09/28.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class PopupView: UIView {
    var fillColor : UIColor?
    var showAnchor = true {
        didSet {
            if oldValue != showAnchor {
                self.setNeedsDisplay()
            }
        }
    }
    var noBackground : Bool = false

    override func drawRect(rect: CGRect) {
        if noBackground {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        let radius = CGFloat(16)
        let anchor = CGFloat(16)
        let anchorHalfWidth = CGFloat(anchor * 0.9)
        let xOffset = -CGFloat(0)
        let width = self.bounds.size.width
        let height = self.bounds.size.height - anchor

        if self.fillColor != nil {
            CGContextSetFillColorWithColor(context, self.fillColor!.CGColor)
        }
        
        let rect = CGRectMake(0, 0, width, height)
        let minX = CGRectGetMinX(rect)
        let maxX = CGRectGetMaxX(rect)
        let midX = CGRectGetMidX(rect) + xOffset
        let minY = CGRectGetMinY(rect)
        let maxY = CGRectGetMaxY(rect)
        let midY = CGRectGetMidY(rect)
        CGContextMoveToPoint(context, midX + anchorHalfWidth, maxY)
        CGContextAddArcToPoint(context, minX, maxY, minX, midY, radius)
        CGContextAddArcToPoint(context, minX, minY, midX, minY, radius)
        CGContextAddArcToPoint(context, maxX, minY, maxX, midY, radius)
        CGContextAddArcToPoint(context, maxX, maxY, midX, maxY, radius)
        
        if showAnchor {
            CGContextAddLineToPoint(context, midX + anchorHalfWidth, maxY)
            CGContextAddLineToPoint(context, midX, maxY + anchor)
            CGContextAddLineToPoint(context, midX - anchorHalfWidth, maxY)
        }
        
        CGContextClosePath(context)
        CGContextFillPath(context)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - タッチイベント処理
    //-----------------------------------------------------------------------------------------
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        NSLog("touchBegan")
//    }
//    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        NSLog("touchMoved")
//    }
//    
//    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        NSLog("touchEnded")
//    }
//    
//    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
//        NSLog("touchCanceld")
//    }
}
