//
//  MapViewControllerBase.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit
import DVremoteCommonLib

public class MapViewControllerBase: UIViewController, MKMapViewDelegate,
                                    ConfigurationControllerDelegate, SummaryPopupViewControllerDelegate,
                                    UIDocumentInteractionControllerDelegate {
    
    @IBOutlet public var mapView : MKMapView? = nil

    private let configController = ConfigurationController.sharedController
    private var show3DView = true
    private var headingDisplayMode = ConfigurationController.sharedController.mapHeadingDisplay
    
    private var annotationView : AnnotationView?
    public var popupViewController : SummaryPopupViewController?
    
    private var coverView : UIVisualEffectView?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        geocoder = CLGeocoder()
        
        coverView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        setBlurCover(true, isShowPopup: false)
        
        reflectUserDefaults()
        
        initSummaryBar()
    }
    
    deinit{
        configController.unregisterObserver(self)
    }

    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - User Defaultsの反映
    //-----------------------------------------------------------------------------------------
    public var pinColor = ConfigurationController.sharedController.mapPinColor
    public var arrowColor = ConfigurationController.sharedController.mapArrowColor
    public var fovColor = ConfigurationController.sharedController.mapFovColor
    public var summaryMode = ConfigurationController.sharedController.mapSummaryDisplay
    public var summaryPinningStyle = ConfigurationController.sharedController.mapSummaryPinningStyle
    
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
    
    public func notifyUpdateConfiguration(configuration: ConfigurationController) {
        reflectUserDefaults()
    }
    
    public func notifyUpdateMapDetailConfiguration(configuration: ConfigurationController) {
        moveToDefaultPosition(self)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - メタデータ＆サムネール設定
    //-----------------------------------------------------------------------------------------
    private var geocoder : CLGeocoder? = nil
    private var isGeocoding = false
    private var pendingGeocodingRecquest : CLLocation? = nil
    private var currentLocation : CLLocation? = nil
    private var placemark : CLPlacemark? = nil
    private var isFirst = true
    
    public var isLocalSession : Bool = false
    
    public var meta: [NSObject : AnyObject]! {
        didSet{
            self.thumbnail = nil
            popupViewController!.thumbnailView!.image = nil
            
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
                popupViewController!.thumbnailView.image = self.thumbnail
            }
            
            if meta[DVRCNMETA_LATITUDE] != nil {
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
    }
    
    public var thumbnail: UIImage! = nil {
        didSet{
            if popupViewController!.thumbnailView!.image == nil {
                popupViewController!.thumbnailView!.image = thumbnail
                if annotation != nil  && configController.mapSummaryDisplay == .Balloon {
                    mapView!.selectAnnotation(annotation!, animated:true)
                }
            }
        }
    }
    
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 住所取得 (逆ジオコーディング)
    //-----------------------------------------------------------------------------------------
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
    
    public func mapViewWillStartLoadingMap(mapView: MKMapView) {
        if (isUpdatedLocation){
            isLoadingData = true
        }
    }
    
    public func mapViewDidFinishLoadingMap(view: MKMapView){
        if (isUpdatedLocation){
            isUpdatedLocation = false
            moveToDefaultPosition(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図視点移動
    //-----------------------------------------------------------------------------------------
    public var geometry : MapGeometry? = nil
    
    @IBAction public func moveToDefaultPosition(sender : AnyObject?) {
        if meta[DVRCNMETA_LATITUDE] != nil {
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
    
    public func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
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
    
    public var imageSelector : ((UIImageView) -> Void)? = nil

    public func viewFullImage(sender: AnyObject) {
        if let selector = imageSelector {
            selector(popupViewController!.thumbnailView)
        }
    }

    public func tapOnThumbnail(recognizer: UIGestureRecognizer){
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
    
    public func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        var altitude : Double = 0
        if mapView.overlays.count > 0 {
            altitude = (mapView.overlays[0] as? HeadingOverlay)!.altitude
        }
        if altitude < mapView.camera.altitude * 0.9 || altitude > mapView.camera.altitude * 1.1 {
            addOverlay()
        }
    }
    
    public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
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
    // MARK: - サマリバーコントロール
    //-----------------------------------------------------------------------------------------
    @IBOutlet public weak var summaryBar: UIView!
    @IBOutlet public weak var summaryBarPosition: NSLayoutConstraint!

    @IBOutlet public weak var summaryBarPlaceholder: UIView!
    @IBOutlet public weak var summaryBarPlaceholderHeight: NSLayoutConstraint!
    
    @IBOutlet public weak var summaryBar2nd: UIView!
    @IBOutlet public weak var summaryBar2ndPosition: NSLayoutConstraint!
    
    @IBOutlet public weak var summaryBarLeftPlaceholder: UIView!
    @IBOutlet public weak var summaryBarLeftPlaceholderHeight: NSLayoutConstraint!
    @IBOutlet public weak var summaryBarLeftPlaceholderWidth: NSLayoutConstraint!
    
    @IBOutlet public weak var summaryBarRightPlaceholder: UIView!
    @IBOutlet public weak var summaryBarRightPlaceholderHeight: NSLayoutConstraint!
    @IBOutlet public weak var summaryBarRightPlaceholderWidth: NSLayoutConstraint!
    
    private var summaryBarPositionDefault: CGFloat = 0
    private var summaryBar2ndPositionDefault: CGFloat = 0
    
    public func initSummaryBar() {
        summaryBarPositionDefault = summaryBarPosition.constant
        summaryBar2ndPositionDefault = summaryBar2ndPosition.constant
    }
    
    public func arrangeSummaryBar() {
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
    
    public func summaryPopupViewControllerPushedPinButton(controller: SummaryPopupViewController) {
        if configController.mapSummaryDisplay == .Pinning {
            configController.mapSummaryDisplay = .Balloon
        }else{
            configController.mapSummaryDisplay = .Pinning
        }
    }

}
