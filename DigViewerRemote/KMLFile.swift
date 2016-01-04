//
//  KMLFile.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/12/13.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI

class KMLFile: NSObject, UIActivityItemSource {
    
    private let titleName : String
    private let pathString : String
    private let contents : String
    
    init(name : String, geometry : MapGeometry) {
        titleName = name
        
        let fileName = name.stringByReplacingOccurrencesOfString("/", withString: "-")
        let dirPath = "\(NSHomeDirectory())/tmp/KML"
        self.pathString = "\(dirPath)/\(fileName).kml"
        
        let range = max(geometry.spanLatitudeMeter, geometry.spanLongitudeMeter) / cos(geometry.cameraTilt / 180 * M_PI)

        let manager = NSFileManager.defaultManager()
        _ = try? manager.removeItemAtPath(dirPath)
        _ = try? manager.createDirectoryAtPath(dirPath, withIntermediateDirectories: true, attributes: nil)
        
        contents =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n" +
            "    <Placemark>\n" +
            "        <name>\(name)</name>\n" +
            "        <Point>\n" +
            "            <altitudeMode>clampToGround</altitudeMode>\n" +
            "            <coordinates>\(geometry.longitude),\(geometry.latitude),0</coordinates>\n" +
            "        </Point>\n" +
            "        <LookAt>\n" +
            "            <longitude>\(geometry.centerCoordinate.longitude)</longitude>\n" +
            "            <latitude>\(geometry.centerCoordinate.latitude)</latitude>\n" +
            "            <heading>\(geometry.cameraHeading)</heading>\n" +
            "            <tilt>\(geometry.cameraTilt)</tilt>\n" +
            "            <range>\(range)</range>\n" +
            "        </LookAt>\n" +
            "    </Placemark>\n" +
            "</kml>\n"
    }

    
    var path : String {
        get{
            _ = try? contents.writeToFile(pathString, atomically: false, encoding: NSUTF8StringEncoding)
            return pathString
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - UIActivityItemSourceプロトコル
    //-----------------------------------------------------------------------------------------
    func activityViewControllerPlaceholderItem(controller: UIActivityViewController) -> AnyObject {
        return NSData()
    }
    
    func activityViewController(controller: UIActivityViewController, itemForActivityType type: String) -> AnyObject? {
        return contents.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    func activityViewController(controller: UIActivityViewController, dataTypeIdentifierForActivityType type: String?) -> String {
        return "com.google.earth.kml"
    }
    
    func activityViewController(controller: UIActivityViewController, subjectForActivityType type: String?) -> String {
        return titleName
    }
}
