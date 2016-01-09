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

public class HeadingOverlay: NSObject, MKOverlay {
    private let center : CLLocationCoordinate2D
    private let heading : Double
    private let fov : Double
    private let length : Double
    
    private var arrowGeometry : [MKMapPoint] = []
    private let bound : MKMapRect
    
    public var fovArcAngle : Double = 0
    public var fovArcCenter : MKMapPoint = MKMapPoint()
    public var fovArcStart : MKMapPoint = MKMapPoint()

    public var arrowColor = ConfigurationController.sharedController.mapArrowColor
    public var fovColor = ConfigurationController.sharedController.mapFovColor
    
    public var altitude: Double = 0
    
    public init(center : CLLocationCoordinate2D, heading : Double, fov : Double, vScale : Double, hScale : Double) {
        self.center = center
        self.heading = heading
        self.fov = fov
        self.length = vScale
        
        let rotation = -self.heading * M_PI / 180.0
        
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
            fovArcAngle = fov * M_PI / 180.0
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

    public var coordinate: CLLocationCoordinate2D {
        get {
            return center
        }
    }
    
    public var boundingMapRect: MKMapRect {
        get {
            return bound
        }
    }
    
    public var arrowPointList: [MKMapPoint] {
        get {
            return arrowGeometry
        }
    }
}
