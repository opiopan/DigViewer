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

    fileprivate var initialized = false
    fileprivate var firstConnecting = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController!.presentsWithGesture = false
        splitViewController!.maximumPrimaryColumnWidth = 320
        
        navigationItem.hidesBackButton = true;
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController!.setNavigationBarHidden(true, animated: false)
        
        toolbar.layer.zPosition = 100
        summaryBar2nd.layer.zPosition = 1
        
        super.imageSelector = {
            [unowned self] (imageView) in
            self.performSegue(withIdentifier: "FullImageView", sender: self)
        }

        mapView!.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.onLongPress(_:))))
        
        initMessageView()

        if !ConfigurationController.sharedController.mapNeedWarmUp {
            initialConnect()
        }
    }
    
    deinit{
        DVRemoteClient.shared().remove(self)
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        _ = super.preferredStatusBarStyle
        return UIStatusBarStyle.lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //-----------------------------------------------------------------------------------------
    // MARK: - 初回接続処理
    //-----------------------------------------------------------------------------------------
    fileprivate func initialConnect() {
        if (!initialized){
            initialized = true
            let client = DVRemoteClient.shared()
            client?.isInitialized = true
            client?.add(self)
            barTitle!.title = client?.state != .connected ? client?.stateString : client?.serviceName
            if let name = ConfigurationController.sharedController.establishedConnection {
                let time = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {() -> Void in
                    if name == "" {
                        client?.connectToLocal()
                    }else{
                        let service = NetService(domain: "local", type: DVR_SERVICE_TYPE, name: name);
                        let key = ConfigurationController.sharedController.authenticationgKeys[name];
                        client?.connect(toServer: service, withKey: key, fromDevice: AppDelegate.deviceID())
                    }
                })
            }else{
                firstConnecting = false;
                showServersList()
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 回転時対応
    //-----------------------------------------------------------------------------------------
    var isEnableDoublePane = true;
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let traitCollection = UIApplication.shared.keyWindow!.traitCollection
        let isReguler = traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular))
        let mode = splitViewController!.displayMode
        if size.width > size.height && isReguler {
            if mode != .primaryHidden {
                splitViewController!.preferredDisplayMode = .primaryHidden
            }
            if isEnableDoublePane {
                let time = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {[unowned self]() -> Void in
                    self.splitViewController!.preferredDisplayMode = .allVisible
                })
            }
        }else if size.height > size.width && isReguler {
            if mode != .primaryHidden {
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                splitViewController!.preferredDisplayMode = .primaryHidden
                UIView.commitAnimations()
            }
        }
    }
    
    // MARK: - ボタン応答
    //-----------------------------------------------------------------------------------------
    // Information ボタン
    //-----------------------------------------------------------------------------------------
    @IBAction func performInformationButton(_ sender : UIBarButtonItem) {
        let bounds = UIScreen.main.bounds
        let traitCollection = UIApplication.shared.keyWindow!.traitCollection
        let isReguler = traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular))
        if bounds.size.height > bounds.size.width {
            // 縦表示
            if isReguler {
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                splitViewController!.preferredDisplayMode = UISplitViewController.DisplayMode.primaryOverlay
                UIView.commitAnimations()
            }else{
                performSegue(withIdentifier: "ShowInformationView", sender: sender)
            }
        }else{
            // 横表示
            if isReguler {
                isEnableDoublePane = !isEnableDoublePane
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                splitViewController!.preferredDisplayMode = isEnableDoublePane ? .allVisible : .primaryHidden
                UIView.commitAnimations()
            }else{
                performSegue(withIdentifier: "ShowInformationView", sender: sender)
            }
        }
    }

    //-----------------------------------------------------------------------------------------
    // 次・前 ボタン
    //-----------------------------------------------------------------------------------------
    @IBAction func moveToNextImage(_ sender : AnyObject) {
        DVRemoteClient.shared()!.moveToNextImage()
    }
    
    @IBAction func moveToPreviousImage(_ sender : AnyObject) {
        DVRemoteClient.shared()!.moveToPreviousImage()
    }
    
    //-----------------------------------------------------------------------------------------
    // 設定ボタン
    //-----------------------------------------------------------------------------------------
    @IBAction func configureApp(_ sender : AnyObject) {
        let traitCollection = UIApplication.shared.keyWindow!.traitCollection
        let isReguler = traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular)) &&
            traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .regular))
        if isReguler {
            performSegue(withIdentifier: "PopoverConfigurationView", sender: sender)
        }else{
            performSegue(withIdentifier: "ModalConfigurationView", sender: sender)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // Serversリスト表示
    //-----------------------------------------------------------------------------------------
    fileprivate func showServersList() {
        isOpenServerList = true
        let traitCollection = UIApplication.shared.keyWindow!.traitCollection
        let isReguler = traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular)) &&
            traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .regular))
        if isReguler {
            performSegue(withIdentifier: "PopoverConfigurationView", sender: self)
        }else{
            performSegue(withIdentifier: "ModalConfigurationView", sender: self)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    fileprivate var pendingPairingKey : String? = nil
    
    func dvrClient(_ client: DVRemoteClient!, change state: DVRClientState) {
        updateMessageView()
        if client.state == .disconnected {
            pendingPairingKey = nil
        }
        if client.state == .disconnected && firstConnecting {
            firstConnecting = false
            showServersList()
        }else if client.state == .connected {
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
    
    func dvrClient(_ client: DVRemoteClient!, didRecievePairingKey key: String!, forServer service: NetService!) {
        pendingPairingKey = key
        let controller = ConfigurationController.sharedController
        var keys = controller.authenticationgKeys
        keys[service.name] = nil
        controller.authenticationgKeys = keys
     
        performSegue(withIdentifier: "ParingNotice", sender: self)
    }
    
    fileprivate var geocoder : CLGeocoder? = nil
    fileprivate var isGeocoding = false
    fileprivate var pendingGeocodingRecquest : CLLocation? = nil
    fileprivate var currentLocation : CLLocation? = nil
    fileprivate var placemark : CLPlacemark? = nil
    fileprivate var isFirst = true
    
    func dvrClient(_ client: DVRemoteClient!, didRecieveMeta meta: [AnyHashable: Any]!) {
        super.meta = meta
        super.thumbnail = client.thumbnail
    }
    
    func dvrClient(_ client: DVRemoteClient!, didRecieveCurrentThumbnail thumbnail: UIImage!) {
        super.thumbnail = thumbnail
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図データロード状況ごとの処理 (MKMapViewDelegateプロトコル)
    //-----------------------------------------------------------------------------------------
    override func mapViewDidFinishLoadingMap(_ view: MKMapView){
        initialConnect()
        super.mapViewDidFinishLoadingMap(view)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - メッセージウィンドウ・コントロール
    //-----------------------------------------------------------------------------------------
    @IBOutlet weak var messageView: MessageView!
    @IBOutlet weak var messageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    fileprivate var messageViewHeight : CGFloat = 0.0
    
    fileprivate func initMessageView() {
        messageView.layer.zPosition = 10.0
        messageViewHeight = messageViewHeightConstraint.constant

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapOnMessageView(_:)))
        messageView.addGestureRecognizer(recognizer)

        updateMessageView()
    }
    
    fileprivate func updateMessageView() {
        let client = DVRemoteClient.shared()
        if initialized {
            messageLabel.text = client?.state != .connected ? client?.stateString :
                AppDelegate.connectionName()
                //NSString(format: NSLocalizedString("MSGVIEW_ESTABLISHED", comment: ""), AppDelegate.connectionName()!) as String
        }else{
            messageLabel.text = NSLocalizedString("MSGVIEW_INITIALIIZING_MAP", comment: "")
        }
        let height = client?.state == .connected ? 0.0 : messageViewHeight
        let delay = client?.state == .connected ? 2.0 : 0.0
        if messageViewHeightConstraint.constant != height {
            OperationQueue.main.addOperation {
                [unowned self]() in
                UIView.animate(
                    withDuration: 0.5, delay: delay, options: UIView.AnimationOptions.curveLinear, animations: {
                        [unowned self]() -> Void in
                        self.messageViewHeightConstraint.constant = height
                        self.view.layoutIfNeeded()
                    }, completion: nil)
            }
        }
    }
    
    @objc func tapOnMessageView(_ recognizer: UIGestureRecognizer){
        showServersList()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 位置情報の共有
    //-----------------------------------------------------------------------------------------
    fileprivate var documentInteractionController : UIDocumentInteractionController!
    
    @objc func onLongPress(_ recognizer: UIGestureRecognizer){
        let rect = CGRect(origin: recognizer.location(in: self.view), size: CGSize.zero)
        
        if self.presentedViewController == nil {
            let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            if geometry != nil {
                controller.addAction(UIAlertAction(
                    title: NSLocalizedString("SA_SHARE_LOCATION", comment: ""), style: .default){
                        [unowned self](action: UIAlertAction) in
                        self.showLocationSharingSheet(rect)
                    }
                )
                controller.addAction(UIAlertAction(
                    title: NSLocalizedString("SA_SHARE_KML", comment: ""), style: .default){
                        [unowned self](action: UIAlertAction) in
                        self.showKMLSharingSheet(rect)
                    }
                )
                controller.addAction(UIAlertAction(
                    title: NSLocalizedString("SA_COPY_SUMMARY", comment: ""), style: .default){
                        [unowned self](action: UIAlertAction) in
                        if self.meta != nil {
                            let summary = SummarizedMeta(meta: self.meta)
                            summary.copySummaryToPasteboard()
                        }
                    }
                )
            }
            controller.addAction(UIAlertAction(
                title: NSLocalizedString("SA_SHARE_CANCEL", comment: ""), style: .cancel){(action: UIAlertAction) in}
            )
            if let popoverPresentationController = controller.popoverPresentationController {
                popoverPresentationController.sourceView = self.view
                popoverPresentationController.sourceRect = rect
            }
            if controller.actions.count > 1 {
                self.present(controller, animated: true){}
            }
        }
    }

    fileprivate func showLocationSharingSheet(_ rect : CGRect) {
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
            var items : [Any] = [
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
                let options : [String : Any] = [
                    MKLaunchOptionsMapTypeKey: mapType.rawValue,
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: span),
                    MKLaunchOptionsCameraKey: camera,
                ]
                mapItem.openInMaps(launchOptions: options)
            }
            let mapScale = geometry.spanLongitudeMeter / Double(mapView!.frame.size.width)
            let gmapActivity = CustomActivity(key: "CA_OPEN_GOOGLEMAPS", icon: UIImage(named: "action_open_googlemaps")!){
                let zoom = Int(max(0, min(19, round(log2(156543.033928 / mapScale)))))
                var url : URL
                if UIApplication.shared.canOpenURL(URL(string: "comgooglemapsurl://")!){
                    url = URL(string: "comgooglemapsurl://?ll=\(lat),\(lng)&z=\(zoom)&q=\(lat),\(lng)")!
                }else{
                    url = URL(string: "https://www.google.com/maps?ll=\(lat),\(lng)&z=\(zoom)&q=\(lat),\(lng)")!
                }
                UIApplication.shared.openURL(url)
            }
            let activities = [mapActivity, gmapActivity]
            
            // アクティビティビューの表示
            let controller = UIActivityViewController(activityItems: items, applicationActivities: activities)
            if let popoverPresentationController = controller.popoverPresentationController {
                popoverPresentationController.sourceView = self.view
                popoverPresentationController.sourceRect = rect
            }
            self.present(controller, animated: true){}
        }
    }
    
    fileprivate func showKMLSharingSheet(_ rect : CGRect) {
        if self.presentedViewController == nil && geometry != nil{
            let date = self.popupViewController!.dateLabel.text
            let kml = KMLFile(name: date!, geometry: self.geometry!)
            documentInteractionController = UIDocumentInteractionController(url: URL(fileURLWithPath: kml.path))
            documentInteractionController.delegate = self
            documentInteractionController.presentOpenInMenu(from: rect, in: self.view, animated: true)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Segueコントロール
    //-----------------------------------------------------------------------------------------
    fileprivate var isOpenServerList : Bool = false
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "PopoverConfigurationView" || segue.identifier == "ModalConfigurationView" {
            let controller = segue.destination as! PreferencesNavigationController
            controller.isOpenServerList = isOpenServerList
            controller.mapView = self.mapView
            isOpenServerList = false
        }else if segue.identifier! == "ParingNotice" {
            let controller = segue.destination as! PairingViewController
            var bounds = controller.view.bounds
            bounds.size.width *= 2
            controller.hashLabel.text = NSString(format: "%04d", Int(pendingPairingKey!)! % 10000) as String
        }
    }

}
