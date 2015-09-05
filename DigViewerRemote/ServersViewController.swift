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
        DVRemoteClient.sharedClient().addClientDelegate(self)
        
        browser.delegate = self
        browser.searchServers()
    }
    
    deinit{
        browser.stop()
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        return servers != nil ? servers!.count : 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServerCell", forIndexPath: indexPath) 
        let client = DVRemoteClient.sharedClient()
        let name = servers[indexPath.row].name
        cell.textLabel!.text = name
        if client.state != .Disconnected && client.service!.name == name {
            cell.accessoryType = .Checkmark
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let nextServer = servers[indexPath.row]
        let client = DVRemoteClient.sharedClient()
        if (client.service != nil && client.service!.name != nextServer.name){
            client.disconnect()
            client.connectToServer(nextServer)
        }else if (client.state == .Disconnected){
            client.connectToServer(nextServer)
        }
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
