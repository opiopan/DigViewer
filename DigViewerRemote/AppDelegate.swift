//
//  AppDelegate.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DVRemoteClientDelegate{

    var window: UIWindow?

    deinit {
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let client = DVRemoteClient.sharedClient()
        client.addClientDelegate(self)
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        if state == .Disconnected && client.reconectCount < 10 {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue(), {() -> Void in client.reconnect()})
        }else if state == .Connected {
            let connectionName = client.service == nil ? "" : client.serviceName
            ConfigurationController.sharedController.establishedConnection = connectionName
        }
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        restrictLock()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 画面ロック禁止期間の制御
    //-----------------------------------------------------------------------------------------
    private var timeToStartLock : dispatch_time_t = 0
    private var isInvokedLockTimer = false
    
    func restrictLock() {
        timeToStartLock = dispatch_time(DISPATCH_TIME_NOW, Int64(60 * Double(NSEC_PER_SEC)))
        if (!isInvokedLockTimer){
            isInvokedLockTimer = true
            UIApplication.sharedApplication().idleTimerDisabled = true
            waitForTimeToStartLock()
        }
    }
    
    func waitForTimeToStartLock() {
        dispatch_after(timeToStartLock, dispatch_get_main_queue(), {[unowned self]() -> Void in
            let now = dispatch_time(DISPATCH_TIME_NOW, 0)
            if (now > self.timeToStartLock){
                UIApplication.sharedApplication().idleTimerDisabled = false
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
            (identifier, element) in
            guard let value = element.value as? Int8 where value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
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
        let name = DVRemoteClient.sharedClient().serviceName
        if name != nil && DVRemoteClient.sharedClient().isConnectedToLocal {
            return deviceName()
        }else{
            return name
        }
    }
}

