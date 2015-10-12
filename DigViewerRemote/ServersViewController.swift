//
//  ServersViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit

class ServerViewController: UITableViewController, DVRemoteBrowserDelegate, DVRemoteClientDelegate {

    let browser : DVRemoteBrowser = DVRemoteBrowser()

    override func viewDidLoad() {
        super.viewDidLoad()
        browser.delegate = self
        browser.searchServers()
    }
    
    deinit{
        browser.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        DVRemoteClient.sharedClient().addClientDelegate(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    @IBAction func closeServersView(sender : UIBarButtonItem?){
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - サーバー探索
    //-----------------------------------------------------------------------------------------
    private var servers : [NSNetService]! = nil
    
    func dvrBrowserDetectChangeServers(browser: DVRemoteBrowser!) {
        servers = browser.servers as! [NSNetService]!
        tableView.reloadData()
    }
    
    func dvrBrowser(browser: DVRemoteBrowser!, didNotSearch errorDict: [NSObject : AnyObject]!) {
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemote クライアント
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
    }
 
    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビュー用データソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers != nil ? servers!.count + 1 : 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServerCell", forIndexPath: indexPath)
        
        let serverCount = servers != nil ? servers!.count : 0;
        let name = indexPath.row < serverCount ? servers[indexPath.row].name : NSLocalizedString("DSNAME_LOCAL", comment: "")
        cell.textLabel!.text = name
        cell.accessoryType = .None
        
        let client = DVRemoteClient.sharedClient()
        if client.state != .Disconnected && client.service == nil && indexPath.row == serverCount {
            cell.accessoryType = .Checkmark
        }else if client.state != .Disconnected && client.service != nil && client.service.name == name {
            cell.accessoryType = .Checkmark
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let serverCount = servers != nil ? servers!.count : 0;
        let client = DVRemoteClient.sharedClient()
        if indexPath.row == serverCount {
            var needConnect = false
            if client.state != .Disconnected && client.service != nil {
                client.disconnect()
                needConnect = true
            }else if client.state == .Disconnected {
                needConnect = true
            }
            if needConnect {
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue(), {() -> Void in
                    client.connectToLocal()
                })
            }
        }else{
            let nextServer = servers[indexPath.row]
            if client.state != .Disconnected && (client.service == nil || client.service!.name != nextServer.name) {
                client.disconnect()
                client.connectToServer(nextServer)
            }else if client.state == .Disconnected {
                client.connectToServer(nextServer)
            }
        }
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
