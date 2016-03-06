//
//  PreferencesNavigationController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/03.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

class PreferencesNavigationController: UINavigationController {
    var isOpenServerList : Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isOpenServerList {
            var controllers = viewControllers
            let newController = storyboard!.instantiateViewControllerWithIdentifier("ServerViewController") as? ServerViewController
            newController!.preferredContentSize = controllers[0].preferredContentSize
            controllers.append(newController!)
            viewControllers = controllers
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var mapView : MKMapView!
    
}
