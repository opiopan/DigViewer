//
//  MapViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, DVRemoteClientDelegate {
    
    @IBOutlet var barTitle : UINavigationItem? = nil
    @IBOutlet var mapView : MKMapView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true;
        
//        let infoButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Camera,
//                                         target: self, action: Selector("performInformationButton:"))
//        navigationItem.rightBarButtonItem = infoButton;
        
        mapView!.layer.zPosition = -1;
        
        let client = DVRemoteClient.sharedClient()
        client.addClientDelegate(self)
        barTitle!.title = client.state != .Connected ? client.stateString : client.service.name
        if client.state == .Disconnected {
            let control = UIControl()
            performServersButton(self)
        }
    }
    
    deinit{
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 回転時対応
    //-----------------------------------------------------------------------------------------
    var isEnableDoublePane = true;
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let isReguler = traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular))
        let mode = splitViewController!.displayMode
        if size.width > size.height && isReguler {
            if mode != .PrimaryHidden {
                splitViewController!.preferredDisplayMode = .PrimaryHidden
            }
            if isEnableDoublePane {
                splitViewController!.preferredDisplayMode = .AllVisible
            }
        }else if size.height > size.width && isReguler {
            if mode != .PrimaryHidden {
                splitViewController!.preferredDisplayMode = .PrimaryHidden
            }
        }
    }
    
    // MARK: - ボタン応答
    //-----------------------------------------------------------------------------------------
    // Information ボタン
    //-----------------------------------------------------------------------------------------
    @IBAction func performInformationButton(sender : UIBarButtonItem) {
        let bounds = UIScreen.mainScreen().bounds
        let isReguler = traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular))
        let isConnected = DVRemoteClient.sharedClient().state == .Connected
        if bounds.size.height > bounds.size.width {
            // 縦表示
            if isConnected {
                if isReguler {
                    splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay
                }else{
                    performSegueWithIdentifier("ShowInformationView", sender: sender)
                }
            }
        }else{
            // 横表示
            if isReguler {
                isEnableDoublePane = !isEnableDoublePane
                splitViewController!.preferredDisplayMode = isEnableDoublePane ? .AllVisible : .PrimaryHidden
            }else{
                if isConnected {
                    performSegueWithIdentifier("ShowInformationView", sender: sender)
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // Servers ボタン
    //-----------------------------------------------------------------------------------------
    @IBAction func performServersButton(sender : AnyObject) {
        let isReguler = traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular)) &&
                        traitCollection.containsTraitsInCollection(UITraitCollection(verticalSizeClass: .Regular))
        if isReguler {
            performSegueWithIdentifier("PopoverServersView", sender: sender)
        }else{
            performSegueWithIdentifier("ModalServersView", sender: sender)
        }
    }

    //-----------------------------------------------------------------------------------------
    // 次・前 ボタン
    //-----------------------------------------------------------------------------------------
    @IBAction func moveToNextImage(sender : AnyObject) {
        DVRemoteClient.sharedClient()!.moveToNextImage()
    }
    
    @IBAction func moveToPreviousImage(sender : AnyObject) {
        DVRemoteClient.sharedClient()!.moveToPreviousImage()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        barTitle!.title = client.state != .Connected ? client.stateString : client.service.name
    }
    
    private var annotation : MKShape? = nil;
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        if (annotation != nil){
            mapView!.removeAnnotation(annotation)
        }
        
        let latitude = meta[DVRCNMETA_LATITUDE] as! Double?;
        let longitude = meta[DVRCNMETA_LONGITUDE] as! Double?;
        let viewLatitude = meta[DVRCNMETA_VIEW_LATITUDE] as! Double?;
        let viewLongitude = meta[DVRCNMETA_VIEW_LONGITUDE] as! Double?;
        if (latitude != nil && longitude != nil){
            let centerCoordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
            let fromEyeCoordinate = CLLocationCoordinate2DMake(viewLatitude!, viewLongitude!)
            let eyeAltitude = 50.0
            let camera = MKMapCamera(lookingAtCenterCoordinate: centerCoordinate,
                                     fromEyeCoordinate: fromEyeCoordinate, eyeAltitude: eyeAltitude)
            mapView!.camera = camera;

            var nodeId = meta[DVRCNMETA_ID] as! [String]?;
            var theRoppongiAnnotation = MKPointAnnotation()
            theRoppongiAnnotation.coordinate = centerCoordinate
            theRoppongiAnnotation.title = nodeId![nodeId!.count - 1]
            annotation = theRoppongiAnnotation
            mapView!.addAnnotation(annotation)
        }
    }

}

