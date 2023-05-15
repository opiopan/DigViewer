//
//  MapGeometry.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/12.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit
import DVremoteCommonLib

private let SPAN_TO_ALTITUDE_RATIO = 1.875
private let DEGREE_TO_METER_RATIO = 111000.0

open class MapGeometry: NSObject {
    public let latitude : Double
    public let longitude : Double
    public let viewLatitude : Double
    public let viewLongitude : Double
    
    public let spanLatitude : Double
    public let spanLongitude : Double
    public let spanLatitudeMeter : Double
    public let spanLongitudeMeter : Double
    
    public let heading : Double?
    
    public let centerCoordinate : CLLocationCoordinate2D
    public let photoCoordinate : CLLocationCoordinate2D
    
    public let mapSpan : MKCoordinateSpan
    public let cameraAltitude : Double
    public let cameraHeading : Double
    public let cameraTilt : Double
    
    public let fovAngle : Double
    
    public init(meta: [AnyHashable: Any]!, viewSize : CGSize, isLocalSession : Bool){
        let controller = ConfigurationController.sharedController
        
        latitude = (meta[DVRCNMETA_LATITUDE] as! Double?)!
        longitude = (meta[DVRCNMETA_LONGITUDE] as! Double?)!
        if controller.mapRelationSpan && !isLocalSession {
            spanLatitude = (meta[DVRCNMETA_SPAN_LATITUDE] as! Double?)!
            spanLongitude = (meta[DVRCNMETA_SPAN_LONGITUDE] as! Double?)!
            spanLatitudeMeter = (meta[DVRCNMETA_SPAN_LATITUDE_METER] as! Double?)!
            spanLongitudeMeter = (meta[DVRCNMETA_SPAN_LONGITUDE_METER] as! Double?)!
        }else{
            spanLatitudeMeter = Double(controller.mapSpan)
            spanLongitudeMeter = Double(controller.mapSpan)
            spanLatitude = spanLatitudeMeter / DEGREE_TO_METER_RATIO
            spanLongitude = spanLongitudeMeter / DEGREE_TO_METER_RATIO / fabs(cos(latitude / 180.0 * Double.pi))
        }
        
        heading = meta[DVRCNMETA_HEADING] as! Double?
        
        let OFFSET_RATIO = Double(controller.mapHeadingShift)
        let deltaLat = spanLatitude * OFFSET_RATIO
        let compensating = fabs(cos(latitude / 180 * Double.pi))
        let deltaLng = compensating == 0 ? deltaLat : deltaLat / compensating

        if heading != nil && controller.mapTurnToHeading {
            viewLatitude = latitude + deltaLat * cos(heading! / 180.0 * Double.pi)
            viewLongitude = longitude + deltaLng * sin(heading! / 180.0 * Double.pi)
            cameraHeading = heading!
        }else{
            viewLatitude = latitude
            viewLongitude = longitude
            cameraHeading = 0
        }
        cameraTilt = Double(controller.mapTilt)
        
        photoCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
        centerCoordinate = CLLocationCoordinate2DMake(viewLatitude, viewLongitude)
        mapSpan = MKCoordinateSpan(latitudeDelta: spanLatitude, longitudeDelta: spanLongitude)

        let vRatio = spanLatitudeMeter / Double(viewSize.height)
        let hRatio = spanLongitudeMeter / Double(viewSize.width)
        let vSpan = Double(viewSize.height) * max(vRatio, hRatio)
        
        cameraAltitude = vSpan * SPAN_TO_ALTITUDE_RATIO * cos(cameraTilt / 180 * Double.pi)

        let angle = meta[DVRCNMETA_FOV_ANGLE] as? Double
        if angle != nil {
            fovAngle = angle!
        }else{
            fovAngle = 0
        }
    }
    
    open class func mapToSpan(_ mapView : MKMapView) -> Double {
        let altitude = mapView.camera.altitude / cos(Double(mapView.camera.pitch) / 180 * Double.pi)
        let vSpan = altitude / SPAN_TO_ALTITUDE_RATIO
        let hSpan = vSpan * Double(mapView.bounds.size.width / mapView.bounds.size.height)
        
        return min(vSpan, hSpan)
    }
    
    open class func mapToSize(_ mapView : MKMapView) -> CGSize {
        let altitude = mapView.camera.altitude / cos(Double(mapView.camera.pitch) / 180 * Double.pi)
        let vSpan = altitude / SPAN_TO_ALTITUDE_RATIO
        let hSpan = vSpan * Double(mapView.bounds.size.width / mapView.bounds.size.height)
        
        return CGSize(width: hSpan, height: vSpan)
    }
    
    open class func translateCoordinateToMapPoint(_ point : CLLocationCoordinate2D, offset : CGPoint, rotation : CGFloat) -> MKMapPoint {
        let cosTheta = cos(rotation)
        let sinTheta = sin(rotation)
        let deltaX = offset.x * cosTheta - offset.y * sinTheta
        let deltaY = offset.x * sinTheta + offset.y * cosTheta
        let deltaLat = Double(deltaY) / DEGREE_TO_METER_RATIO
        let deltaLong = Double(deltaX) / DEGREE_TO_METER_RATIO / fabs(cos(point.latitude / 180.0 * Double.pi))
        return MKMapPoint(
            CLLocationCoordinate2D(latitude:point.latitude + deltaLat, longitude: point.longitude + deltaLong))
    }
}
