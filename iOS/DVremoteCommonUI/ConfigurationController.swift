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
    
    static public let DataSourcePinnedList = "DataSourcePinnedList2"
    
    static public let AuthenticationgKeys = "AuthenticatingKeys"
    
    static public let LensLibrarySource = "LensLibrarySource"
    static public let LensLibraryDate = "LnesLibraryDate"
}

public enum MapType : Int {
    case Map = 0
    case Satellite
}

public enum MapHeadingDisplay : Int {
    case None = 0
    case Arrow
    case FOV
    case ArrowAndFOV
}

public enum MapSummaryDisplay : Int {
    case None = 0
    case Balloon
    case Pinning
}

public enum MapRelationSpanMethod : Int {
    case LongSide = 0
    case ShortSide
}

public enum MapSummaryPinningStyle : Int {
    case InToolBar = 0
    case LowerLeft
    case LowerRight
}

//-----------------------------------------------------------------------------------------
// MARK: - Observer用プロトコル定義
//-----------------------------------------------------------------------------------------
@objc public protocol ConfigurationControllerDelegate {
    optional func notifyUpdateConfiguration(configuration : ConfigurationController);
    optional func notifyUpdateMapDetailConfiguration(configuration : ConfigurationController)
    optional func notifyUpdateDataSourceConfiguration(configuration : ConfigurationController)
}


//-----------------------------------------------------------------------------------------
// MARK: - Server情報
//-----------------------------------------------------------------------------------------
public class ServerInfo : NSObject, NSCoding {
    public var service: NSNetService!
    public var icon: UIImage!
    public var image: UIImage!
    public var attributes: [String : String]!
    public var isPinned: Bool = false
    public var isActive: Bool = false
    
    public override init() {
        super.init()
    }
    
    public init(src : ServerInfo) {
        super.init()
        service = NSNetService(domain: src.service.domain, type: src.service.type, name: src.service.name)
        icon = src.icon
        image = src.image
        attributes = src.attributes
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        let domain = aDecoder.decodeObjectForKey("domain") as! String
        let type = aDecoder.decodeObjectForKey("type") as! String
        let name = aDecoder.decodeObjectForKey("name") as! String
        service = NSNetService(domain: domain, type: type, name: name)
        icon = aDecoder.decodeObjectForKey("icon") as! UIImage
        image = aDecoder.decodeObjectForKey("image") as! UIImage
        attributes = NSDictionary(coder: aDecoder) as! [String:String]
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(service.domain as NSString, forKey: "domain")
        aCoder.encodeObject(service.type as NSString, forKey: "type")
        aCoder.encodeObject(service.name as NSString, forKey: "name")
        aCoder.encodeObject(icon, forKey: "icon")
        aCoder.encodeObject(image, forKey: "image")
        (attributes as NSDictionary).encodeWithCoder(aCoder)
    }
}

//-----------------------------------------------------------------------------------------
// MARK: - ConfigurationController クラス定義
//-----------------------------------------------------------------------------------------
public class ConfigurationController: NSObject {
    static public let sharedController = ConfigurationController()
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 初期化
    //-----------------------------------------------------------------------------------------
    private var defaults : [String:AnyObject]
    private let controller = NSUserDefaults(suiteName: DVremoteAppGroupID)!

    override init(){
        let redColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.redColor())
        defaults = [
            UserDefaults.MapType                : MapType.Map.rawValue,
            UserDefaults.MapShowLabel           : true,
            UserDefaults.Map3DView              : false,
            UserDefaults.MapHeadingDisplay      : MapHeadingDisplay.ArrowAndFOV.rawValue,
            UserDefaults.MapSummaryDisplay      : MapSummaryDisplay.Balloon.rawValue,
            UserDefaults.EnableVolumeButton     : false,
            UserDefaults.MapRelationSpan        : true,
            UserDefaults.MapRelationSpanMethod  : MapRelationSpanMethod.LongSide.rawValue,
            UserDefaults.MapTurnToHeading       : true,
            UserDefaults.MapHeadingShift        : 0.3,
            UserDefaults.MapSpan                : 450.0,
            UserDefaults.MapTilt                : 50.0,
            UserDefaults.MapPinColor            : redColor,
            UserDefaults.MapArrowColor          : redColor,
            UserDefaults.MapFOVColor            : redColor,
            UserDefaults.MapSummaryPinningStyle : MapSummaryPinningStyle.InToolBar.rawValue,
            UserDefaults.DataSourcePinnedList   : NSKeyedArchiver.archivedDataWithRootObject([] as [ServerInfo]),
            UserDefaults.AuthenticationgKeys    : NSDictionary(),
            UserDefaults.LensLibraryDate        : 0,
        ]
        controller.registerDefaults(defaults)
        establishedConnection = controller.valueForKey(UserDefaults.EstablishedConnection) as! String?
        mapType = MapType(rawValue : controller.valueForKey(UserDefaults.MapType) as! Int)!
        mapShowLabel = controller.valueForKey(UserDefaults.MapShowLabel) as! Bool
        map3DView = controller.valueForKey(UserDefaults.Map3DView) as! Bool
        mapHeadingDisplay = MapHeadingDisplay(rawValue: controller.valueForKey(UserDefaults.MapHeadingDisplay) as! Int)!
        mapSummaryDisplay = MapSummaryDisplay(rawValue: controller.valueForKey(UserDefaults.MapSummaryDisplay) as! Int)!
        enableVolumeButton = controller.valueForKey(UserDefaults.EnableVolumeButton) as! Bool
        mapRelationSpan = controller.valueForKey(UserDefaults.MapRelationSpan) as! Bool
        mapRelationSpanMethod = MapRelationSpanMethod(rawValue: controller.valueForKey(UserDefaults.MapRelationSpanMethod) as! Int)!
        mapTurnToHeading = controller.valueForKey(UserDefaults.MapTurnToHeading) as! Bool
        mapHeadingShift = controller.valueForKey(UserDefaults.MapHeadingShift) as! CGFloat
        mapSpan = controller.valueForKey(UserDefaults.MapSpan) as! CGFloat
        mapTilt = controller.valueForKey(UserDefaults.MapTilt) as! CGFloat
        mapPinColor =
            NSKeyedUnarchiver.unarchiveObjectWithData(controller.valueForKey(UserDefaults.MapPinColor) as! NSData) as! UIColor
        mapArrowColor =
            NSKeyedUnarchiver.unarchiveObjectWithData(controller.valueForKey(UserDefaults.MapArrowColor) as! NSData) as! UIColor
        mapFovColor =
            NSKeyedUnarchiver.unarchiveObjectWithData(controller.valueForKey(UserDefaults.MapFOVColor) as! NSData) as! UIColor
        mapSummaryPinningStyle =
            MapSummaryPinningStyle(rawValue: controller.valueForKey(UserDefaults.MapSummaryPinningStyle) as! Int)!
        dataSourcePinnedList =
            NSKeyedUnarchiver.unarchiveObjectWithData(controller.valueForKey(UserDefaults.DataSourcePinnedList) as! NSData)
            as! [ServerInfo]
        authenticationgKeys = controller.valueForKey(UserDefaults.AuthenticationgKeys) as! [String:String]
        lensLibrarySource = controller.valueForKey(UserDefaults.LensLibrarySource) as! String?
        lensLibraryDate = controller.valueForKey(UserDefaults.LensLibraryDate) as! Double
        
        super.init()
        
        self.migrateToAppGroups()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - App Groupsへのマイグレーション
    //-----------------------------------------------------------------------------------------
    private func migrateToAppGroups() {
        if controller.valueForKey(UserDefaults.GroupsMigration) == nil {
            let src = NSUserDefaults.standardUserDefaults()
            
            establishedConnection = src.valueForKey(UserDefaults.EstablishedConnection) as! String?
            mapType = MapType(rawValue : src.valueForKey(UserDefaults.MapType) as! Int)!
            mapShowLabel = src.valueForKey(UserDefaults.MapShowLabel) as! Bool
            map3DView = src.valueForKey(UserDefaults.Map3DView) as! Bool
            mapHeadingDisplay = MapHeadingDisplay(rawValue: src.valueForKey(UserDefaults.MapHeadingDisplay) as! Int)!
            mapSummaryDisplay = MapSummaryDisplay(rawValue: src.valueForKey(UserDefaults.MapSummaryDisplay) as! Int)!
            enableVolumeButton = src.valueForKey(UserDefaults.EnableVolumeButton) as! Bool
            mapRelationSpan = src.valueForKey(UserDefaults.MapRelationSpan) as! Bool
            mapRelationSpanMethod = MapRelationSpanMethod(rawValue: src.valueForKey(UserDefaults.MapRelationSpanMethod) as! Int)!
            mapTurnToHeading = src.valueForKey(UserDefaults.MapTurnToHeading) as! Bool
            mapHeadingShift = src.valueForKey(UserDefaults.MapHeadingShift) as! CGFloat
            mapSpan = src.valueForKey(UserDefaults.MapSpan) as! CGFloat
            mapTilt = src.valueForKey(UserDefaults.MapTilt) as! CGFloat
            mapPinColor =
                NSKeyedUnarchiver.unarchiveObjectWithData(src.valueForKey(UserDefaults.MapPinColor) as! NSData) as! UIColor
            mapArrowColor =
                NSKeyedUnarchiver.unarchiveObjectWithData(src.valueForKey(UserDefaults.MapArrowColor) as! NSData) as! UIColor
            mapFovColor =
                NSKeyedUnarchiver.unarchiveObjectWithData(src.valueForKey(UserDefaults.MapFOVColor) as! NSData) as! UIColor
            mapSummaryPinningStyle =
                MapSummaryPinningStyle(rawValue: src.valueForKey(UserDefaults.MapSummaryPinningStyle) as! Int)!
            dataSourcePinnedList =
                NSKeyedUnarchiver.unarchiveObjectWithData(src.valueForKey(UserDefaults.DataSourcePinnedList) as! NSData)
                as! [ServerInfo]
            authenticationgKeys = src.valueForKey(UserDefaults.AuthenticationgKeys) as! [String:String]
            
            controller.setValue(true, forKey: UserDefaults.GroupsMigration)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Observer管理
    //-----------------------------------------------------------------------------------------
    private var observers : [ConfigurationControllerDelegate] = []
    public func registerObserver(observer : ConfigurationControllerDelegate){
        observers.append(observer)
    }
    
    public func unregisterObserver(observer : ConfigurationControllerDelegate){
        for var i = 0; i < observers.count; i++ {
            if observers[i] as AnyObject === observer as AnyObject {
                observers.removeAtIndex(i)
                break
            }
        }
    }

    private var updateCount = 0
    private func updateConfiguration(){
        updateCount++
        for observer in observers {
            observer.notifyUpdateConfiguration?(self)
        }
    }
    
    private func updateMapDetailConfiguration() {
        updateCount++
        if inMapDetailConfigurationTransaction == 0 {
            for observer in observers {
                observer.notifyUpdateMapDetailConfiguration?(self)
            }
        }
    }
    
    private func updateDataSourceConfiguration() {
        updateCount++
        for observer in observers {
            observer.notifyUpdateDataSourceConfiguration?(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - デフォルト設定
    //-----------------------------------------------------------------------------------------
    public func defaultValue(name : String) -> AnyObject? {
        return defaults[name]
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - トランザクション
    //-----------------------------------------------------------------------------------------
    private var inMapDetailConfigurationTransaction = 0;
    public func beginMapDetailConfigurationTransaction() {
        inMapDetailConfigurationTransaction++
    }
    
    public func commitMapDetailConfigurationTransaction() {
        inMapDetailConfigurationTransaction--
        updateMapDetailConfiguration()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - プロパティの実装
    //-----------------------------------------------------------------------------------------
    public var establishedConnection : String? {
        didSet{
            controller.setValue(establishedConnection, forKey: UserDefaults.EstablishedConnection)
            updateConfiguration()
        }
    }
    public var mapType : MapType {
        didSet{
            controller.setValue(mapType.rawValue, forKey: UserDefaults.MapType)
            updateConfiguration()
        }
    }
    public var mapShowLabel : Bool {
        didSet{
            controller.setValue(mapShowLabel, forKey: UserDefaults.MapShowLabel)
            updateConfiguration()
        }
    }
    public var map3DView : Bool {
        didSet {
            controller.setValue(map3DView, forKey: UserDefaults.Map3DView)
            updateConfiguration()
        }
    }
    public var mapHeadingDisplay : MapHeadingDisplay {
        didSet {
            controller.setValue(mapHeadingDisplay.rawValue, forKey: UserDefaults.MapHeadingDisplay)
            updateConfiguration()
        }
    }
    
    public var mapSummaryDisplay : MapSummaryDisplay {
        didSet {
            controller.setValue(mapSummaryDisplay.rawValue, forKey: UserDefaults.MapSummaryDisplay)
            updateConfiguration()
        }
    }
    
    public var enableVolumeButton : Bool {
        didSet {
            controller.setValue(enableVolumeButton, forKey: UserDefaults.EnableVolumeButton)
            updateConfiguration()
        }
    }
    
    public var mapRelationSpan : Bool {
        didSet {
            controller.setValue(mapRelationSpan, forKey: UserDefaults.MapRelationSpan)
            updateMapDetailConfiguration()
        }
    }
    
    public var mapRelationSpanMethod : MapRelationSpanMethod {
        didSet {
            controller.setValue(mapRelationSpanMethod.rawValue, forKey: UserDefaults.MapRelationSpanMethod)
            updateMapDetailConfiguration()
        }
    }
    
    public var mapTurnToHeading : Bool {
        didSet {
            controller.setValue(mapTurnToHeading, forKey: UserDefaults.MapTurnToHeading)
            updateMapDetailConfiguration()
        }
    }
    
    public var mapHeadingShift : CGFloat {
        didSet {
            controller.setValue(mapHeadingShift, forKey: UserDefaults.MapHeadingShift)
            updateMapDetailConfiguration()
        }
    }
    
    public var mapSpan : CGFloat {
        didSet {
            controller.setValue(mapSpan, forKey: UserDefaults.MapSpan)
            updateMapDetailConfiguration()
        }
    }
    
    public var mapSpanString : String {
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
    
    public var mapTilt : CGFloat {
        didSet {
            controller.setValue(mapTilt, forKey: UserDefaults.MapTilt)
            updateMapDetailConfiguration()
        }
    }
    
    public var mapTiltString : String {
        get {
            return NSString(format: "%.0f°", mapTilt) as String
        }
    }
    
    public var mapPinColor : UIColor {
        didSet {
            let data = NSKeyedArchiver.archivedDataWithRootObject(mapPinColor)
            controller.setValue(data, forKey: UserDefaults.MapPinColor)
            updateConfiguration()
        }
    }
    
    public var mapArrowColor : UIColor {
        didSet {
            let data = NSKeyedArchiver.archivedDataWithRootObject(mapArrowColor)
            controller.setValue(data, forKey: UserDefaults.MapArrowColor)
            updateConfiguration()
        }
    }
    
    public var mapFovColor : UIColor {
        didSet {
            let data = NSKeyedArchiver.archivedDataWithRootObject(mapFovColor)
            controller.setValue(data, forKey: UserDefaults.MapFOVColor)
            updateConfiguration()
        }
    }
    
    public var mapSummaryPinningStyle : MapSummaryPinningStyle {
        didSet {
            controller.setValue(mapSummaryPinningStyle.rawValue, forKey: UserDefaults.MapSummaryPinningStyle)
            updateConfiguration()
        }
    }
    
    public var dataSourcePinnedList : [ServerInfo] {
        didSet {
            let data = NSKeyedArchiver.archivedDataWithRootObject(dataSourcePinnedList)
            controller.setValue(data, forKey: UserDefaults.DataSourcePinnedList)
            updateDataSourceConfiguration()
        }
    }
    
    public var authenticationgKeys : [String:String] {
        didSet {
            controller.setValue(authenticationgKeys, forKey: UserDefaults.AuthenticationgKeys)
        }
    }
    
    public var lensLibrarySource : String? {
        didSet {
            controller.setValue(lensLibrarySource, forKey: UserDefaults.LensLibrarySource)
        }
    }
    
    public var lensLibraryDate : Double {
        didSet {
            controller.setValue(lensLibraryDate, forKey: UserDefaults.LensLibraryDate)
        }
    }
    
    public var informationViewType : Int = 0
}
