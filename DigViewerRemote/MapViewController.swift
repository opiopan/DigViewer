//
//  MapViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit
import DVremoteCommonLib
import DVremoteCommonUI

class MapViewController: UIViewController, DVRemoteClientDelegate, MKMapViewDelegate,
                         ConfigurationControllerDelegate, SummaryPopupViewControllerDelegate,
                         UIDocumentInteractionControllerDelegate {
    
    @IBOutlet var barTitle : UINavigationItem? = nil
    @IBOutlet var mapView : MKMapView? = nil
    @IBOutlet weak var toolbar: UIToolbar!

    private let configController = ConfigurationController.sharedController
    private var show3DView = true
    private var headingDisplayMode = ConfigurationController.sharedController.mapHeadingDisplay
    private var firstConnecting = true
    
    private var initialized = false
    
    private var annotationView : AnnotationView?
    private var popupViewController : SummaryPopupViewController?
    
    private var coverView : UIVisualEffectView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController!.presentsWithGesture = false
        splitViewController!.maximumPrimaryColumnWidth = 320
        
        navigationItem.hidesBackButton = true;
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        navigationController!.setNavigationBarHidden(true, animated: false)
        
        toolbar.layer.zPosition = 100
        summaryBar2nd.layer.zPosition = 1
        
        configController.registerObserver(self)
        show3DView = configController.map3DView
        
        popupViewController = storyboard!.instantiateViewControllerWithIdentifier("ImageSummaryPopup") as? SummaryPopupViewController
        if let view = popupViewController!.view {
            var frame = view.frame
            frame.size.width *= 2
        }
        let recognizer = UITapGestureRecognizer(target: self, action: "tapOnThumbnail:")
        popupViewController!.thumbnailView!.addGestureRecognizer(recognizer)
        popupViewController?.delegate = self
        
        mapView!.layer.zPosition = -1;
        mapView!.delegate = self
        mapView!.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "onLongPress:"))
        
        geocoder = CLGeocoder()
        
        coverView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        setBlurCover(true, isShowPopup: false)
        
        reflectUserDefaults()
        
        initMessageView()
        
        initSummaryBar()
    }
    
    deinit{
        DVRemoteClient.sharedClient().removeClientDelegate(self)
        configController.unregisterObserver(self)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - User Defaultsの反映
    //-----------------------------------------------------------------------------------------
    var pinColor = ConfigurationController.sharedController.mapPinColor
    var arrowColor = ConfigurationController.sharedController.mapArrowColor
    var fovColor = ConfigurationController.sharedController.mapFovColor
    var summaryMode = ConfigurationController.sharedController.mapSummaryDisplay
    var summaryPinningStyle = ConfigurationController.sharedController.mapSummaryPinningStyle
    
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
        
        if configController.mapHeadingDisplay != headingDisplayMode {
            headingDisplayMode = configController.mapHeadingDisplay
            addOverlay()
        }
        
        if configController.mapPinColor != pinColor {
            pinColor = configController.mapPinColor
            removeAnnotation()
            addAnnotation()
        }
        
        if configController.mapArrowColor != arrowColor || configController.mapFovColor != fovColor {
            arrowColor = configController.mapArrowColor
            fovColor = configController.mapFovColor
            removeOverlay()
            addOverlay()
        }
        
        if configController.mapSummaryDisplay != summaryMode {
            summaryMode = configController.mapSummaryDisplay
            arrangeSummaryBar()
        }
        
        if configController.mapSummaryPinningStyle != summaryPinningStyle {
            summaryPinningStyle = configController.mapSummaryPinningStyle
            arrangeSummaryBar()
        }
    }
    
    func notifyUpdateConfiguration(configuration: ConfigurationController) {
        reflectUserDefaults()
    }
    
    func notifyUpdateMapDetailConfiguration(configuration: ConfigurationController) {
        moveToDefaultPosition(self)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 回転時対応
    //-----------------------------------------------------------------------------------------
    var isEnableDoublePane = true;
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        let traitCollection = UIApplication.sharedApplication().keyWindow!.traitCollection
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
        let traitCollection = UIApplication.sharedApplication().keyWindow!.traitCollection
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
        let traitCollection = UIApplication.sharedApplication().keyWindow!.traitCollection
        let isReguler = traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular)) &&
            traitCollection.containsTraitsInCollection(UITraitCollection(verticalSizeClass: .Regular))
        if isReguler {
            performSegueWithIdentifier("PopoverConfigurationView", sender: sender)
        }else{
            performSegueWithIdentifier("ModalConfigurationView", sender: sender)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // Serversリスト表示
    //-----------------------------------------------------------------------------------------
    private func showServersList() {
        isOpenServerList = true
        let traitCollection = UIApplication.sharedApplication().keyWindow!.traitCollection
        let isReguler = traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular)) &&
            traitCollection.containsTraitsInCollection(UITraitCollection(verticalSizeClass: .Regular))
        if isReguler {
            performSegueWithIdentifier("PopoverConfigurationView", sender: self)
        }else{
            performSegueWithIdentifier("ModalConfigurationView", sender: self)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    private var pendingPairingKey : String? = nil
    
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        updateMessageView()
        if client.state == .Disconnected {
            pendingPairingKey = nil
        }
        if client.state == .Disconnected && firstConnecting {
            firstConnecting = false
            showServersList()
        }else if client.state == .Connected {
            firstConnecting = false
            if pendingPairingKey != nil {
                let controller = ConfigurationController.sharedController
                var keys = controller.authenticationgKeys
                keys[client.service.name] = pendingPairingKey
                controller.authenticationgKeys = keys
                pendingPairingKey = nil
            }
        }
    }
    
    func dvrClient(client: DVRemoteClient!, didRecievePairingKey key: String!, forServer service: NSNetService!) {
        pendingPairingKey = key
        let controller = ConfigurationController.sharedController
        var keys = controller.authenticationgKeys
        keys[service.name] = nil
        controller.authenticationgKeys = keys
     
        performSegueWithIdentifier("ParingNotice", sender: self)
    }
    
    private var geocoder : CLGeocoder? = nil
    private var isGeocoding = false
    private var pendingGeocodingRecquest : CLLocation? = nil
    private var currentLocation : CLLocation? = nil
    private var placemark : CLPlacemark? = nil
    private var isFirst = true
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        removeAnnotation()
        removeOverlay()
        geometry = nil
        placemark = nil
        
        if isFirst {
            isFirst = false
            arrangeSummaryBar()
        }

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
        }

        if meta[DVRCNMETA_LATITUDE] != nil {
            let isLocalSession = DVRemoteClient.sharedClient()!.isConnectedToLocal
            geometry = MapGeometry(meta: meta, viewSize: mapView!.bounds.size, isLocalSession: isLocalSession)

            // アノテーションセットアップ
            addAnnotation()
            
            // 逆ジオコーディング(経緯度→住所に変換)
            let GPSSummary = meta[DVRCNMETA_GPS_SUMMARY] as! NSArray?
            let latKV = GPSSummary![0] as! ImageMetadataKV
            let longKV = GPSSummary![1] as! ImageMetadataKV
            popupViewController!.addressLabel.text = NSString(format: "%@\n%@", latKV.value, longKV.value) as String
            currentLocation = CLLocation(latitude: geometry!.latitude, longitude: geometry!.longitude)
            performGeocoding(currentLocation!)

            // ブラーカバーを外す
            setBlurCover(false, isShowPopup: false)
            
            // 撮影地点に移動
            willStartToMove()
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
            if annotation != nil  && configController.mapSummaryDisplay == .Balloon {
                mapView!.selectAnnotation(annotation!, animated:true)
            }
        }
    }
    
    private func performGeocoding(location : CLLocation) {
        if !isGeocoding {
            isGeocoding = true
            geocoder!.reverseGeocodeLocation(location, completionHandler: {
                [unowned self](placemarks:[CLPlacemark]?, error : NSError?) -> Void in
                if placemarks != nil && placemarks!.count > 0 && self.pendingGeocodingRecquest == nil{
                    self.placemark = placemarks![0]
                    if self.currentLocation == location {
                        self.popupViewController!.addressLabel.text = self.recognizePlacemark(self.placemark!)
                    }
                }
                self.isGeocoding = false
                if let pending = self.pendingGeocodingRecquest {
                    self.pendingGeocodingRecquest = nil
                    self.performGeocoding(pending)
                }
            })
        }else{
            pendingGeocodingRecquest = location
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
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図データロード状況ごとの処理 (MKMapViewDelegateプロトコル)
    //-----------------------------------------------------------------------------------------
    private var isUpdatedLocation = false
    private var isLoadingData = false
    
    func willStartToMove() {
        let region = mapView!.region
        let camera = mapView!.camera
        var altitude = camera.altitude
        if !configController.map3DView {
            altitude *= Double(cos(configController.mapTilt))
        }
        if (geometry!.photoCoordinate.latitude >= region.center.latitude - region.span.latitudeDelta &&
            geometry!.photoCoordinate.latitude <= region.center.latitude + region.span.latitudeDelta &&
            geometry!.photoCoordinate.longitude >= region.center.longitude - region.span.longitudeDelta &&
            geometry!.photoCoordinate.longitude <= region.center.longitude + region.span.longitudeDelta &&
            geometry!.cameraAltitude > altitude * 0.5 && geometry!.cameraAltitude < altitude * 2){
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
            client.isInitialized = true
            client.addClientDelegate(self)
            barTitle!.title = client.state != .Connected ? client.stateString : client.serviceName
            if let name = ConfigurationController.sharedController.establishedConnection {
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue(), {() -> Void in
                    if name == "" {
                        client.connectToLocal()
                    }else{
                        let service = NSNetService(domain: "local", type: DVR_SERVICE_TYPE, name: name);
                        let key = ConfigurationController.sharedController.authenticationgKeys[name];
                        client.connectToServer(service, withKey: key, fromDevice: AppDelegate.deviceID())
                    }
                })
            }else{
                firstConnecting = false;
                showServersList()
            }
        }

        if (isUpdatedLocation){
            isUpdatedLocation = false
            moveToDefaultPosition(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図視点移動
    //-----------------------------------------------------------------------------------------
    private var geometry : MapGeometry? = nil
    
    @IBAction func moveToDefaultPosition(sender : AnyObject?) {
        let meta = DVRemoteClient.sharedClient().meta
        if meta[DVRCNMETA_LATITUDE] != nil {
            let isLocalSession = DVRemoteClient.sharedClient()!.isConnectedToLocal
            geometry = MapGeometry(meta: meta, viewSize: mapView!.bounds.size, isLocalSession: isLocalSession)
        }
        if (isUpdatedLocation || !configController.map3DView){
            if geometry != nil {
                let region = MKCoordinateRegionMake(geometry!.photoCoordinate, geometry!.mapSpan)
                mapView!.setRegion(region, animated: !isUpdatedLocation)
                if !isUpdatedLocation {
                    addOverlay()
                }
            }
        }else{
            if geometry != nil {
                let camera = MKMapCamera();
                camera.centerCoordinate = geometry!.centerCoordinate
                camera.heading = geometry!.cameraHeading
                camera.altitude = geometry!.cameraAltitude
                camera.pitch = CGFloat(geometry!.cameraTilt)
                
                mapView!.setCamera(camera, animated: true)
                addOverlay()
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - アノテーション制御
    //-----------------------------------------------------------------------------------------
    private var annotation : MKPointAnnotation? = nil

    private func addAnnotation() {
        if geometry != nil {
            (popupViewController!.view as! PopupView).showAnchor = true
            annotation = MKPointAnnotation()
            annotation!.coordinate = geometry!.photoCoordinate
            mapView!.addAnnotation(annotation!)
            if popupViewController!.thumbnailView.image != nil {
                let time = dispatch_time(DISPATCH_TIME_NOW, 0)
                dispatch_after(time, dispatch_get_main_queue(), {[unowned self]() -> Void in
                    if let annotation = self.annotation {
                        if self.configController.mapSummaryDisplay == .Balloon {
                            self.mapView!.selectAnnotation(annotation, animated:true)
                        }
                    }
                })
            }
        }
    }
    
    private func removeAnnotation() {
        if (annotation != nil){
            popupViewController!.updateCount++
            mapView!.removeAnnotation(annotation!)
            annotation = nil
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation === mapView.userLocation { // 現在地を示すアノテーションの場合はデフォルトのまま
            return nil
        } else {
            let identifier = "annotation"
            let summaryBarEnable = configController.mapSummaryDisplay == .Pinning
            if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? AnnotationView{
                // 再利用できる場合はそのまま返す
                annotationView.calloutViewController = summaryBarEnable ? nil : popupViewController
                annotationView.pinTintColor = configController.mapPinColor
                return annotationView
            } else { // 再利用できるアノテーションが無い場合（初回など）は生成する
                let annotationView = AnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.calloutViewController = summaryBarEnable ? nil : popupViewController
                annotationView.pinTintColor = configController.mapPinColor
                return annotationView
            }
        }
    }
    
    func viewFullImage(sender: AnyObject) {
        performSegueWithIdentifier("FullImageView", sender: sender)
    }

    func tapOnThumbnail(recognizer: UIGestureRecognizer){
        viewFullImage(self)
    }
    
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 撮影方向オーバーレイ制御
    //-----------------------------------------------------------------------------------------
    private func addOverlay() {
        removeOverlay()
        if geometry != nil && geometry!.heading != nil {
            let size = MapGeometry.mapToSize(mapView!)
            let hScale = Double(min(size.width, size.height)) / 2
            let vScale =  hScale / cos(Double(mapView!.camera.pitch) / 180 * M_PI)
            let overlay = HeadingOverlay(
                center: geometry!.photoCoordinate, heading: geometry!.heading!, fov: geometry!.fovAngle,
                vScale: vScale, hScale: hScale)
            overlay.altitude = mapView!.camera.altitude
            mapView!.addOverlay(overlay, level: .AboveLabels)
        }
    }
    
    private func removeOverlay() {
        for overlay in mapView!.overlays {
            mapView!.removeOverlay(overlay)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        var altitude : Double = 0
        if mapView.overlays.count > 0 {
            altitude = (mapView.overlays[0] as? HeadingOverlay)!.altitude
        }
        if altitude < mapView.camera.altitude * 0.9 || altitude > mapView.camera.altitude * 1.1 {
            addOverlay()
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        return HeadingOverlayRenderer(overlay: overlay)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ブラーカバーの制御
    //-----------------------------------------------------------------------------------------
    private func setBlurCover(isShow : Bool, isShowPopup : Bool) {
        if isShow && coverView!.superview == nil {
            //coverView!.frame = self.view.bounds
            let childView = coverView!
            childView.translatesAutoresizingMaskIntoConstraints = false
            mapView!.addSubview(childView)
            childView.layer.zPosition = 1
            let viewDictionary = ["childView": childView]
            let constraints = NSMutableArray()
            let constraintFormat1 =
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "H:|-[childView]-|",
                    options : NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: viewDictionary)
            constraints.addObjectsFromArray(constraintFormat1)
            let constraintFormat2 =
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "V:|-[childView]-|",
                    options : NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: viewDictionary)
            constraints.addObjectsFromArray(constraintFormat2)
            mapView!.addConstraints((constraints as NSArray as? [NSLayoutConstraint])!)
        }else if !isShow && coverView!.superview != nil {
            if popupViewController!.view.superview != nil && popupViewController!.view.superview == coverView {
                popupViewController!.removeFromSuperView()
            }
            coverView!.removeFromSuperview()
        }

        if isShow && isShowPopup && configController.mapSummaryDisplay == .Balloon {
            if popupViewController!.view.superview != nil && popupViewController!.view.superview != coverView {
                popupViewController!.removeFromSuperView()
            }
            if popupViewController!.view.superview == nil {
                popupViewController!.addToSuperView(coverView!, parentType: .NoLocationCover)
                popupViewController!.view.alpha = 1.0
                popupViewController!.updateCount++
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - メッセージウィンドウ・コントロール
    //-----------------------------------------------------------------------------------------
    @IBOutlet weak var messageView: MessageView!
    @IBOutlet weak var messageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    private var messageViewHeight : CGFloat = 0.0
    
    private func initMessageView() {
        messageView.layer.zPosition = 10.0
        messageViewHeight = messageViewHeightConstraint.constant

        let recognizer = UITapGestureRecognizer(target: self, action: "tapOnMessageView:")
        messageView.addGestureRecognizer(recognizer)

        updateMessageView()
    }
    
    private func updateMessageView() {
        let client = DVRemoteClient.sharedClient()
        if initialized {
            messageLabel.text = client.state != .Connected ? client.stateString :
                AppDelegate.connectionName()
                //NSString(format: NSLocalizedString("MSGVIEW_ESTABLISHED", comment: ""), AppDelegate.connectionName()!) as String
        }else{
            messageLabel.text = NSLocalizedString("MSGVIEW_INITIALIIZING_MAP", comment: "")
        }
        let height = client.state == .Connected ? 0.0 : messageViewHeight
        let delay = client.state == .Connected ? 2.0 : 0.0
        if messageViewHeightConstraint.constant != height {
            UIView.animateWithDuration(
                0.5, delay: delay, options: UIViewAnimationOptions.CurveLinear, animations: {
                    [unowned self]() -> Void in
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        [unowned self]() in
                        self.messageViewHeightConstraint.constant = height
                        self.view.layoutIfNeeded()
                    }
                }, completion: nil)
        }
    }
    
    func tapOnMessageView(recognizer: UIGestureRecognizer){
        showServersList()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - サマリバーコントロール
    //-----------------------------------------------------------------------------------------
    @IBOutlet weak var summaryBar: UIView!
    @IBOutlet weak var summaryBarPosition: NSLayoutConstraint!

    @IBOutlet weak var summaryBarPlaceholder: UIView!
    @IBOutlet weak var summaryBarPlaceholderHeight: NSLayoutConstraint!
    
    @IBOutlet weak var summaryBar2nd: UIView!
    @IBOutlet weak var summaryBar2ndPosition: NSLayoutConstraint!
    
    @IBOutlet weak var summaryBarLeftPlaceholder: UIView!
    @IBOutlet weak var summaryBarLeftPlaceholderHeight: NSLayoutConstraint!
    @IBOutlet weak var summaryBarLeftPlaceholderWidth: NSLayoutConstraint!
    
    @IBOutlet weak var summaryBarRightPlaceholder: UIView!
    @IBOutlet weak var summaryBarRightPlaceholderHeight: NSLayoutConstraint!
    @IBOutlet weak var summaryBarRightPlaceholderWidth: NSLayoutConstraint!
    
    private var summaryBarPositionDefault: CGFloat = 0
    private var summaryBar2ndPositionDefault: CGFloat = 0
    
    func initSummaryBar() {
        summaryBarPositionDefault = summaryBarPosition.constant
        summaryBar2ndPositionDefault = summaryBar2ndPosition.constant
    }
    
    func arrangeSummaryBar() {
        if configController.mapSummaryDisplay != .Pinning {
            popupViewController?.removeFromSuperView()
            popupViewController?.pinMode = .Off
            summaryBarPosition.constant = summaryBarPositionDefault
            summaryBar2ndPosition.constant = summaryBar2ndPositionDefault
            if coverView?.superview != nil {
                popupViewController?.addToSuperView(coverView!, parentType: .NoLocationCover)
            }else{
                removeAnnotation()
                addAnnotation()
            }
            
        }else{
            if coverView?.superview != nil {
                popupViewController?.removeFromSuperView()
            }else{
                removeAnnotation()
                addAnnotation()
            }
            if configController.mapSummaryPinningStyle == .InToolBar {
                summaryBarPlaceholderHeight.constant = popupViewController!.viewHeight
                summaryBarPosition.constant = summaryBarPositionDefault + popupViewController!.viewBaseHeight
                summaryBar2ndPosition.constant = summaryBar2ndPositionDefault
                popupViewController?.pinMode = .Toolbar
                popupViewController?.addToSuperView(summaryBarPlaceholder, parentType: .NoLocationCover)
            }else if configController.mapSummaryPinningStyle == .LowerLeft {
                summaryBarLeftPlaceholderHeight.constant = popupViewController!.viewHeight
                summaryBarLeftPlaceholderWidth.constant = popupViewController!.viewWidth
                summaryBarPosition.constant = summaryBarPositionDefault
                summaryBar2ndPosition.constant = summaryBar2ndPositionDefault + popupViewController!.viewBaseHeight
                popupViewController?.pinMode = .Left
                popupViewController?.addToSuperView(summaryBarLeftPlaceholder, parentType: .NoLocationCover)
            }else{
                summaryBarRightPlaceholderHeight.constant = popupViewController!.viewHeight
                summaryBarRightPlaceholderWidth.constant = popupViewController!.viewWidth
                summaryBarPosition.constant = summaryBarPositionDefault
                summaryBar2ndPosition.constant = summaryBar2ndPositionDefault + popupViewController!.viewBaseHeight
                popupViewController?.pinMode = .Right
                popupViewController?.addToSuperView(summaryBarRightPlaceholder, parentType: .NoLocationCover)
            }
        }
    }
    
    func summaryPopupViewControllerPushedPinButton(controller: SummaryPopupViewController) {
        if configController.mapSummaryDisplay == .Pinning {
            configController.mapSummaryDisplay = .Balloon
        }else{
            configController.mapSummaryDisplay = .Pinning
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 位置情報の共有
    //-----------------------------------------------------------------------------------------
    private var documentInteractionController : UIDocumentInteractionController!
    
    func onLongPress(recognizer: UIGestureRecognizer){
        let rect = CGRect(origin: recognizer.locationInView(self.view), size: CGSizeZero)
        
        if self.presentedViewController == nil {
            let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            if geometry != nil {
                controller.addAction(UIAlertAction(
                    title: NSLocalizedString("SA_SHARE_LOCATION", comment: ""), style: .Default){
                        [unowned self](action: UIAlertAction) in
                        self.showLocationSharingSheet(rect)
                    }
                )
                controller.addAction(UIAlertAction(
                    title: NSLocalizedString("SA_SHARE_KML", comment: ""), style: .Default){
                        [unowned self](action: UIAlertAction) in
                        self.showKMLSharingSheet(rect)
                    }
                )
            }
            controller.addAction(UIAlertAction(
                title: NSLocalizedString("SA_SHARE_CANCEL", comment: ""), style: .Cancel){(action: UIAlertAction) in}
            )
            if let popoverPresentationController = controller.popoverPresentationController {
                popoverPresentationController.sourceView = self.view
                popoverPresentationController.sourceRect = rect
            }
            if controller.actions.count > 1 {
                self.presentViewController(controller, animated: true){}
            }
        }
    }

    private func showLocationSharingSheet(rect : CGRect) {
        if let geometry = self.geometry {
            let lat = geometry.latitude
            let lng = geometry.longitude
            let title = popupViewController!.dateLabel.text

            // 共有データ構築
            var text = "\(title!)\n"
            if let camera = popupViewController!.cameraLabel.text {
                text += "\(camera)\n"
            }
            if let lens = popupViewController!.lensLabel.text {
                text += "\(lens)\n"
            }
            if let condition = popupViewController!.conditionLabel.text {
                text += "\(condition)\n"
            }
            if let address = popupViewController!.addressLabel.text {
                text += "\(address)\n"
            }
            let mapUrl = MapURL(geometry: geometry, title: popupViewController!.addressLabel.text!)
            var items : [AnyObject] = [
                text,
                mapUrl,
            ]
            if let thumbnail = popupViewController!.thumbnailView.image {
                items.append(thumbnail)
            }
            
            // カスタムアクティビティの設定
            let mapType = mapView!.mapType
            let mapActivity = CustomActivity(key: "CA_OPEN_MAP", icon: UIImage(named: "action_open_map")!){
                let placeMark = MKPlacemark(
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), addressDictionary: nil)
                let mapItem = MKMapItem(placemark: placeMark)
                mapItem.name = title
                let span = MKCoordinateSpan(latitudeDelta: geometry.spanLatitude, longitudeDelta: geometry.spanLongitude)
                let camera = MKMapCamera();
                camera.centerCoordinate = geometry.centerCoordinate
                camera.heading = geometry.cameraHeading
                camera.altitude = geometry.cameraAltitude
                camera.pitch = CGFloat(geometry.cameraTilt)
                let options = [
                    MKLaunchOptionsMapTypeKey: mapType.rawValue,
                    MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: span),
                    MKLaunchOptionsCameraKey: camera,
                ]
                mapItem.openInMapsWithLaunchOptions(options)
            }
            let mapScale = geometry.spanLongitudeMeter / Double(mapView!.frame.size.width)
            let gmapActivity = CustomActivity(key: "CA_OPEN_GOOGLEMAPS", icon: UIImage(named: "action_open_googlemaps")!){
                let zoom = Int(max(0, min(19, round(log2(156543.033928 / mapScale)))))
                var url : NSURL
                if UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemapsurl://")!){
                    url = NSURL(string: "comgooglemapsurl://?ll=\(lat),\(lng)&z=\(zoom)&q=\(lat),\(lng)")!
                }else{
                    url = NSURL(string: "https://www.google.com/maps?ll=\(lat),\(lng)&z=\(zoom)&q=\(lat),\(lng)")!
                }
                UIApplication.sharedApplication().openURL(url)
            }
            let activities = [mapActivity, gmapActivity]
            
            // アクティビティビューの表示
            let controller = UIActivityViewController(activityItems: items, applicationActivities: activities)
            if let popoverPresentationController = controller.popoverPresentationController {
                popoverPresentationController.sourceView = self.view
                popoverPresentationController.sourceRect = rect
            }
            self.presentViewController(controller, animated: true){}
        }
    }
    
    private func showKMLSharingSheet(rect : CGRect) {
        if self.presentedViewController == nil && geometry != nil{
            let date = self.popupViewController!.dateLabel.text
            let kml = KMLFile(name: date!, geometry: self.geometry!)
            documentInteractionController = UIDocumentInteractionController(URL: NSURL(fileURLWithPath: kml.path))
            documentInteractionController.delegate = self
            documentInteractionController.presentOpenInMenuFromRect(rect, inView: self.view, animated: true)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Segueコントロール
    //-----------------------------------------------------------------------------------------
    private var isOpenServerList : Bool = false
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier! == "PopoverConfigurationView" || segue.identifier == "ModalConfigurationView" {
            let controller = segue.destinationViewController as! PreferencesNavigationController
            controller.isOpenServerList = isOpenServerList
            controller.mapView = self.mapView
            isOpenServerList = false
        }else if segue.identifier! == "ParingNotice" {
            let controller = segue.destinationViewController as! PairingViewController
            var bounds = controller.view.bounds
            bounds.size.width *= 2
            controller.hashLabel.text = NSString(format: "%04d", Int(pendingPairingKey!)! % 10000) as String
        }
    }

}
