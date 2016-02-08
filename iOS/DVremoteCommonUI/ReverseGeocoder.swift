//
//  ReverseGeocoder.swift
//  DigViewerRemote
//
//  Created by opiopan on 2016/01/09.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import MapKit

public class ReverseGeocoder: NSObject {
    
    public typealias CompleteHandler = (coder: ReverseGeocoder) -> Void

    public static let sharedCoder = ReverseGeocoder()
    
    private let geocoder = CLGeocoder()
    
    public var address : String? = nil
    
    private var currentLocation : CLLocation?
    private var isProceeding = false
    private var currentHandlers : [CompleteHandler] = []
    
    private var pendingLocation : CLLocation?
    private var pendingHandlers : [CompleteHandler] = []
    
    public func performCoding(location : CLLocation, completeHandler : CompleteHandler?) {
        if !isProceeding {
            if location == currentLocation {
                if let handler = completeHandler {
                    handler(coder: self)
                }
                return
            }
            
            isProceeding = true
            currentLocation = location
            if let handler = completeHandler {
                currentHandlers.append(handler)
            }
            geocoder.reverseGeocodeLocation(location){
                [unowned self](placemarks:[CLPlacemark]?, error : NSError?) -> Void in
                if placemarks != nil && placemarks!.count > 0 && self.pendingLocation == nil{
                    let placemark = placemarks![0]
                    if self.currentLocation == location {
                        self.address = self.recognizePlacemark(placemark)
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            [unowned self] in
                            for handler in self.currentHandlers {
                                handler(coder: self)
                            }
                            self.isProceeding = false
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
            }
        }else if location == currentLocation {
            if let handler = completeHandler {
                currentHandlers.append(handler)
            }
        }else if location == pendingLocation {
            if let handler = completeHandler {
                pendingHandlers.append(handler)
            }
        }else{
            pendingLocation = location
            pendingHandlers = []
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
