//
//  AppDelegate.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DVRemoteClientDelegate, URLSessionDelegate{

    var window: UIWindow?

    deinit {
        DVRemoteClient.shared().remove(self)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let client = DVRemoteClient.shared()
        client?.add(self)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - アプリ間連携
    //-----------------------------------------------------------------------------------------
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        DVRemoteClient.shared().regeisterSharedImage(url)
        return true
    }
    
    fileprivate var completionHandler: (() -> Void)? = nil
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        NSLog("event for shared session")
        self.completionHandler = completionHandler
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        self.completionHandler!()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(_ client: DVRemoteClient!, change state: DVRClientState) {
        if state == .disconnected && client.reconectCount < 10 && client.service != nil {
            let key = ConfigurationController.sharedController.authenticationgKeys[client.service.name]
            if key != nil {
                let time = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {() -> Void in client.reconnect()})
            }
        }else if state == .connected {
            let connectionName = client.service == nil ? "" : client.serviceName
            ConfigurationController.sharedController.establishedConnection = connectionName
        }
    }
    
    func dvrClient(_ client: DVRemoteClient!, didRecieveMeta meta: [AnyHashable: Any]!) {
        restrictLock()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 画面ロック禁止期間の制御
    //-----------------------------------------------------------------------------------------
    fileprivate var timeToStartLock : DispatchTime = DispatchTime(uptimeNanoseconds: 0)
    fileprivate var isInvokedLockTimer = false
    
    func restrictLock() {
        timeToStartLock = DispatchTime.now() + Double(Int64(60 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        if (!isInvokedLockTimer){
            isInvokedLockTimer = true
            UIApplication.shared.isIdleTimerDisabled = true
            waitForTimeToStartLock()
        }
    }
    
    func waitForTimeToStartLock() {
        DispatchQueue.main.asyncAfter(deadline: timeToStartLock, execute: {[unowned self]() -> Void in
            let now = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
            if (now > self.timeToStartLock){
                UIApplication.shared.isIdleTimerDisabled = false
                self.isInvokedLockTimer = false
            }else{
                self.waitForTimeToStartLock()
            }
        })
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 端末情報
    //-----------------------------------------------------------------------------------------
    static func deviceID() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") {
            guard let value = $1.value as? Int8, value != 0 else {return $0}
            return $0 + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    static func deviceName() -> String {
        let identifier = AppDelegate.deviceID()
        if identifier.hasPrefix("iPhone") {
            return NSLocalizedString("DSNAME_LOCAL_IPHONE", comment:"")
        }else if identifier.hasPrefix("iPad") {
            return NSLocalizedString("DSNAME_LOCAL_IPAD", comment:"")
        }else if identifier.hasPrefix("iPod") {
            return NSLocalizedString("DSNAME_LOCAL_IPOD_TOUCH", comment:"")
        }else{
            return NSLocalizedString("DSNAME_LOCAL_SIMULATOR", comment:"")
        }
    }
    
    static func deviceIcon() -> UIImage? {
        let identifier = AppDelegate.deviceID()
        if identifier.hasPrefix("iPhone") {
            return UIImage(named: "icon_iPhone")
        }else if identifier.hasPrefix("iPad") {
            return UIImage(named: "icon_iPad")
        }else if identifier.hasPrefix("iPod") {
            return UIImage(named: "icon_iPod")
        }else{
            return UIImage(named: "icon_iPhone")
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - コネクション名
    //-----------------------------------------------------------------------------------------
    static func connectionName() -> String? {
        let name = DVRemoteClient.shared().serviceName
        if name != nil && DVRemoteClient.shared().isConnectedToLocal {
            return deviceName()
        }else{
            return name
        }
    }
}

