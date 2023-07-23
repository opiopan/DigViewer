//
//  ConfigurationController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/21.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonLib

//-----------------------------------------------------------------------------------------
// MARK: ユーザデフォルトキー名 / 列挙型定義
//-----------------------------------------------------------------------------------------
public struct UserDefaults {
    static public let GroupsMigration = "GroupsMigration";
    
    static public let EstablishedConnection = "EstablishedConnection";
    static public let MapType = "MapType";
    static public let MapShowLabel = "MapShowLabel";
    static public let Map3DView = "Map3DView"
    static public let MapHeadingDisplay = "MapHeadingDisplay"
    static public let MapSummaryDisplay = "MapSummaryDisplay"
    static public let EnableVolumeButton = "EnableVolumeButton"
    
    static public let MapRelationSpan = "MapRelationSpan";
    static public let MapRelationSpanMethod = "MapRelationSpanMethod"
    static public let MapTurnToHeading = "MapTurnToHeading"
    static public let MapHeadingShift = "MapHeadingShift"
    static public let MapSpan = "MapSpan"
    static public let MapTilt = "MapTilt"
    static public let MapPinColor = "MapPinColor"
    static public let MapArrowColor = "MapArrowColor"
    static public let MapFOVColor = "MapFOVColor"
    static public let MapSummaryPinningStyle = "MapSummaryPinningStyle"
    static public let MapNeedWarmUp = "MapNeedWarmUp"
    
    static public let DataSourcePinnedList = "DataSourcePinnedList2"
    
    static public let AuthenticationgKeys = "AuthenticatingKeys"
    
    static public let LensLibrarySource = "LensLibrarySource"
    static public let LensLibraryDate = "LnesLibraryDate"
}

public enum MapType : Int {
    case map = 0
    case satellite
}

public enum MapHeadingDisplay : Int {
    case none = 0
    case arrow
    case fov
    case arrowAndFOV
}

public enum MapSummaryDisplay : Int {
    case none = 0
    case balloon
    case pinning
}

public enum MapRelationSpanMethod : Int {
    case longSide = 0
    case shortSide
}

public enum MapSummaryPinningStyle : Int {
    case inToolBar = 0
    case lowerLeft
    case lowerRight
}

//-----------------------------------------------------------------------------------------
// MARK: - Observer用プロトコル定義
//-----------------------------------------------------------------------------------------
@objc public protocol ConfigurationControllerDelegate {
    @objc optional func notifyUpdateConfiguration(_ configuration : ConfigurationController);
    @objc optional func notifyUpdateMapDetailConfiguration(_ configuration : ConfigurationController)
    @objc optional func notifyUpdateDataSourceConfiguration(_ configuration : ConfigurationController)
}


//-----------------------------------------------------------------------------------------
// MARK: - Server情報
//-----------------------------------------------------------------------------------------
open class ServerInfo : NSObject, NSCoding {
    open var service: NetService!
    open var icon: UIImage!
    open var image: UIImage!
    open var attributes: [String : String]!
    open var isPinned: Bool = false
    open var isActive: Bool = false
    
    public override init() {
        super.init()
    }
    
    public init(src : ServerInfo) {
        super.init()
        service = NetService(domain: src.service.domain, type: src.service.type, name: src.service.name)
        icon = src.icon
        image = src.image
        attributes = src.attributes
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        let domain = aDecoder.decodeObject(forKey: "domain") as! String
        let type = aDecoder.decodeObject(forKey: "type") as! String
        let name = aDecoder.decodeObject(forKey: "name") as! String
        service = NetService(domain: domain, type: type, name: name)
        icon = aDecoder.decodeObject(forKey: "icon") as? UIImage
        image = aDecoder.decodeObject(forKey: "image") as? UIImage
        attributes = NSDictionary(coder: aDecoder) as? [String:String]
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(service.domain as NSString, forKey: "domain")
        aCoder.encode(service.type as NSString, forKey: "type")
        aCoder.encode(service.name as NSString, forKey: "name")
        aCoder.encode(icon, forKey: "icon")
        aCoder.encode(image, forKey: "image")
        (attributes as NSDictionary).encode(with: aCoder)
    }
}

//-----------------------------------------------------------------------------------------
// MARK: - ConfigurationController クラス定義
//-----------------------------------------------------------------------------------------
open class ConfigurationController: NSObject {
    @objc static public let sharedController = ConfigurationController()
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 初期化
    //-----------------------------------------------------------------------------------------
    fileprivate var defaults : [String:Any]
    fileprivate let controller = Foundation.UserDefaults(suiteName: DVremoteAppGroupID)!

    override init(){
        let redColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.red)
        defaults = [
            UserDefaults.EstablishedConnection  : "",
            UserDefaults.MapType                : MapType.map.rawValue,
            UserDefaults.MapShowLabel           : true,
            UserDefaults.Map3DView              : false,
            UserDefaults.MapHeadingDisplay      : MapHeadingDisplay.arrowAndFOV.rawValue,
            UserDefaults.MapSummaryDisplay      : MapSummaryDisplay.balloon.rawValue,
            UserDefaults.EnableVolumeButton     : false,
            UserDefaults.MapRelationSpan        : true,
            UserDefaults.MapRelationSpanMethod  : MapRelationSpanMethod.longSide.rawValue,
            UserDefaults.MapTurnToHeading       : true,
            UserDefaults.MapHeadingShift        : 0.3,
            UserDefaults.MapSpan                : 450.0,
            UserDefaults.MapTilt                : 50.0,
            UserDefaults.MapPinColor            : redColor,
            UserDefaults.MapArrowColor          : redColor,
            UserDefaults.MapFOVColor            : redColor,
            UserDefaults.MapSummaryPinningStyle : MapSummaryPinningStyle.inToolBar.rawValue,
            UserDefaults.MapNeedWarmUp          : true,
            UserDefaults.DataSourcePinnedList   : NSKeyedArchiver.archivedData(withRootObject: [] as [ServerInfo]),
            UserDefaults.AuthenticationgKeys    : NSDictionary(),
            UserDefaults.LensLibraryDate        : 0,
        ]
        controller.register(defaults: defaults)
        establishedConnection = controller.value(forKey: UserDefaults.EstablishedConnection) as! String?
        mapType = MapType(rawValue : controller.value(forKey: UserDefaults.MapType) as! Int)!
        mapShowLabel = controller.value(forKey: UserDefaults.MapShowLabel) as! Bool
        map3DView = controller.value(forKey: UserDefaults.Map3DView) as! Bool
        mapHeadingDisplay = MapHeadingDisplay(rawValue: controller.value(forKey: UserDefaults.MapHeadingDisplay) as! Int)!
        mapSummaryDisplay = MapSummaryDisplay(rawValue: controller.value(forKey: UserDefaults.MapSummaryDisplay) as! Int)!
        enableVolumeButton = controller.value(forKey: UserDefaults.EnableVolumeButton) as! Bool
        mapRelationSpan = controller.value(forKey: UserDefaults.MapRelationSpan) as! Bool
        mapRelationSpanMethod = MapRelationSpanMethod(rawValue: controller.value(forKey: UserDefaults.MapRelationSpanMethod) as! Int)!
        mapTurnToHeading = controller.value(forKey: UserDefaults.MapTurnToHeading) as! Bool
        mapHeadingShift = controller.value(forKey: UserDefaults.MapHeadingShift) as! CGFloat
        mapSpan = controller.value(forKey: UserDefaults.MapSpan) as! CGFloat
        mapTilt = controller.value(forKey: UserDefaults.MapTilt) as! CGFloat
        mapPinColor =
            NSKeyedUnarchiver.unarchiveObject(with: controller.value(forKey: UserDefaults.MapPinColor) as! Data) as! UIColor
        mapArrowColor =
            NSKeyedUnarchiver.unarchiveObject(with: controller.value(forKey: UserDefaults.MapArrowColor) as! Data) as! UIColor
        mapFovColor =
            NSKeyedUnarchiver.unarchiveObject(with: controller.value(forKey: UserDefaults.MapFOVColor) as! Data) as! UIColor
        mapSummaryPinningStyle =
            MapSummaryPinningStyle(rawValue: controller.value(forKey: UserDefaults.MapSummaryPinningStyle) as! Int)!
        mapNeedWarmUp = controller.value(forKey: UserDefaults.MapNeedWarmUp) as! Bool
        dataSourcePinnedList =
            NSKeyedUnarchiver.unarchiveObject(with: controller.value(forKey: UserDefaults.DataSourcePinnedList) as! Data)
            as! [ServerInfo]
        authenticationgKeys = controller.value(forKey: UserDefaults.AuthenticationgKeys) as! [String:String]
        lensLibrarySource = controller.value(forKey: UserDefaults.LensLibrarySource) as! String?
        lensLibraryDate = controller.value(forKey: UserDefaults.LensLibraryDate) as! Double
        
        super.init()
        
        self.migrateToAppGroups()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - App Groupsへのマイグレーション
    //-----------------------------------------------------------------------------------------
    fileprivate func migrateToAppGroups() {
        if controller.value(forKey: UserDefaults.GroupsMigration) == nil {
            let src = Foundation.UserDefaults.standard
            
            establishedConnection = src.value(forKey: UserDefaults.EstablishedConnection) as! String?
            mapType = MapType(rawValue : src.value(forKey: UserDefaults.MapType) as! Int)!
            mapShowLabel = src.value(forKey: UserDefaults.MapShowLabel) as! Bool
            map3DView = src.value(forKey: UserDefaults.Map3DView) as! Bool
            mapHeadingDisplay = MapHeadingDisplay(rawValue: src.value(forKey: UserDefaults.MapHeadingDisplay) as! Int)!
            mapSummaryDisplay = MapSummaryDisplay(rawValue: src.value(forKey: UserDefaults.MapSummaryDisplay) as! Int)!
            enableVolumeButton = src.value(forKey: UserDefaults.EnableVolumeButton) as! Bool
            mapRelationSpan = src.value(forKey: UserDefaults.MapRelationSpan) as! Bool
            mapRelationSpanMethod = MapRelationSpanMethod(rawValue: src.value(forKey: UserDefaults.MapRelationSpanMethod) as! Int)!
            mapTurnToHeading = src.value(forKey: UserDefaults.MapTurnToHeading) as! Bool
            mapHeadingShift = src.value(forKey: UserDefaults.MapHeadingShift) as! CGFloat
            mapSpan = src.value(forKey: UserDefaults.MapSpan) as! CGFloat
            mapTilt = src.value(forKey: UserDefaults.MapTilt) as! CGFloat
            mapPinColor =
                NSKeyedUnarchiver.unarchiveObject(with: src.value(forKey: UserDefaults.MapPinColor) as! Data) as! UIColor
            mapArrowColor =
                NSKeyedUnarchiver.unarchiveObject(with: src.value(forKey: UserDefaults.MapArrowColor) as! Data) as! UIColor
            mapFovColor =
                NSKeyedUnarchiver.unarchiveObject(with: src.value(forKey: UserDefaults.MapFOVColor) as! Data) as! UIColor
            mapSummaryPinningStyle =
                MapSummaryPinningStyle(rawValue: src.value(forKey: UserDefaults.MapSummaryPinningStyle) as! Int)!
            dataSourcePinnedList =
                NSKeyedUnarchiver.unarchiveObject(with: src.value(forKey: UserDefaults.DataSourcePinnedList) as! Data)
                as! [ServerInfo]
            authenticationgKeys = src.value(forKey: UserDefaults.AuthenticationgKeys) as! [String:String]
            
            controller.setValue(true, forKey: UserDefaults.GroupsMigration)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Observer管理
    //-----------------------------------------------------------------------------------------
    fileprivate var observers : [ConfigurationControllerDelegate] = []
    open func registerObserver(_ observer : ConfigurationControllerDelegate){
        observers.append(observer)
    }
    
    open func unregisterObserver(_ observer : ConfigurationControllerDelegate){
        for i in 0 ..< observers.count {
            if observers[i] as AnyObject === observer as AnyObject {
                observers.remove(at: i)
                break
            }
        }
    }

    fileprivate var updateCount = 0
    fileprivate func updateConfiguration(){
        updateCount += 1
        for observer in observers {
            observer.notifyUpdateConfiguration?(self)
        }
    }
    
    fileprivate func updateMapDetailConfiguration() {
        updateCount += 1
        if inMapDetailConfigurationTransaction == 0 {
            for observer in observers {
                observer.notifyUpdateMapDetailConfiguration?(self)
            }
        }
    }
    
    fileprivate func updateDataSourceConfiguration() {
        updateCount += 1
        for observer in observers {
            observer.notifyUpdateDataSourceConfiguration?(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - デフォルト設定
    //-----------------------------------------------------------------------------------------
    open func defaultValue(_ name : String) -> Any? {
        return defaults[name]
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - トランザクション
    //-----------------------------------------------------------------------------------------
    fileprivate var inMapDetailConfigurationTransaction = 0;
    open func beginMapDetailConfigurationTransaction() {
        inMapDetailConfigurationTransaction += 1
    }
    
    open func commitMapDetailConfigurationTransaction() {
        inMapDetailConfigurationTransaction -= 1
        updateMapDetailConfiguration()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - プロパティの実装
    //-----------------------------------------------------------------------------------------
    open var establishedConnection : String? {
        didSet{
            controller.setValue(establishedConnection, forKey: UserDefaults.EstablishedConnection)
            updateConfiguration()
        }
    }
    open var mapType : MapType {
        didSet{
            controller.setValue(mapType.rawValue, forKey: UserDefaults.MapType)
            updateConfiguration()
        }
    }
    open var mapShowLabel : Bool {
        didSet{
            controller.setValue(mapShowLabel, forKey: UserDefaults.MapShowLabel)
            updateConfiguration()
        }
    }
    open var map3DView : Bool {
        didSet {
            controller.setValue(map3DView, forKey: UserDefaults.Map3DView)
            updateConfiguration()
        }
    }
    open var mapHeadingDisplay : MapHeadingDisplay {
        didSet {
            controller.setValue(mapHeadingDisplay.rawValue, forKey: UserDefaults.MapHeadingDisplay)
            updateConfiguration()
        }
    }
    
    open var mapSummaryDisplay : MapSummaryDisplay {
        didSet {
            controller.setValue(mapSummaryDisplay.rawValue, forKey: UserDefaults.MapSummaryDisplay)
            updateConfiguration()
        }
    }
    
    open var enableVolumeButton : Bool {
        didSet {
            controller.setValue(enableVolumeButton, forKey: UserDefaults.EnableVolumeButton)
            updateConfiguration()
        }
    }
    
    open var mapRelationSpan : Bool {
        didSet {
            controller.setValue(mapRelationSpan, forKey: UserDefaults.MapRelationSpan)
            updateMapDetailConfiguration()
        }
    }
    
    open var mapRelationSpanMethod : MapRelationSpanMethod {
        didSet {
            controller.setValue(mapRelationSpanMethod.rawValue, forKey: UserDefaults.MapRelationSpanMethod)
            updateMapDetailConfiguration()
        }
    }
    
    open var mapTurnToHeading : Bool {
        didSet {
            controller.setValue(mapTurnToHeading, forKey: UserDefaults.MapTurnToHeading)
            updateMapDetailConfiguration()
        }
    }
    
    open var mapHeadingShift : CGFloat {
        didSet {
            controller.setValue(mapHeadingShift, forKey: UserDefaults.MapHeadingShift)
            updateMapDetailConfiguration()
        }
    }
    
    open var mapSpan : CGFloat {
        didSet {
            controller.setValue(mapSpan, forKey: UserDefaults.MapSpan)
            updateMapDetailConfiguration()
        }
    }
    
    open var mapSpanString : String {
        get {
            var rc = ""
            
            if mapSpan < 100 {
                rc = NSString(format: "%.1fm", mapSpan) as String
            }else if mapSpan < 900 {
                rc = NSString(format: "%.0fm", mapSpan) as String
            }else if mapSpan < 10000 {
                rc = NSString(format: "%.2fkm", mapSpan / 1000) as String
            }else if mapSpan < 100000 {
                rc = NSString(format: "%.1fkm", mapSpan / 1000) as String
            }else{
                rc = NSString(format: "%.0fkm", mapSpan / 1000) as String
            }
            
            return rc
        }
    }
    
    open var mapTilt : CGFloat {
        didSet {
            controller.setValue(mapTilt, forKey: UserDefaults.MapTilt)
            updateMapDetailConfiguration()
        }
    }
    
    open var mapTiltString : String {
        get {
            return NSString(format: "%.0f°", mapTilt) as String
        }
    }
    
    open var mapPinColor : UIColor {
        didSet {
            let data = NSKeyedArchiver.archivedData(withRootObject: mapPinColor)
            controller.setValue(data, forKey: UserDefaults.MapPinColor)
            updateConfiguration()
        }
    }
    
    open var mapArrowColor : UIColor {
        didSet {
            let data = NSKeyedArchiver.archivedData(withRootObject: mapArrowColor)
            controller.setValue(data, forKey: UserDefaults.MapArrowColor)
            updateConfiguration()
        }
    }
    
    open var mapFovColor : UIColor {
        didSet {
            let data = NSKeyedArchiver.archivedData(withRootObject: mapFovColor)
            controller.setValue(data, forKey: UserDefaults.MapFOVColor)
            updateConfiguration()
        }
    }
    
    open var mapSummaryPinningStyle : MapSummaryPinningStyle {
        didSet {
            controller.setValue(mapSummaryPinningStyle.rawValue, forKey: UserDefaults.MapSummaryPinningStyle)
            updateConfiguration()
        }
    }
    
    open var mapNeedWarmUp : Bool {
        didSet {
            controller.setValue(mapNeedWarmUp, forKey: UserDefaults.MapNeedWarmUp)
            updateConfiguration()
        }
    }
    
    open var dataSourcePinnedList : [ServerInfo] {
        didSet {
            let data = NSKeyedArchiver.archivedData(withRootObject: dataSourcePinnedList)
            controller.setValue(data, forKey: UserDefaults.DataSourcePinnedList)
            updateDataSourceConfiguration()
        }
    }
    
    open var authenticationgKeys : [String:String] {
        didSet {
            controller.setValue(authenticationgKeys, forKey: UserDefaults.AuthenticationgKeys)
        }
    }
    
    @objc open var lensLibrarySource : String? {
        didSet {
            controller.setValue(lensLibrarySource, forKey: UserDefaults.LensLibrarySource)
        }
    }
    
    @objc open var lensLibraryDate : Double {
        didSet {
            controller.setValue(lensLibraryDate, forKey: UserDefaults.LensLibraryDate)
        }
    }
    
    open var informationViewType : Int = 0
}
