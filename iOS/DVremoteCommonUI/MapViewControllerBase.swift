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

open class MapViewControllerBase: UIViewController, MKMapViewDelegate,
                                    ConfigurationControllerDelegate, SummaryPopupViewControllerDelegate,
                                    UIDocumentInteractionControllerDelegate {
    
    @IBOutlet open var mapView : MKMapView? = nil

    fileprivate let configController = ConfigurationController.sharedController
    fileprivate var show3DView = true
    fileprivate var headingDisplayMode = ConfigurationController.sharedController.mapHeadingDisplay
    
    fileprivate var annotationView : AnnotationView?
    open var popupViewController : SummaryPopupViewController?
    
    fileprivate var coverView : UIVisualEffectView?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        summaryBar2nd.layer.zPosition = 1
        
        configController.registerObserver(self)
        show3DView = configController.map3DView
        
        popupViewController = storyboard!.instantiateViewController(withIdentifier: "ImageSummaryPopup") as? SummaryPopupViewController
        if let view = popupViewController!.view {
            var frame = view.frame
            frame.size.width *= 2
        }
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(MapViewControllerBase.tapOnThumbnail(_:)))
        popupViewController!.thumbnailView!.addGestureRecognizer(recognizer)
        popupViewController?.delegate = self
        
        mapView!.layer.zPosition = -1;
        mapView!.delegate = self
        
        coverView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        setBlurCover(true, isShowPopup: false)
        
        reflectUserDefaults()
        
        initSummaryBar()
    }
    
    deinit{
        configController.unregisterObserver(self)
    }

    override open var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - User Defaultsの反映
    //-----------------------------------------------------------------------------------------
    open var pinColor = ConfigurationController.sharedController.mapPinColor
    open var arrowColor = ConfigurationController.sharedController.mapArrowColor
    open var fovColor = ConfigurationController.sharedController.mapFovColor
    open var summaryMode = ConfigurationController.sharedController.mapSummaryDisplay
    open var summaryPinningStyle = ConfigurationController.sharedController.mapSummaryPinningStyle
    
    func reflectUserDefaults() {
        if configController.mapType == .map {
            mapView!.mapType = .standard
        }else{
            mapView!.mapType = configController.mapShowLabel ? .hybridFlyover : .satelliteFlyover
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
    
    open func notifyUpdateConfiguration(_ configuration: ConfigurationController) {
        reflectUserDefaults()
    }
    
    open func notifyUpdateMapDetailConfiguration(_ configuration: ConfigurationController) {
        moveToDefaultPosition(self)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - メタデータ＆サムネール設定
    //-----------------------------------------------------------------------------------------
    fileprivate var isFirst = true
    
    open var isLocalSession : Bool = false
    
    open var meta: [AnyHashable: Any]! {
        didSet{
            self.thumbnail = nil
            popupViewController!.thumbnailView!.image = nil
            
            removeAnnotation()
            removeOverlay()
            geometry = nil
            
            if isFirst {
                isFirst = false
                arrangeSummaryBar()
            }
            
            // ポップアップウィンドウセットアップ
            let popupSummary = SummarizedMeta(meta: meta)
            popupViewController!.dateLabel.text = popupSummary.date
            popupViewController!.cameraLabel.text = popupSummary.camera
            popupViewController!.lensLabel.text = popupSummary.lens
            popupViewController!.conditionLabel.text = popupSummary.condition
            popupViewController!.thumbnailView.image = self.thumbnail
            
            // 位置情報付の反映
            if meta[DVRCNMETA_LATITUDE] != nil {
                geometry = MapGeometry(meta: meta, viewSize: mapView!.bounds.size, isLocalSession: isLocalSession)
                
                // アノテーションセットアップ
                addAnnotation()
                
                // 逆ジオコーディング(経緯度→住所に変換)
                let GPSSummary = meta[DVRCNMETA_GPS_SUMMARY] as! NSArray?
                let latKV = GPSSummary![0] as! ImageMetadataKV
                let longKV = GPSSummary![1] as! ImageMetadataKV
                popupViewController!.addressLabel.text = NSString(format: "%@\n%@", latKV.value, longKV.value) as String
                let location = CLLocation(latitude: geometry!.latitude, longitude: geometry!.longitude)
                ReverseGeocoder.sharedCoder.performCoding(location){
                    [unowned self](coder : ReverseGeocoder) in
                    if self.geometry != nil {
                        if self.geometry!.latitude == location.coordinate.latitude &&
                           self.geometry!.longitude == location.coordinate.longitude {
                            self.popupViewController!.addressLabel.text = coder.address
                        }
                    }
                }
                
                // ブラーカバーを外す
                setBlurCover(false, isShowPopup: false)
                
                // 撮影地点に移動
                willStartToMove()
                moveToDefaultPosition(self)
            }else{
                geometry = nil
                popupViewController!.addressLabel.text = NSLocalizedString("ADDRESS_NA", comment: "")
                (popupViewController!.view as! PopupView).showAnchor = false
                setBlurCover(true, isShowPopup: true)
            }
        }
    }
    
    open var thumbnail: UIImage! = nil {
        didSet{
            if popupViewController!.thumbnailView!.image == nil {
                popupViewController!.thumbnailView!.image = thumbnail
                if annotation != nil  && configController.mapSummaryDisplay == .balloon {
                    mapView!.selectAnnotation(annotation!, animated:true)
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図データロード状況ごとの処理 (MKMapViewDelegateプロトコル)
    //-----------------------------------------------------------------------------------------
    fileprivate var isUpdatedLocation = false
    fileprivate var isLoadingData = false
    
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
            let time = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {[unowned self]() -> Void in
                if (!self.isLoadingData){
                    self.isUpdatedLocation = false
                    self.moveToDefaultPosition(self)
                }
                })
        }
    }
    
    open func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        if (isUpdatedLocation){
            isLoadingData = true
        }
    }
    
    open func mapViewDidFinishLoadingMap(_ view: MKMapView){
        if (isUpdatedLocation){
            isUpdatedLocation = false
            moveToDefaultPosition(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 地図視点移動
    //-----------------------------------------------------------------------------------------
    open var geometry : MapGeometry? = nil
    
    @IBAction open func moveToDefaultPosition(_ sender : AnyObject?) {
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
    fileprivate var annotation : MKPointAnnotation? = nil

    fileprivate func addAnnotation() {
        if geometry != nil {
            (popupViewController!.view as! PopupView).showAnchor = true
            annotation = MKPointAnnotation()
            annotation!.coordinate = geometry!.photoCoordinate
            mapView!.addAnnotation(annotation!)
            if popupViewController!.thumbnailView.image != nil {
                let time = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {[unowned self]() -> Void in
                    if let annotation = self.annotation {
                        if self.configController.mapSummaryDisplay == .balloon {
                            self.mapView!.selectAnnotation(annotation, animated:true)
                        }
                    }
                })
            }
        }
    }
    
    fileprivate func removeAnnotation() {
        if (annotation != nil){
            popupViewController!.updateCount += 1
            mapView!.removeAnnotation(annotation!)
            annotation = nil
        }
    }
    
    open func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation === mapView.userLocation { // 現在地を示すアノテーションの場合はデフォルトのまま
            return nil
        } else {
            let identifier = "annotation"
            let summaryBarEnable = configController.mapSummaryDisplay == .pinning
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? AnnotationView{
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
    
    open var imageSelector : ((UIImageView) -> Void)? = nil

    open func viewFullImage(_ sender: AnyObject) {
        if let selector = imageSelector {
            selector(popupViewController!.thumbnailView)
        }
    }

    open func tapOnThumbnail(_ recognizer: UIGestureRecognizer){
        viewFullImage(self)
    }
    
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 撮影方向オーバーレイ制御
    //-----------------------------------------------------------------------------------------
    fileprivate func addOverlay() {
        removeOverlay()
        if geometry != nil && geometry!.heading != nil {
            let size = MapGeometry.mapToSize(mapView!)
            let hScale = Double(min(size.width, size.height)) / 2
            let vScale =  hScale / cos(Double(mapView!.camera.pitch) / 180 * Double.pi)
            let overlay = HeadingOverlay(
                center: geometry!.photoCoordinate, heading: geometry!.heading!, fov: geometry!.fovAngle,
                vScale: vScale, hScale: hScale)
            overlay.altitude = mapView!.camera.altitude
            mapView!.add(overlay, level: .aboveLabels)
        }
    }
    
    fileprivate func removeOverlay() {
        for overlay in mapView!.overlays {
            mapView!.remove(overlay)
        }
    }
    
    open func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        var altitude : Double = 0
        if mapView.overlays.count > 0 {
            altitude = (mapView.overlays[0] as? HeadingOverlay)!.altitude
        }
        if altitude < mapView.camera.altitude * 0.9 || altitude > mapView.camera.altitude * 1.1 {
            addOverlay()
        }
    }
    
    open func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return HeadingOverlayRenderer(overlay: overlay)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ブラーカバーの制御
    //-----------------------------------------------------------------------------------------
    fileprivate func setBlurCover(_ isShow : Bool, isShowPopup : Bool) {
        if isShow && coverView!.superview == nil {
            //coverView!.frame = self.view.bounds
            let childView = coverView!
            childView.translatesAutoresizingMaskIntoConstraints = false
            mapView!.addSubview(childView)
            childView.layer.zPosition = 1
            let viewDictionary = ["childView": childView]
            let constraints = NSMutableArray()
            let constraintFormat1 =
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-[childView]-|",
                    options : NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: viewDictionary)
            constraints.addObjects(from: constraintFormat1)
            let constraintFormat2 =
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-[childView]-|",
                    options : NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: viewDictionary)
            constraints.addObjects(from: constraintFormat2)
            mapView!.addConstraints((constraints as NSArray as? [NSLayoutConstraint])!)
        }else if !isShow && coverView!.superview != nil {
            if popupViewController!.view.superview != nil && popupViewController!.view.superview == coverView {
                popupViewController!.removeFromSuperView()
            }
            coverView!.removeFromSuperview()
        }

        if isShow && isShowPopup && configController.mapSummaryDisplay == .balloon {
            if popupViewController!.view.superview != nil && popupViewController!.view.superview != coverView {
                popupViewController!.removeFromSuperView()
            }
            if popupViewController!.view.superview == nil {
                popupViewController!.addToSuperView(coverView!, parentType: .noLocationCover)
                popupViewController!.view.alpha = 1.0
                popupViewController!.updateCount += 1
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - サマリバーコントロール
    //-----------------------------------------------------------------------------------------
    @IBOutlet open weak var summaryBar: UIView!
    @IBOutlet open weak var summaryBarPosition: NSLayoutConstraint!

    @IBOutlet open weak var summaryBarPlaceholder: UIView!
    @IBOutlet open weak var summaryBarPlaceholderHeight: NSLayoutConstraint!
    
    @IBOutlet open weak var summaryBar2nd: UIView!
    @IBOutlet open weak var summaryBar2ndPosition: NSLayoutConstraint!
    
    @IBOutlet open weak var summaryBarLeftPlaceholder: UIView!
    @IBOutlet open weak var summaryBarLeftPlaceholderHeight: NSLayoutConstraint!
    @IBOutlet open weak var summaryBarLeftPlaceholderWidth: NSLayoutConstraint!
    
    @IBOutlet open weak var summaryBarRightPlaceholder: UIView!
    @IBOutlet open weak var summaryBarRightPlaceholderHeight: NSLayoutConstraint!
    @IBOutlet open weak var summaryBarRightPlaceholderWidth: NSLayoutConstraint!
    
    fileprivate var summaryBarPositionDefault: CGFloat = 0
    fileprivate var summaryBar2ndPositionDefault: CGFloat = 0
    
    open func initSummaryBar() {
        summaryBarPositionDefault = summaryBarPosition.constant
        summaryBar2ndPositionDefault = summaryBar2ndPosition.constant
    }
    
    open func arrangeSummaryBar() {
        if configController.mapSummaryDisplay != .pinning {
            popupViewController?.removeFromSuperView()
            popupViewController?.pinMode = .off
            summaryBarPosition.constant = summaryBarPositionDefault
            summaryBar2ndPosition.constant = summaryBar2ndPositionDefault
            if coverView?.superview != nil {
                popupViewController?.addToSuperView(coverView!, parentType: .noLocationCover)
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
            if configController.mapSummaryPinningStyle == .inToolBar {
                summaryBarPlaceholderHeight.constant = popupViewController!.viewHeight
                summaryBarPosition.constant = summaryBarPositionDefault + popupViewController!.viewBaseHeight
                summaryBar2ndPosition.constant = summaryBar2ndPositionDefault
                popupViewController?.pinMode = .toolbar
                popupViewController?.addToSuperView(summaryBarPlaceholder, parentType: .noLocationCover)
            }else if configController.mapSummaryPinningStyle == .lowerLeft {
                summaryBarLeftPlaceholderHeight.constant = popupViewController!.viewHeight
                summaryBarLeftPlaceholderWidth.constant = popupViewController!.viewWidth
                summaryBarPosition.constant = summaryBarPositionDefault
                summaryBar2ndPosition.constant = summaryBar2ndPositionDefault + popupViewController!.viewBaseHeight
                popupViewController?.pinMode = .left
                popupViewController?.addToSuperView(summaryBarLeftPlaceholder, parentType: .noLocationCover)
            }else{
                summaryBarRightPlaceholderHeight.constant = popupViewController!.viewHeight
                summaryBarRightPlaceholderWidth.constant = popupViewController!.viewWidth
                summaryBarPosition.constant = summaryBarPositionDefault
                summaryBar2ndPosition.constant = summaryBar2ndPositionDefault + popupViewController!.viewBaseHeight
                popupViewController?.pinMode = .right
                popupViewController?.addToSuperView(summaryBarRightPlaceholder, parentType: .noLocationCover)
            }
        }
    }
    
    open func summaryPopupViewControllerPushedPinButton(_ controller: SummaryPopupViewController) {
        if configController.mapSummaryDisplay == .pinning {
            configController.mapSummaryDisplay = .balloon
        }else{
            configController.mapSummaryDisplay = .pinning
        }
    }

}
