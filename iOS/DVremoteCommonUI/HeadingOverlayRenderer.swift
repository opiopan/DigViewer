//
//  HeadingOverlayRenderer.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/31.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

public class HeadingOverlayRenderer: MKOverlayRenderer {
    private var displayMode : MapHeadingDisplay

    private var components : [CGFloat]
    private var locations : [CGFloat] = [0.0, 1.0]
    
    override public init(overlay : MKOverlay) {
        displayMode = ConfigurationController.sharedController.mapHeadingDisplay

        var red : CGFloat = 0
        var green : CGFloat = 0
        var blue : CGFloat = 0
        var alpha : CGFloat = 0
        (overlay as! HeadingOverlay).fovColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let startColor = UIColor(red: red, green: green, blue: blue, alpha: 0.4)
        let startColorComponent = CGColorGetComponents(startColor.CGColor)
        let endColor = UIColor(red: red, green: green, blue: blue, alpha: 0)
        let endColorComponent = CGColorGetComponents(endColor.CGColor)
        components = [
            startColorComponent[0], startColorComponent[1], startColorComponent[2], startColorComponent[3],
            endColorComponent[0], endColorComponent[1], endColorComponent[2], endColorComponent[3],
        ];

        super.init(overlay: overlay)
    }
    
    override public func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
        let headingOverlay = overlay as? HeadingOverlay

        // FOVを表す扇形の描画
        if displayMode == .FOV || displayMode == .ArrowAndFOV {
            CGContextSaveGState(context)
            let center = pointForMapPoint(headingOverlay!.fovArcCenter)
            let start = pointForMapPoint(headingOverlay!.fovArcStart)
            let startRel = CGPoint(x: start.x - center.x, y: start.y - center.y)
            let radius = sqrt(startRel.x * startRel.x + startRel.y * startRel.y)
            var startAngle = acos(startRel.x / radius)
            if startRel.y < 0 {
                startAngle *= -1
            }
            CGContextBeginPath(context)
            CGContextMoveToPoint(context, center.x, center.y)
            CGContextAddLineToPoint(context, start.x, start.y)
            CGContextAddArc(
                context, center.x, center.y, radius,
                startAngle, startAngle + CGFloat(headingOverlay!.fovArcAngle), 0)
            CGContextClosePath(context)
            CGContextClip(context)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, locations.count)
            CGContextDrawRadialGradient(context, gradient!, center, 0, center, radius, .DrawsAfterEndLocation)
            
            CGContextRestoreGState(context)
        }
        
        // 矢印の描画
        if displayMode == .Arrow || displayMode == .ArrowAndFOV {
            let points = headingOverlay!.arrowPointList
            let startPoint = pointForMapPoint(points[0])
            CGContextBeginPath(context)
            CGContextMoveToPoint(context, startPoint.x, startPoint.y)
            for i in 1 ..< points.count {
                let point = pointForMapPoint(points[i])
                CGContextAddLineToPoint(context, point.x, point.y)
            }
            CGContextClosePath(context)
            CGContextSetFillColorWithColor(context, headingOverlay!.arrowColor.CGColor)
            CGContextFillPath(context)
        }
    }
}
