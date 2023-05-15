//
//  ReverseGeocoder.swift
//  DigViewerRemote
//
//  Created by opiopan on 2016/01/09.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import MapKit

private extension CLLocation {
}

open class ReverseGeocoder: NSObject {
    
    public typealias CompleteHandler = (_ coder: ReverseGeocoder) -> Void

    public static let sharedCoder = ReverseGeocoder()
    
    fileprivate let geocoder = CLGeocoder()

    open var location : CLLocation? {
        get {
            return currentLocation
        }
    }
    
    open var address : String? = nil
    
    fileprivate enum QueryStatus {
        case none
        case waiting
        case proceeding
    }
    
    fileprivate var queryDate : Date?
    fileprivate var currentLocation : CLLocation?
    fileprivate var queryStatus = QueryStatus.none
    fileprivate var currentHandlers : [CompleteHandler] = []
    
    fileprivate var pendingLocation : CLLocation?
    fileprivate var pendingHandlers : [CompleteHandler] = []
    
    open func performCoding(_ location : CLLocation, completeHandler : CompleteHandler?) {
        if queryStatus == .none {
            if location.isEqual(currentLocation) {
                if let handler = completeHandler {
                    handler(self)
                }
                return
            }

            queryStatus = .waiting
            currentLocation = location
            if let handler = completeHandler {
                currentHandlers.append(handler)
            }

            var interval = 0.0
            let now = Date()
            if queryDate != nil {
                interval = max(0.3 - now.timeIntervalSince(queryDate!), 0)
            }

            //NSLog("wait: \(location.coordinate.latitude) \(location.coordinate.longitude): \(interval)")
            let time = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time){
                [unowned self] in
                if self.queryStatus != .waiting || self.currentLocation != location {
                    self.queryStatus = .none
                    let newLocation = self.currentLocation!
                    self.currentLocation = nil
                    var handler : CompleteHandler? = nil
                    if self.currentHandlers.count > 0 {
                        handler = self.currentHandlers.removeLast()
                    }
                    //NSLog("switch: \(newLocation.coordinate.latitude) \(newLocation.coordinate.longitude)")
                    self.performCoding(newLocation, completeHandler: handler)
                    return
                }
                //NSLog("start: \(location.coordinate.latitude) \(location.coordinate.longitude)")
                self.queryDate = Date()
                self.queryStatus = .proceeding
                self.geocoder.reverseGeocodeLocation(location){
                    [unowned self](placemarks:[CLPlacemark]?, error : Error?) -> Void in
                    OperationQueue.main.addOperation {
                        [unowned self] in
                        //NSLog("end: \(location.coordinate.latitude) \(location.coordinate.longitude)")
                        self.queryDate = Date()
                        if placemarks != nil && placemarks!.count > 0{
                            let placemark = placemarks![0]
                            if location.isEqual(self.currentLocation) {
                                self.address = self.recognizePlacemark(placemark)
                                for handler in self.currentHandlers {
                                    handler(self)
                                }
                            }
                        }
                        self.queryStatus = .none
                        if let pending = self.pendingLocation {
                            self.pendingLocation = nil
                            self.currentHandlers = self.pendingHandlers
                            self.pendingHandlers = []
                            self.performCoding(pending, completeHandler: nil)
                        }else{
                            self.currentHandlers = []
                        }
                    }
                }
            }
        }else if location.isEqual(currentLocation) {
            //NSLog("pending1: \(location.coordinate.latitude) \(location.coordinate.longitude)")
            if let handler = completeHandler {
                currentHandlers.append(handler)
            }
        }else if queryStatus == .waiting {
            //NSLog("pending2: \(location.coordinate.latitude) \(location.coordinate.longitude)")
            if !location.isEqual(currentLocation) {
                currentLocation = location
                currentHandlers = []
            }
            if let handler = completeHandler {
                currentHandlers.append(handler)
            }
        }else{
            //NSLog("pending3: \(location.coordinate.latitude) \(location.coordinate.longitude)")
            if !location.isEqual(pendingLocation) {
                pendingLocation = location
                pendingHandlers = []
            }
            if let handler = completeHandler {
                pendingHandlers.append(handler)
            }
        }
    }
    
    fileprivate func recognizePlacemark(_ placemark : CLPlacemark) -> String? {
        var address : String? = nil
        
        let interest = placemark.areasOfInterest
        if interest != nil && interest!.count > 0 {
            address = interest![0]
        }
        
        var units : [String] = []
        if let unit = placemark.administrativeArea {
            units.append(unit)
        }
        if let unit = placemark.locality {
            units.append(unit)
        }
        if let unit = placemark.subLocality {
            units.append(unit)
        }
        
        if units.count >= 2 {
            let str = NSString(format: NSLocalizedString("ADDRESS_FORMAT", comment: "") as NSString,units[1], units[0]) as String
            if address == nil {
                address = str
            }else{
                address = "\(address!)\n\(str)"
            }
        }else if units.count == 1 {
            if address == nil {
                address = units[0]
            }else{
                address = "\(address!)\n\(units[0])"
            }
            
        }
        if let country = placemark.country {
            if address == nil {
                address = country
            }else{
                address = "\(address!) (\(country))"
            }
        }
        
        return address
    }

}
