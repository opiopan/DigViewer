//
//  HeadingOverlay.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/31.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

private let LineWidth = 0.008
private let HeadRootV = 0.05
private let HeadV = 0.07
private let HeadH = 0.04

private let ArrowTemplate : [CGPoint] = [
    CGPoint(x: 0.0, y: 1.0),
    CGPoint(x: HeadH, y: 1.0 - HeadV),
    CGPoint(x: LineWidth, y: 1.0 - HeadRootV),
    CGPoint(x: LineWidth, y: 0.0),
    CGPoint(x: -LineWidth, y: 0.0),
    CGPoint(x: -LineWidth, y: 1.0 - HeadRootV),
    CGPoint(x: -HeadH, y: 1.0 - HeadV),
]

open class HeadingOverlay: NSObject, MKOverlay {
    fileprivate let center : CLLocationCoordinate2D
    fileprivate let heading : Double
    fileprivate let fov : Double
    fileprivate let length : Double
    
    fileprivate var arrowGeometry : [MKMapPoint] = []
    fileprivate let bound : MKMapRect
    
    open var fovArcAngle : Double = 0
    open var fovArcCenter : MKMapPoint = MKMapPoint()
    open var fovArcStart : MKMapPoint = MKMapPoint()

    open var arrowColor = ConfigurationController.sharedController.mapArrowColor
    open var fovColor = ConfigurationController.sharedController.mapFovColor
    
    open var altitude: Double = 0
    
    public init(center : CLLocationCoordinate2D, heading : Double, fov : Double, vScale : Double, hScale : Double) {
        self.center = center
        self.heading = heading
        self.fov = fov
        self.length = vScale
        
        let rotation = -self.heading * Double.pi / 180.0
        
        for point in ArrowTemplate {
            let offset = CGPoint(x: point.x * CGFloat(hScale), y: point.y * CGFloat(vScale))
            arrowGeometry.append(MapGeometry.translateCoordinateToMapPoint(center, offset: offset, rotation: CGFloat(rotation)))
        }
        
        var xMax : Double
        var xMin : Double
        var yMax : Double
        var yMin : Double
        if fov > 0 {
            let fovArcRadius = length * 2.5
            fovArcAngle = fov * Double.pi / 180.0
            fovArcCenter = MKMapPointForCoordinate(center)
            fovArcStart = MapGeometry.translateCoordinateToMapPoint(
                center, offset: CGPoint(x: 0, y: fovArcRadius), rotation: CGFloat(rotation + fovArcAngle / 2))
            let width = sin(fovArcAngle / 2) * fovArcRadius
            let rect = [
                CGPoint(x: -width, y: fovArcRadius),
                CGPoint(x: width, y: fovArcRadius),
                CGPoint(x: width, y: 0),
                CGPoint(x: -width, y: 0),
            ]
            var mrect : [MKMapPoint] = []
            for point in rect {
                mrect.append(MapGeometry.translateCoordinateToMapPoint(center, offset: point, rotation: CGFloat(rotation)))
            }
            xMax = mrect[0].x
            xMin = mrect[0].x
            yMax = mrect[0].y
            yMin = mrect[0].y
            for point in mrect {
                xMax = max(xMax, point.x)
                xMin = min(xMin, point.x)
                yMax = max(yMax, point.y)
                yMin = min(yMin, point.y)
            }
        }else{
            xMax = arrowGeometry[0].x
            xMin = arrowGeometry[0].x
            yMax = arrowGeometry[0].y
            yMin = arrowGeometry[0].y
            for point in arrowGeometry {
                xMax = max(xMax, point.x)
                xMin = min(xMin, point.x)
                yMax = max(yMax, point.y)
                yMin = min(yMin, point.y)
            }
        }
        bound = MKMapRect(origin: MKMapPoint(x: xMin, y: yMin), size: MKMapSize(width: xMax - xMin, height: yMax - yMin))
    }

    open var coordinate: CLLocationCoordinate2D {
        get {
            return center
        }
    }
    
    open var boundingMapRect: MKMapRect {
        get {
            return bound
        }
    }
    
    open var arrowPointList: [MKMapPoint] {
        get {
            return arrowGeometry
        }
    }
}
