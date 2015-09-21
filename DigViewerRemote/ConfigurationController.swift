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
private struct UserDefaults {
    static let EstablishedConnection = "EstablishedConnection";
    static let MapType = "MapType";
    static let MapShowLabel = "MapShowLabel";
    static let Map3DView = "Map3DView"
    static let EnableVolumeButton = "EnableVolumeButton"
}

enum MapType : Int {
    case Map = 0
    case Satellite
}

//-----------------------------------------------------------------------------------------
// MARK: - Observer用プロトコル定義
//-----------------------------------------------------------------------------------------
protocol ConfigurationControllerDelegate {
    func notifyUpdateConfiguration(configuration : ConfigurationController);
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
    override init(){
        defaults = [
            UserDefaults.MapType                : MapType.Map.rawValue,
            UserDefaults.MapShowLabel           : true,
            UserDefaults.Map3DView              : false,
            UserDefaults.EnableVolumeButton     : false
        ]
        let controller = NSUserDefaults.standardUserDefaults()
        controller.registerDefaults(defaults)
        establishedConnection = controller.valueForKey(UserDefaults.EstablishedConnection) as! String?
        mapType = MapType(rawValue : controller.valueForKey(UserDefaults.MapType) as! Int)!
        mapShowLabel = controller.valueForKey(UserDefaults.MapShowLabel) as! Bool
        map3DView = controller.valueForKey(UserDefaults.Map3DView) as! Bool
        enableVolumeButton = controller.valueForKey(UserDefaults.EnableVolumeButton) as! Bool
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
            if observers[i] as? AnyObject === observer as? AnyObject {
                observers.removeAtIndex(i)
                break
            }
        }
    }

    var updateCount = 0
    func updateConfiguration(){
        updateCount++
        for observer in observers {
            observer.notifyUpdateConfiguration(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - プロパティの実装
    //-----------------------------------------------------------------------------------------
    var establishedConnection : String? {
        didSet{
            let controller = NSUserDefaults.standardUserDefaults()
            controller.setValue(establishedConnection, forKey: UserDefaults.EstablishedConnection)
            updateConfiguration()
        }
    }
    var mapType : MapType {
        didSet{
            let controller = NSUserDefaults.standardUserDefaults()
            controller.setValue(mapType.rawValue, forKey: UserDefaults.MapType)
            updateConfiguration()
        }
    }
    var mapShowLabel : Bool {
        didSet{
            let controller = NSUserDefaults.standardUserDefaults()
            controller.setValue(mapShowLabel, forKey: UserDefaults.MapShowLabel)
            updateConfiguration()
        }
    }
    var map3DView : Bool {
        didSet {
            let controller = NSUserDefaults.standardUserDefaults()
            controller.setValue(map3DView, forKey: UserDefaults.Map3DView)
            updateConfiguration()
        }
    }
    var enableVolumeButton : Bool {
        didSet {
            let controller = NSUserDefaults.standardUserDefaults()
            controller.setValue(enableVolumeButton, forKey: UserDefaults.EnableVolumeButton)
            updateConfiguration()
        }
    }
}
