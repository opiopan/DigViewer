//
//  HeadingOverlayRenderer.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/31.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

open class HeadingOverlayRenderer: MKOverlayRenderer {
    fileprivate var displayMode : MapHeadingDisplay

    fileprivate var components : [CGFloat]
    fileprivate var locations : [CGFloat] = [0.0, 1.0]
    
    override public init(overlay : MKOverlay) {
        displayMode = ConfigurationController.sharedController.mapHeadingDisplay

        var red : CGFloat = 0
        var green : CGFloat = 0
        var blue : CGFloat = 0
        var alpha : CGFloat = 0
        (overlay as! HeadingOverlay).fovColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let startColor = UIColor(red: red, green: green, blue: blue, alpha: 0.4)
        let startColorComponent:[CGFloat] = startColor.cgColor.components!
        let endColor = UIColor(red: red, green: green, blue: blue, alpha: 0)
        let endColorComponent:[CGFloat] = endColor.cgColor.components!
        components = [
            startColorComponent[0], startColorComponent[1], startColorComponent[2], startColorComponent[3],
            endColorComponent[0], endColorComponent[1], endColorComponent[2], endColorComponent[3],
        ];

        super.init(overlay: overlay)
    }
    
    override open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let headingOverlay = overlay as? HeadingOverlay

        // FOVを表す扇形の描画
        if displayMode == .fov || displayMode == .arrowAndFOV {
            context.saveGState()
            let center = point(for: headingOverlay!.fovArcCenter)
            let start = point(for: headingOverlay!.fovArcStart)
            let startRel = CGPoint(x: start.x - center.x, y: start.y - center.y)
            let radius = sqrt(startRel.x * startRel.x + startRel.y * startRel.y)
            var startAngle = acos(startRel.x / radius)
            if startRel.y < 0 {
                startAngle *= -1
            }
            context.beginPath()
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: start.x, y: start.y))
            context.addArc(center: center, radius: radius,
                           startAngle: startAngle, endAngle: startAngle + CGFloat(headingOverlay!.fovArcAngle),
                           clockwise: false)
            context.closePath()
            context.clip()
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: locations.count)
            context.drawRadialGradient(gradient!, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
            
            context.restoreGState()
        }
        
        // 矢印の描画
        if displayMode == .arrow || displayMode == .arrowAndFOV {
            let points = headingOverlay!.arrowPointList
            let startPoint = point(for: points[0])
            context.beginPath()
            context.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
            for i in 1 ..< points.count {
                let point = self.point(for: points[i])
                context.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            context.closePath()
            context.setFillColor(headingOverlay!.arrowColor.cgColor)
            context.fillPath()
        }
    }
}
