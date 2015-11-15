//
//  ServersViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit

class ServerInfo {
    var service: NSNetService!
    var icon: UIImage!
    var image: UIImage!
    var attributes: [String : String]!
}

class ServerViewController: UITableViewController, DVRemoteBrowserDelegate, DVRemoteClientDelegate {

    private let browser : DVRemoteBrowser = DVRemoteBrowser()

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
        tmpClient.addClientDelegate(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        tmpClient.removeClientDelegate(self)
    }

    @IBAction func closeServersView(sender : UIBarButtonItem?){
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - サーバー探索
    //-----------------------------------------------------------------------------------------
    private var servers : [ServerInfo] = []
    
    func dvrBrowserDetectAddServer(browser: DVRemoteBrowser!, service: NSNetService!) {
        let serverInfo = ServerInfo()
        serverInfo.service = service
        addServerInfo(serverInfo)
    }
    
    func dvrBrowserDetectRemoveServer(browser: DVRemoteBrowser!, service: NSNetService!) {
        let indexes = servers.enumerate().filter{$0.element.service.name == service.name}.map{$0.index}
        if let index = indexes.first {
            servers.removeAtIndex(index)
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
            tableView.endUpdates()
        }
    }
    
    func dvrBrowser(browser: DVRemoteBrowser!, didNotSearch errorDict: [NSObject : AnyObject]!) {
    }
    
    
    //-----------------------------------------------------------------------------------------
    // MARK: - サーバー情報収集
    //-----------------------------------------------------------------------------------------
    private var queryingServers : [ServerInfo] = []
    private let tmpClient = DVRemoteClient.temporaryClient()
    
    private func addServerInfo(serverInfo: ServerInfo){
        queryingServers.append(serverInfo)
        if queryingServers.count == 1 {
            queryServerInfo()
        }
    }
    
    private func queryServerInfo(){
        headerController.activityIndicator.startAnimating()
        tmpClient.connectToServer(queryingServers[0].service)
    }
    
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        if state == .Connected {
            client.requestServerInfo()
        }else if state == .Disconnected {
            headerController.activityIndicator.stopAnimating()
            queryingServers.removeAtIndex(0)
            if queryingServers.count > 0 {
                queryServerInfo()
            }
        }
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveServerInfo info: [NSObject : AnyObject]!) {
        let serverInfo = queryingServers[0];
        serverInfo.attributes = info[DVRCNMETA_SERVER_INFO] as! [String : String]
        serverInfo.icon = UIImage(data: info[DVRCNMETA_SERVER_ICON] as! NSData)
        serverInfo.image = UIImage(data: info[DVRCNMETA_SERVER_IMAGE] as! NSData)
        servers.append(serverInfo)
        servers = servers.sort{$0.service.name < $1.service.name}
        let indexes = servers.enumerate().filter{$0.element.service.name == serverInfo.service.name}.map{$0.index}
        if let index = indexes.first {
            tableView.beginUpdates()
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
            tableView.endUpdates()
        }
        client.disconnect()
    }
 
    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビュー用データソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServerCell", forIndexPath: indexPath) as! DataSourceCell
        
        let serverCount = servers.count;
        let isRemote = indexPath.row < serverCount
        let name = isRemote ? servers[indexPath.row].service.name : AppDelegate.deviceName()
        let icon = isRemote ? servers[indexPath.row].icon : AppDelegate.deviceIcon()
        let description = isRemote ? servers[indexPath.row].attributes[DVRCNMETA_MACHINE_NAME] : nil
        cell.dataSourceLabel.text = name
        cell.descriptionLabel.text = description
        cell.accessoryType = .None
        cell.iconImageVIew.image = icon
        cell.iconImageVIew.contentMode = .ScaleAspectFit
        
        if isRemote {
            cell.detailTransitor = {[unowned self](cell : DataSourceCell) in
                self.detailTargetRow = indexPath.row
                self.performSegueWithIdentifier("DataSourceDetail", sender: self)
            }
        }else{
            cell.detailButton.enabled = false
            cell.detailButton.hidden = true
        }
        
        let client = DVRemoteClient.sharedClient()
        if client.state != .Disconnected && client.service == nil && indexPath.row == serverCount {
            cell.accessoryType = .Checkmark
        }else if client.state != .Disconnected && client.service != nil && client.service.name == name {
            cell.accessoryType = .Checkmark
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let serverCount = servers.count;
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
            let nextServer = servers[indexPath.row].service
            if client.state != .Disconnected && (client.service == nil || client.service!.name != nextServer.name) {
                client.disconnect()
                client.connectToServer(nextServer)
            }else if client.state == .Disconnected {
                client.connectToServer(nextServer)
            }
        }
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private var headerController : DataSourceHeaderController!

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return 54
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let storyboard = self.storyboard {
            headerController = storyboard.instantiateViewControllerWithIdentifier("dataSourceHeader") as! DataSourceHeaderController
            return headerController.view
        }else{
            return nil
        }
    }
    
    private var footerController : SimpleFooterViewController!

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let storyboard = self.storyboard{
            footerController =
                storyboard.instantiateViewControllerWithIdentifier("SimpleFooter") as! SimpleFooterViewController
            if footerController.view.subviews.count > 0 {
                footerController.textLabel.text = NSLocalizedString("MSG_DATASOURCE_DESCTIPTION", comment: "")
            }
            return footerController.view
        }else{
            return nil
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    private var detailTargetRow = -1
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DataSourceDetail" {
            let target = segue.destinationViewController as! DataSourceDetailViewController
            target.serverInfo = servers[detailTargetRow]
        }
    }

}
