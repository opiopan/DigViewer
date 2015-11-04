//
//  ConfigurationController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/21.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit


//-----------------------------------------------------------------------------------------
// MARK: ユーザデフォルトキー名 / 列挙型定義
//-----------------------------------------------------------------------------------------
struct UserDefaults {
    static let EstablishedConnection = "EstablishedConnection";
    static let MapType = "MapType";
    static let MapShowLabel = "MapShowLabel";
    static let Map3DView = "Map3DView"
    static let MapHeadingDisplay = "MapHeadingDisplay"
    static let EnableVolumeButton = "EnableVolumeButton"
    
    static let MapRelationSpan = "MapRelationSpan";
    static let MapRelationSpanMethod = "MapRelationSpanMethod"
    static let MapTurnToHeading = "MapTurnToHeading"
    static let MapHeadingShift = "MapHeadingShift"
    static let MapSpan = "MapSpan"
    static let MapTilt = "MapTilt"
}

enum MapType : Int {
    case Map = 0
    case Satellite
}

enum MapHeadingDisplay : Int {
    case None = 0
    case Arrow
    case FOV
    case ArrowAndFOV
}

enum MapRelationSpanMethod : Int {
    case LongSide = 0
    case ShortSide
}

//-----------------------------------------------------------------------------------------
// MARK: - Observer用プロトコル定義
//-----------------------------------------------------------------------------------------
@objc protocol ConfigurationControllerDelegate {
    func notifyUpdateConfiguration(configuration : ConfigurationController);
    optional func notifyUpdateMapDetailConfiguration(configuration : ConfigurationController)
}


//-----------------------------------------------------------------------------------------
// MARK: - ConfigurationController クラス定義
//-----------------------------------------------------------------------------------------
class ConfigurationController: NSObject {
    static let sharedController = ConfigurationController()
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 初期化
    //-----------------------------------------------------------------------------------------
    private var defaults : [String:AnyObject]
    private let controller = NSUserDefaults.standardUserDefaults()

    override init(){
        defaults = [
            UserDefaults.MapType                : MapType.Map.rawValue,
            UserDefaults.MapShowLabel           : true,
            UserDefaults.Map3DView              : false,
            UserDefaults.MapHeadingDisplay      : MapHeadingDisplay.ArrowAndFOV.rawValue,
            UserDefaults.EnableVolumeButton     : false,
            UserDefaults.MapRelationSpan        : true,
            UserDefaults.MapRelationSpanMethod  : MapRelationSpanMethod.LongSide.rawValue,
            UserDefaults.MapTurnToHeading       : true,
            UserDefaults.MapHeadingShift        : 0.3,
            UserDefaults.MapSpan                : 450.0,
            UserDefaults.MapTilt                : 50.0,
        ]
        controller.registerDefaults(defaults)
        establishedConnection = controller.valueForKey(UserDefaults.EstablishedConnection) as! String?
        mapType = MapType(rawValue : controller.valueForKey(UserDefaults.MapType) as! Int)!
        mapShowLabel = controller.valueForKey(UserDefaults.MapShowLabel) as! Bool
        map3DView = controller.valueForKey(UserDefaults.Map3DView) as! Bool
        mapHeadingDisplay = MapHeadingDisplay(rawValue: controller.valueForKey(UserDefaults.MapHeadingDisplay) as! Int)!
        enableVolumeButton = controller.valueForKey(UserDefaults.EnableVolumeButton) as! Bool
        mapRelationSpan = controller.valueForKey(UserDefaults.MapRelationSpan) as! Bool
        mapRelationSpanMethod = MapRelationSpanMethod(rawValue: controller.valueForKey(UserDefaults.MapRelationSpanMethod) as! Int)!
        mapTurnToHeading = controller.valueForKey(UserDefaults.MapTurnToHeading) as! Bool
        mapHeadingShift = controller.valueForKey(UserDefaults.MapHeadingShift) as! CGFloat
        mapSpan = controller.valueForKey(UserDefaults.MapSpan) as! CGFloat
        mapTilt = controller.valueForKey(UserDefaults.MapTilt) as! CGFloat
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Observer管理
    //-----------------------------------------------------------------------------------------
    private var observers : [ConfigurationControllerDelegate] = []
    func registerObserver(observer : ConfigurationControllerDelegate){
        observers.append(observer)
    }
    
    func unregisterObserver(observer : ConfigurationControllerDelegate){
        for var i = 0; i < observers.count; i++ {
            if observers[i] as AnyObject === observer as AnyObject {
                observers.removeAtIndex(i)
                break
            }
        }
    }

    var updateCount = 0
    private func updateConfiguration(){
        updateCount++
        for observer in observers {
            observer.notifyUpdateConfiguration(self)
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
    
    //-----------------------------------------------------------------------------------------
    // MARK: - デフォルト設定
    //-----------------------------------------------------------------------------------------
    func defaultValue(name : String) -> AnyObject? {
        return defaults[name]
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - トランザクション
    //-----------------------------------------------------------------------------------------
    private var inMapDetailConfigurationTransaction = 0;
    func beginMapDetailConfigurationTransaction() {
        inMapDetailConfigurationTransaction++
    }
    
    func commitMapDetailConfigurationTransaction() {
        inMapDetailConfigurationTransaction--
        updateMapDetailConfiguration()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - プロパティの実装
    //-----------------------------------------------------------------------------------------
    var establishedConnection : String? {
        didSet{
            controller.setValue(establishedConnection, forKey: UserDefaults.EstablishedConnection)
            updateConfiguration()
        }
    }
    var mapType : MapType {
        didSet{
            controller.setValue(mapType.rawValue, forKey: UserDefaults.MapType)
            updateConfiguration()
        }
    }
    var mapShowLabel : Bool {
        didSet{
            controller.setValue(mapShowLabel, forKey: UserDefaults.MapShowLabel)
            updateConfiguration()
        }
    }
    var map3DView : Bool {
        didSet {
            controller.setValue(map3DView, forKey: UserDefaults.Map3DView)
            updateConfiguration()
        }
    }
    var mapHeadingDisplay : MapHeadingDisplay {
        didSet {
            controller.setValue(mapHeadingDisplay.rawValue, forKey: UserDefaults.MapHeadingDisplay)
            updateConfiguration()
        }
    }
    
    var enableVolumeButton : Bool {
        didSet {
            controller.setValue(enableVolumeButton, forKey: UserDefaults.EnableVolumeButton)
            updateConfiguration()
        }
    }
    
    var mapRelationSpan : Bool {
        didSet {
            controller.setValue(mapRelationSpan, forKey: UserDefaults.MapRelationSpan)
            updateMapDetailConfiguration()
        }
    }
    
    var mapRelationSpanMethod : MapRelationSpanMethod {
        didSet {
            controller.setValue(mapRelationSpanMethod.rawValue, forKey: UserDefaults.MapRelationSpanMethod)
            updateMapDetailConfiguration()
        }
    }
    
    var mapTurnToHeading : Bool {
        didSet {
            controller.setValue(mapTurnToHeading, forKey: UserDefaults.MapTurnToHeading)
            updateMapDetailConfiguration()
        }
    }
    
    var mapHeadingShift : CGFloat {
        didSet {
            controller.setValue(mapHeadingShift, forKey: UserDefaults.MapHeadingShift)
            updateMapDetailConfiguration()
        }
    }
    
    var mapSpan : CGFloat {
        didSet {
            controller.setValue(mapSpan, forKey: UserDefaults.MapSpan)
            updateMapDetailConfiguration()
        }
    }
    
    var mapSpanString : String {
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
    
    var mapTilt : CGFloat {
        didSet {
            controller.setValue(mapTilt, forKey: UserDefaults.MapTilt)
            updateMapDetailConfiguration()
        }
    }
    
    var mapTiltString : String {
        get {
            return NSString(format: "%.0f°", mapTilt) as String
        }
    }
    
    var informationViewType : Int = 0
}
