//
//  PopupView.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/28.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

public enum PopupViewBackgroundMode {
    case none
    case balloon
    case rectangle
}

open class PopupView: UIView {
    open var fillColor : UIColor?
    open var showAnchor = true {
        didSet {
            if oldValue != showAnchor {
                self.setNeedsDisplay()
            }
        }
    }
    open var backgroundMode = PopupViewBackgroundMode.balloon

    open override func draw(_ rect: CGRect) {
        if backgroundMode == .none {
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
            context!.setFillColor(self.fillColor!.cgColor)
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        if backgroundMode == .balloon {
            let minX = rect.minX
            let maxX = rect.maxX
            let midX = rect.midX + xOffset
            let minY = rect.minY
            let maxY = rect.maxY
            let midY = rect.midY
            
            context!.move(to: CGPoint(x: midX + anchorHalfWidth, y: maxY))
            context!.addArc(tangent1End: CGPoint(x:minX, y:maxY), tangent2End: CGPoint(x:minX, y:midY), radius: radius)
            context!.addArc(tangent1End: CGPoint(x:minX, y:minY), tangent2End: CGPoint(x:midX, y:minY), radius: radius)
            context!.addArc(tangent1End: CGPoint(x:maxX, y:minY), tangent2End: CGPoint(x:maxX, y:midY), radius: radius)
            context!.addArc(tangent1End: CGPoint(x:maxX, y:maxY), tangent2End: CGPoint(x:midX, y:maxY), radius: radius)
            
            if showAnchor {
                context!.addLine(to: CGPoint(x: midX + anchorHalfWidth, y: maxY))
                context!.addLine(to: CGPoint(x: midX, y: maxY + anchor))
                context!.addLine(to: CGPoint(x: midX - anchorHalfWidth, y: maxY))
            }
            
            context!.closePath()
            context!.fillPath()
        }else{
            context!.fill(rect)
        }
    }
    
}
