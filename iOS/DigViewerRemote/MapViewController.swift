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

class MapViewController: MapViewControllerBase, DVRemoteClientDelegate {
    
    @IBOutlet var barTitle : UINavigationItem? = nil
    @IBOutlet weak var toolbar: UIToolbar!

    private var initialized = false
    private var firstConnecting = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController!.presentsWithGesture = false
        splitViewController!.maximumPrimaryColumnWidth = 320
        
        navigationItem.hidesBackButton = true;
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        navigationController!.setNavigationBarHidden(true, animated: false)
        
        toolbar.layer.zPosition = 100
        summaryBar2nd.layer.zPosition = 1
        
        super.imageSelector = {
            [unowned self] (imageView) in
            self.performSegueWithIdentifier("FullImageView", sender: self)
        }

        mapView!.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "onLongPress:"))
        
        initMessageView()
    }
    
    deinit{
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        super.preferredStatusBarStyle()
        return UIStatusBarStyle.LightContent
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
            super.isLocalSession = client.isConnectedToLocal
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
        super.meta = meta
        super.thumbnail = client.thumbnail
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveCurrentThumbnail thumbnail: UIImage!) {
        super.thumbnail = thumbnail
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図データロード状況ごとの処理 (MKMapViewDelegateプロトコル)
    //-----------------------------------------------------------------------------------------
    override func mapViewDidFinishLoadingMap(view: MKMapView){
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
        
        super.mapViewDidFinishLoadingMap(view)
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
            NSOperationQueue.mainQueue().addOperationWithBlock {
                [unowned self]() in
                UIView.animateWithDuration(
                    0.5, delay: delay, options: UIViewAnimationOptions.CurveLinear, animations: {
                        [unowned self]() -> Void in
                        self.messageViewHeightConstraint.constant = height
                        self.view.layoutIfNeeded()
                    }, completion: nil)
            }
        }
    }
    
    func tapOnMessageView(recognizer: UIGestureRecognizer){
        showServersList()
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
                controller.addAction(UIAlertAction(
                    title: NSLocalizedString("SA_COPY_SUMMARY", comment: ""), style: .Default){
                        [unowned self](action: UIAlertAction) in
                        if self.meta != nil {
                            let summary = SummarizedMeta(meta: self.meta)
                            summary.copySummaryToPasteboard()
                        }
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
