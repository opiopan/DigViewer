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

public class ReverseGeocoder: NSObject {
    
    public typealias CompleteHandler = (coder: ReverseGeocoder) -> Void

    public static let sharedCoder = ReverseGeocoder()
    
    private let geocoder = CLGeocoder()

    public var location : CLLocation? {
        get {
            return currentLocation
        }
    }
    
    public var address : String? = nil
    
    private enum QueryStatus {
        case None
        case Waiting
        case Proceeding
    }
    
    private var queryDate : NSDate?
    private var currentLocation : CLLocation?
    private var queryStatus = QueryStatus.None
    private var currentHandlers : [CompleteHandler] = []
    
    private var pendingLocation : CLLocation?
    private var pendingHandlers : [CompleteHandler] = []
    
    public func performCoding(location : CLLocation, completeHandler : CompleteHandler?) {
        if queryStatus == .None {
            if location.isEqual(currentLocation) {
                if let handler = completeHandler {
                    handler(coder: self)
                }
                return
            }

            queryStatus = .Waiting
            currentLocation = location
            if let handler = completeHandler {
                currentHandlers.append(handler)
            }

            var interval = 0.0
            let now = NSDate()
            if queryDate != nil {
                interval = max(0.3 - now.timeIntervalSinceDate(queryDate!), 0)
            }

            //NSLog("wait: \(location.coordinate.latitude) \(location.coordinate.longitude): \(interval)")
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()){
                [unowned self] in
                if self.queryStatus != .Waiting || self.currentLocation != location {
                    self.queryStatus = .None
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
                self.queryDate = NSDate()
                self.queryStatus = .Proceeding
                self.geocoder.reverseGeocodeLocation(location){
                    [unowned self](placemarks:[CLPlacemark]?, error : NSError?) -> Void in
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        [unowned self] in
                        //NSLog("end: \(location.coordinate.latitude) \(location.coordinate.longitude)")
                        self.queryDate = NSDate()
                        if placemarks != nil && placemarks!.count > 0{
                            let placemark = placemarks![0]
                            if location.isEqual(self.currentLocation) {
                                self.address = self.recognizePlacemark(placemark)
                                for handler in self.currentHandlers {
                                    handler(coder: self)
                                }
                            }
                        }
                        self.queryStatus = .None
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
        }else if queryStatus == .Waiting {
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
    
    private func recognizePlacemark(placemark : CLPlacemark) -> String? {
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
            let str = NSString(format: NSLocalizedString("ADDRESS_FORMAT", comment: ""),units[1], units[0]) as String
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
