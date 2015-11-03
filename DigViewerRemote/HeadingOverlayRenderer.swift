//
//  HeadingOverlayRenderer.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/31.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

private let startColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.4)
private let startColorComponent = CGColorGetComponents(startColor.CGColor)
private let endColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0)
private let endColorComponent = CGColorGetComponents(endColor.CGColor)
private var components : [CGFloat] = [
    startColorComponent[0], startColorComponent[1], startColorComponent[2], startColorComponent[3],
    endColorComponent[0], endColorComponent[1], endColorComponent[2], endColorComponent[3],
];

private var locations : [CGFloat] = [0.0, 1.0]

class HeadingOverlayRenderer: MKOverlayRenderer {

    override init(overlay : MKOverlay) {
        super.init(overlay: overlay)
        self.alpha = 1.0
    }
    
    override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
        let headingOverlay = overlay as? HeadingOverlay

        // FOVを表す扇形の描画
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
        CGContextDrawRadialGradient(context, gradient, center, 0, center, radius, .DrawsAfterEndLocation)
        
//        CGContextSetFillColorWithColor(context, UIColor(red: 1, green: 0, blue: 0, alpha: 0.2).CGColor)
//        let rect = rectForMapRect(mapRect)
//        CGContextFillRect(context, rect)

        CGContextRestoreGState(context)
        
        // 矢印の描画
        let points = headingOverlay!.arrowPointList
        let startPoint = pointForMapPoint(points[0])
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, startPoint.x, startPoint.y)
        for var i = 1; i < points.count; i++ {
            let point = pointForMapPoint(points[i])
            CGContextAddLineToPoint(context, point.x, point.y)
        }
        CGContextClosePath(context)
        CGContextSetFillColorWithColor(context, UIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0).CGColor)
        CGContextFillPath(context)
    }
}
