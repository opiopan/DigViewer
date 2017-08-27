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
    
    fileprivate let titleName : String
    fileprivate let pathString : String
    fileprivate let contents : String
    
    init(name : String, geometry : MapGeometry) {
        titleName = name
        
        let fileName = name.replacingOccurrences(of: "/", with: "-")
        let dirPath = "\(NSHomeDirectory())/tmp/KML"
        self.pathString = "\(dirPath)/\(fileName).kml"
        
        let range = max(geometry.spanLatitudeMeter, geometry.spanLongitudeMeter) / cos(geometry.cameraTilt / 180 * Double.pi)

        let manager = FileManager.default
        _ = try? manager.removeItem(atPath: dirPath)
        _ = try? manager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        
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
            _ = try? contents.write(toFile: pathString, atomically: false, encoding: String.Encoding.utf8)
            return pathString
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - UIActivityItemSourceプロトコル
    //-----------------------------------------------------------------------------------------
    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any {
        return Data()
    }
    
    func activityViewController(_ controller: UIActivityViewController, itemForActivityType type: UIActivityType) -> Any? {
        return contents.data(using: String.Encoding.utf8)
    }
    
    func activityViewController(_ controller: UIActivityViewController, dataTypeIdentifierForActivityType type: UIActivityType?) -> String {
        return "com.google.earth.kml"
    }
    
    func activityViewController(_ controller: UIActivityViewController, subjectForActivityType type: UIActivityType?) -> String {
        return titleName
    }
}
