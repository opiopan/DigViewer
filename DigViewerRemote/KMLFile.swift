//
//  KMLFile.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/12/13.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class KMLFile: NSObject {
    
    let path : String
    
    init(name : String, geometry : MapGeometry) {
        let fileName = name.stringByReplacingOccurrencesOfString("/", withString: "-")
        let dirPath = "\(NSHomeDirectory())/tmp/KML"
        self.path = "\(dirPath)/\(fileName).kml"
        
        let range = max(geometry.spanLatitudeMeter, geometry.spanLongitudeMeter) / cos(geometry.cameraTilt / 180 * M_PI)

        let manager = NSFileManager.defaultManager()
        _ = try? manager.removeItemAtPath(dirPath)
        _ = try? manager.createDirectoryAtPath(dirPath, withIntermediateDirectories: true, attributes: nil)
        
        let contents =
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
        _ = try? contents.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
    }

}
