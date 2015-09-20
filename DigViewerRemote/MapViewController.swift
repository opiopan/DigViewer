//
//  MapViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, DVRemoteClientDelegate, MKMapViewDelegate {
    
    @IBOutlet var barTitle : UINavigationItem? = nil
    @IBOutlet var mapView : MKMapView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true;
        
//        let infoButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Camera,
//                                         target: self, action: Selector("performInformationButton:"))
//        navigationItem.rightBarButtonItem = infoButton;
        
        mapView!.layer.zPosition = -1;
        mapView!.mapType = MKMapType.HybridFlyover;
        mapView!.delegate = self
        
        let client = DVRemoteClient.sharedClient()
        client.addClientDelegate(self)
        barTitle!.title = client.state != .Connected ? client.stateString : client.service.name
        if client.state == .Disconnected {
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
    // MARK: - DVRemoteClientDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        barTitle!.title = client.state != .Connected ? client.stateString : client.service.name
    }
    
    private var annotation : MKShape? = nil
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        if (annotation != nil){
            mapView!.removeAnnotation(annotation!)
            annotation = nil
        }
        centerCoordinate = nil
        photoCoordinate = nil
        mapSpan = nil
        cameraAltitude = nil
        cameraHeading = nil
        cameraTilt = 0
        grandAltitude = nil
        
        let latitude = meta[DVRCNMETA_LATITUDE] as! Double?
        let longitude = meta[DVRCNMETA_LONGITUDE] as! Double?
        if (latitude != nil && longitude != nil){
            let viewLatitude = meta[DVRCNMETA_VIEW_LATITUDE] as! Double?
            let viewLongitude = meta[DVRCNMETA_VIEW_LONGITUDE] as! Double?
            let spanLatitude = meta[DVRCNMETA_SPAN_LATITUDE] as! Double?
            let spanLongitude = meta[DVRCNMETA_SPAN_LONGITUDE] as! Double?

            centerCoordinate = CLLocationCoordinate2DMake(viewLatitude!, viewLongitude!)
            photoCoordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
            mapSpan = MKCoordinateSpanMake(spanLatitude!, spanLongitude!)

            cameraAltitude = meta[DVRCNMETA_STAND_ALTITUDE] as! Double?
            cameraHeading = meta[DVRCNMETA_HEADING] as! Double?
            cameraTilt = meta[DVRCNMETA_TILT] as! CGFloat

            var nodeId = meta[DVRCNMETA_ID] as! [String]?;
            let theRoppongiAnnotation = MKPointAnnotation()
            theRoppongiAnnotation.coordinate = photoCoordinate!
            theRoppongiAnnotation.title = nodeId![nodeId!.count - 1]
            annotation = theRoppongiAnnotation
            mapView!.addAnnotation(annotation!)
            
            willStatToMove()
            moveToDefaultPosition(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - MKMapViewDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    private var isUpdatedLocation = false
    private var isLoadingData = false
    
    func willStatToMove() {
        let region = mapView!.region
        if (photoCoordinate!.latitude >= region.center.latitude - region.span.latitudeDelta &&
            photoCoordinate!.latitude <= region.center.latitude + region.span.latitudeDelta &&
            photoCoordinate!.longitude >= region.center.longitude - region.span.longitudeDelta &&
            photoCoordinate!.longitude <= region.center.longitude + region.span.longitudeDelta){
            isUpdatedLocation = false;
            isLoadingData = false;
        }else{
            isUpdatedLocation = true;
            isLoadingData = false;
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue(), {[unowned self]() -> Void in
                if (!self.isLoadingData){
                    self.isUpdatedLocation = false
                    self.moveToDefaultPosition(self)
                }
                })
        }
    }
    
    func mapViewWillStartLoadingMap(mapView: MKMapView) {
        if (isUpdatedLocation){
            isLoadingData = true
        }
    }
    
    func mapViewDidFinishLoadingMap(view: MKMapView){
        if (isUpdatedLocation){
            isUpdatedLocation = false
            moveToDefaultPosition(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図視点移動
    //-----------------------------------------------------------------------------------------
    private var centerCoordinate : CLLocationCoordinate2D? = nil
    private var photoCoordinate : CLLocationCoordinate2D? = nil
    private var mapSpan : MKCoordinateSpan? = nil
    private var cameraAltitude : Double? = nil
    private var cameraHeading : Double? = nil
    private var cameraTilt : CGFloat = 0
    private var grandAltitude : Double? = nil
    
    @IBAction func moveToDefaultPosition(sender : AnyObject?) {
        if (isUpdatedLocation){
            let region = MKCoordinateRegionMake(photoCoordinate!, mapSpan!)
            mapView!.setRegion(region, animated: true)
        }else{
            let camera = MKMapCamera();
            camera.centerCoordinate = centerCoordinate!
            camera.heading = cameraHeading == nil ? 0 : cameraHeading!
            camera.altitude = cameraAltitude!
            camera.pitch = cameraTilt
            
            mapView!.setCamera(camera, animated: true)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Google Maps Elevation APIを利用した標高取得
    //-----------------------------------------------------------------------------------------
    private var isRunningAltitudeTranslation : Bool = false
    private var translatingAltitude : Double? = nil
    private var translatingCoordinate : CLLocationCoordinate2D? = nil
    
    func scheduleAltitudeTranslation() {
        if (isRunningAltitudeTranslation ||
            (translatingCoordinate != nil && translatingCoordinate!.latitude == photoCoordinate!.latitude &&
             translatingCoordinate!.longitude == photoCoordinate!.longitude)){
            return
        }
        isRunningAltitudeTranslation = true;
        translatingAltitude = nil;
        translatingCoordinate = CLLocationCoordinate2DMake(photoCoordinate!.latitude, photoCoordinate!.longitude);
        let url = NSURL(string: "https://maps.googleapis.com/maps/api/elevation/json?" +
                                "locations=\(translatingCoordinate!.latitude),\(translatingCoordinate!.longitude)")
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let task = session.dataTaskWithURL(url!, completionHandler:{[unowned self](data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            var errorOccured = true
            if (data != nil){
                do{
                    let jsonData = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
                    if let results = jsonData["results"] as? NSArray {
                        if let resultSet = results[0] as? NSDictionary {
                            if let elevation = resultSet["elevation"] as? Double {
                                errorOccured = false
                                self.translatingAltitude = elevation
                            }
                        }
                    }
                }catch let error as NSError {
                    NSLog("%@", error)
                }
            }
            let mainQue = dispatch_get_main_queue()
            dispatch_async(mainQue, {[unowned self]() ->Void in
                self.isRunningAltitudeTranslation = false;
                if (!errorOccured &&
                    self.translatingCoordinate!.latitude == self.photoCoordinate!.latitude &&
                    self.translatingCoordinate!.longitude == self.photoCoordinate!.longitude){
                        self.translatingCoordinate = nil
                        self.grandAltitude = self.translatingAltitude
                        self.moveToDefaultPosition(self)
                }else{
                    self.scheduleAltitudeTranslation()
                }
            })
        })
        task.resume()
    }
}
