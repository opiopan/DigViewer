//
//  MapViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, DVRemoteClientDelegate, MKMapViewDelegate, ConfigurationControllerDelegate {
    
    @IBOutlet var barTitle : UINavigationItem? = nil
    @IBOutlet var mapView : MKMapView? = nil

    private let configController = ConfigurationController.sharedController
    private var show3DView = true
    private var firstConnecting = true
    
    private var thumbnailView : UIImageView? = nil
    
    private var initialized = false
    
    private var annotationView : AnnotationView?
    private var popupViewController : SummaryPopupViewController?
    
    private var coverView : UIVisualEffectView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController!.maximumPrimaryColumnWidth = 320
        
        navigationItem.hidesBackButton = true;
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        //navigationController?.hidesBarsOnTap = true
        
        configController.registerObserver(self)
        show3DView = configController.map3DView
        
        thumbnailView = UIImageView.init(frame: CGRectMake(0, 0, 64, 64));
        thumbnailView!.contentMode = UIViewContentMode.ScaleAspectFill
        
        popupViewController = storyboard!.instantiateViewControllerWithIdentifier("ImageSummaryPopup") as? SummaryPopupViewController
        if let popupView = popupViewController?.view{
            var popupFrame = popupView.frame
            popupFrame.size.width = 350
            popupFrame.size.height = 150
            //popupView.frame = popupFrame
        }
        
        mapView!.layer.zPosition = -1;
        mapView!.delegate = self
        
        geocoder = CLGeocoder()
        
        coverView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        setBlurCover(true, isShowPopup: false)
        
        reflectUserDefaults()

    }
    
    deinit{
        DVRemoteClient.sharedClient().removeClientDelegate(self)
        configController.unregisterObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - User Defaultsの反映
    //-----------------------------------------------------------------------------------------
    func reflectUserDefaults() {
        if configController.mapType == .Map {
            mapView!.mapType = .Standard
        }else{
            mapView!.mapType = configController.mapShowLabel ? .HybridFlyover : .SatelliteFlyover
        }
        
        if configController.map3DView != show3DView {
            show3DView = configController.map3DView
            moveToDefaultPosition(self)
        }
    }
    
    func notifyUpdateConfiguration(configuration: ConfigurationController) {
        reflectUserDefaults()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 回転時対応
    //-----------------------------------------------------------------------------------------
    var isEnableDoublePane = true;
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        var frame = self.view.bounds
        frame.size.width = max(size.width, size.height)
        frame.size.height = max(size.width, size.height)
        coverView!.frame = frame
        arrangePopupInBlurCover()
        
        let isReguler = traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular))
        let mode = splitViewController!.displayMode
        if size.width > size.height && isReguler {
            if mode != .PrimaryHidden {
                splitViewController!.preferredDisplayMode = .PrimaryHidden
            }
            if isEnableDoublePane {
                let time = dispatch_time(DISPATCH_TIME_NOW, 0)
                dispatch_after(time, dispatch_get_main_queue(), {[unowned self]() -> Void in
                    self.splitViewController!.preferredDisplayMode = .AllVisible
                })
            }
        }else if size.height > size.width && isReguler {
            if mode != .PrimaryHidden {
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                splitViewController!.preferredDisplayMode = .PrimaryHidden
                UIView.commitAnimations()
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
        if bounds.size.height > bounds.size.width {
            // 縦表示
            if isReguler {
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay
                UIView.commitAnimations()
            }else{
                performSegueWithIdentifier("ShowInformationView", sender: sender)
            }
        }else{
            // 横表示
            if isReguler {
                isEnableDoublePane = !isEnableDoublePane
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                splitViewController!.preferredDisplayMode = isEnableDoublePane ? .AllVisible : .PrimaryHidden
                UIView.commitAnimations()
            }else{
                performSegueWithIdentifier("ShowInformationView", sender: sender)
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
    // 設定ボタン
    //-----------------------------------------------------------------------------------------
    @IBAction func configureApp(sender : AnyObject) {
        let isReguler = traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular)) &&
            traitCollection.containsTraitsInCollection(UITraitCollection(verticalSizeClass: .Regular))
        if isReguler {
            performSegueWithIdentifier("PopoverConfigurationView", sender: sender)
        }else{
            performSegueWithIdentifier("ModalConfigurationView", sender: sender)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        barTitle!.title = client.state != .Connected ? client.stateString : client.service.name
        if client.state == .Disconnected && firstConnecting {
            performServersButton(self)
            firstConnecting = false;
        }else if client.state == .Connected {
            firstConnecting = false;
        }
    }
    
    private var annotation : MKPointAnnotation? = nil
    private var geocoder : CLGeocoder? = nil
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        if (annotation != nil){
            popupViewController!.updateCount++
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

        // ポップアップウィンドウセットアップ
        popupViewController!.dateLabel.text = nil
        popupViewController!.cameraLabel.text = nil
        popupViewController!.lensLabel.text = nil
        popupViewController!.conditionLabel.text = nil
        popupViewController!.addressLabel.text = nil
        if let popupSummary = meta[DVRCNMETA_POPUP_SUMMARY] as! [ImageMetadataKV]? {
            if popupSummary.count > 0 {
                popupViewController!.dateLabel.text = popupSummary[0].value
            }
            if popupSummary.count > 2 {
                popupViewController!.cameraLabel.text = popupSummary[2].value
            }
            if popupSummary.count > 3 {
                popupViewController!.lensLabel.text = popupSummary[3].value
            }
            var condition : String = ""
            for var i = 5; i < popupSummary.count; i++ {
                if condition == "" {
                    condition = popupSummary[i].value
                }else if let value = popupSummary[i].value {
                    condition = condition + " " + value
                }
            }
            popupViewController!.conditionLabel.text = condition
            popupViewController!.addressLabel.text = nil
            popupViewController!.thumbnailView.image = client.thumbnail
            thumbnailView!.image = client.thumbnail;
        }

        let latitude = meta[DVRCNMETA_LATITUDE] as! Double?
        let longitude = meta[DVRCNMETA_LONGITUDE] as! Double?
        if (latitude != nil && longitude != nil){
            let viewLatitude = meta[DVRCNMETA_VIEW_LATITUDE] as! Double?
            let viewLongitude = meta[DVRCNMETA_VIEW_LONGITUDE] as! Double?
            let spanLatitude = meta[DVRCNMETA_SPAN_LATITUDE] as! Double?
            let spanLongitude = meta[DVRCNMETA_SPAN_LONGITUDE] as! Double?

            // 視点セットアップ
            centerCoordinate = CLLocationCoordinate2DMake(viewLatitude!, viewLongitude!)
            photoCoordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
            mapSpan = MKCoordinateSpanMake(spanLatitude!, spanLongitude!)

            cameraAltitude = meta[DVRCNMETA_STAND_ALTITUDE] as! Double?
            cameraHeading = meta[DVRCNMETA_HEADING] as! Double?
            cameraTilt = meta[DVRCNMETA_TILT] as! CGFloat

            // アノテーションセットアップ
            (popupViewController!.view as! PopupView).showAnchor = true
            var nodeId = meta[DVRCNMETA_ID] as! [String]?;
            annotation = MKPointAnnotation()
            annotation!.coordinate = photoCoordinate!
            annotation!.title = nodeId![nodeId!.count - 1]
            mapView!.addAnnotation(annotation!)
//            mapView!.selectAnnotation(annotation!, animated:true)
            
            // 逆ジオコーディング(経緯度→住所に変換)
            let location = CLLocation(latitude: latitude!, longitude: longitude!)
            geocoder!.reverseGeocodeLocation(location, completionHandler: {
                [unowned self](placemarks:[CLPlacemark]?, error : NSError?) -> Void in
                if placemarks != nil && placemarks!.count > 0 {
                    let placemark = placemarks![0]
                    self.popupViewController!.addressLabel.text = self.recognizePlacemark(placemark)
                }
            })

            // ブラーカバーを外す
            setBlurCover(false, isShowPopup: false)
            
            // 撮影地点に移動
            willStatToMove()
            moveToDefaultPosition(self)
        }else{
            popupViewController!.addressLabel.text = NSLocalizedString("ADDRESS_NA", comment: "")
            (popupViewController!.view as! PopupView).showAnchor = false
            setBlurCover(true, isShowPopup: true)
        }
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveCurrentThumbnail thumbnail: UIImage!) {
        if popupViewController!.thumbnailView!.image == nil {
            popupViewController!.thumbnailView!.image = thumbnail
            if annotation != nil {
                mapView!.selectAnnotation(annotation!, animated:true)
            }
        }
    }
    
    private func recognizePlacemark(placemark : CLPlacemark) -> String? {
        var address : String? = nil
        
        let interest = placemark.areasOfInterest
        if interest != nil && interest!.count > 0 {
            address = interest![interest!.count - 1]
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
        if (!initialized){
            initialized = true
            let client = DVRemoteClient.sharedClient()
            client.addClientDelegate(self)
            barTitle!.title = client.state != .Connected ? client.stateString : client.service.name
            if let name = ConfigurationController.sharedController.establishedConnection {
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue(), {() -> Void in
                    client.connectToServer(NSNetService(domain: "local", type: DVR_SERVICE_TYPE, name: name))
                })
            }else{
                firstConnecting = false;
                self.performServersButton(self)
            }
        }

        if (isUpdatedLocation){
            isUpdatedLocation = false
            moveToDefaultPosition(self)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation === mapView.userLocation { // 現在地を示すアノテーションの場合はデフォルトのまま
            return nil
        } else {
            let identifier = "annotation"
            if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("annotation") { // 再利用できる場合はそのまま返す
                return annotationView
            } else { // 再利用できるアノテーションが無い場合（初回など）は生成する
                let annotationView = AnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.calloutViewController = popupViewController
                return annotationView
            }
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
        if (isUpdatedLocation || !configController.map3DView){
            if photoCoordinate != nil && mapSpan != nil {
                let region = MKCoordinateRegionMake(photoCoordinate!, mapSpan!)
                mapView!.setRegion(region, animated: !configController.map3DView)
            }
        }else{
            if centerCoordinate != nil && cameraAltitude != nil {
                let camera = MKMapCamera();
                camera.centerCoordinate = centerCoordinate!
                camera.heading = cameraHeading == nil ? 0 : cameraHeading!
                camera.altitude = cameraAltitude!
                camera.pitch = cameraTilt
                
                mapView!.setCamera(camera, animated: true)
            }
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
    
    //-----------------------------------------------------------------------------------------
    // MARK: - アノテーションカスタマイズ
    //-----------------------------------------------------------------------------------------
//    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]){
//        for view : MKAnnotationView in views {
//            view.leftCalloutAccessoryView = thumbnailView!
//            let button = UIButton.init(type:UIButtonType.DetailDisclosure)
//            button.addTarget(self, action: "viewFullImage:", forControlEvents: .TouchUpInside)
//            view.rightCalloutAccessoryView = button
//        }
//    }
    
    func viewFullImage(sender: AnyObject) {
        performSegueWithIdentifier("FullImageView", sender: sender)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ブラーカバーの制御
    //-----------------------------------------------------------------------------------------
    private func setBlurCover(isShow : Bool, isShowPopup : Bool) {
        if isShow && coverView!.superview == nil {
            coverView!.frame = self.view.bounds
            mapView!.addSubview(coverView!)
            coverView!.layer.zPosition = 1
        }else if !isShow && coverView!.superview != nil {
            if popupViewController!.view.superview != nil && popupViewController!.view.superview == coverView {
                popupViewController!.view.removeFromSuperview()
            }
            coverView!.removeFromSuperview()
        }

        if isShow && isShowPopup {
            if popupViewController!.view.superview != nil && popupViewController!.view.superview != coverView {
                popupViewController!.view.removeFromSuperview()
            }
            if popupViewController!.view.superview == nil {
                coverView!.addSubview(popupViewController!.view)
                popupViewController!.view.alpha = 1.0
                popupViewController!.updateCount++
                arrangePopupInBlurCover()
            }
        }
    }
    
    private func arrangePopupInBlurCover(){
        if popupViewController!.view.superview != nil && popupViewController!.view.superview == coverView {
            var frame = popupViewController!.view.frame
            frame.origin.x = (mapView!.bounds.width - frame.size.width) * 0.5
            frame.origin.y = (mapView!.bounds.height - frame.size.height) * 0.5
            popupViewController!.view.frame = frame
        }
    }
}
