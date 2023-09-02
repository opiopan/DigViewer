//
//  ServersViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI
import DVremoteCommonLib

class ServerViewController: UITableViewController, DVRemoteBrowserDelegate, DVRemoteClientDelegate {

    fileprivate let browser : DVRemoteBrowser = DVRemoteBrowser()

    override func viewDidLoad() {
        super.viewDidLoad()
        browser.delegate = self
        browser.searchServers()

        headerController =
            storyboard!.instantiateViewController(withIdentifier: "dataSourceHeader") as? DataSourceHeaderController
        footerController =
            storyboard!.instantiateViewController(withIdentifier: "SimpleFooter") as? SimpleFooterViewController
        let localBrowser = browser
        let localHeader = headerController
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(10 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)){
            if localBrowser.servers.count == 0 {
                localHeader?.activityIndicator.stopAnimating()
            }
        }
    }
    
    deinit{
        browser.stop()
        tmpClient?.tmpDelegate = nil
        tmpClient?.disconnect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        syncPinnedList()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }

    @IBAction func closeServersView(_ sender : UIBarButtonItem?){
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - サーバーリスト操作
    //-----------------------------------------------------------------------------------------
    fileprivate var pinnedServers : [ServerInfo] = []
    fileprivate var servers : [ServerInfo] = []

    fileprivate func syncPinnedList() {
        self.pinnedServers = ConfigurationController.sharedController.dataSourcePinnedList

        // 削除
        let deletee = servers.enumerated().filter{
            [unowned self] in
            let name = $0.element.service.name
            return !$0.element.isActive && self.pinnedServers.filter{$0.service.name == name}.count == 0
        }.reversed().map{IndexPath(row:$0.offset, section:0)}
        for index in deletee.reversed() {
            servers.remove(at: index.row)
        }
        tableView.beginUpdates()
        tableView.deleteRows(at: deletee, with: .automatic)
        tableView.endUpdates()
        
        // 追加
        let addee = pinnedServers.filter{
            [unowned self] in
            let name = $0.service.name
            return self.servers.filter{$0.service.name == name}.count == 0
        }.map{ServerInfo(src: $0)}
        servers.append(contentsOf: addee)
        servers = servers.sorted{$0.service.name < $1.service.name}
        let addeeIndexes = pinnedServers.enumerated().filter{
            let name = $0.element.service.name
            return addee.filter{$0.service.name == name}.count > 0
        }.map{IndexPath(row: $0.offset, section: 0)}
        tableView.beginUpdates()
        tableView.deleteRows(at: addeeIndexes, with: .automatic)
        tableView.endUpdates()
    }
    
    fileprivate func registerServer(_ serverInfo : ServerInfo) {
        let pinnedIndexes = servers.enumerated().filter{$0.element.service.name == serverInfo.service.name}.map{$0.offset}
        if let pinnedIndex = pinnedIndexes.first {
            if pinnedServers[pinnedIndex].attributes[DVRCNMETA_OS_VERSION] != serverInfo.attributes[DVRCNMETA_OS_VERSION] ||
                pinnedServers[pinnedIndex].attributes[DVRCNMETA_DV_VERSION] != serverInfo.attributes[DVRCNMETA_DV_VERSION]{
                serverInfo.isPinned = true
                pinnedServers = pinnedServers.enumerated().map{$0.offset == pinnedIndex ? serverInfo : $0.element}
                ConfigurationController.sharedController.dataSourcePinnedList = pinnedServers
                servers[pinnedIndex] = serverInfo
            }
            servers[pinnedIndex].isActive = true
            let indexPath = IndexPath(row: pinnedIndex, section: 0)
            if let cell = tableView.cellForRow(at: indexPath){
                setupCell(cell as! DataSourceCell, indexPath: indexPath, animated: true)
            }
        }else{
            serverInfo.isActive = true
            servers.append(serverInfo)
            servers = servers.sorted{$0.service.name < $1.service.name}
            let indexes = servers.enumerated().filter{$0.element.service.name == serverInfo.service.name}.map{$0.offset}
            if let index = indexes.first {
                tableView.beginUpdates()
                tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                tableView.endUpdates()
            }
        }
    }
    
    fileprivate func unregisterServer(_ name : String) {
        let indexes = servers.enumerated().filter{$0.element.service.name == name}.map{$0.offset}
        if let index = indexes.first {
            let isPinned = pinnedServers.filter{$0.service.name == name}.count > 0
            if  isPinned {
                servers[index].isActive = false;
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) {
                    setupCell(cell as! DataSourceCell, indexPath: indexPath, animated: true)
                }
            }else{
                servers.remove(at: index)
                tableView.beginUpdates()
                tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                tableView.endUpdates()
            }
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - サーバー探索
    //-----------------------------------------------------------------------------------------
    func dvrBrowserDetectAddServer(_ browser: DVRemoteBrowser!, service: NetService!) {
        let serverInfo = ServerInfo()
        serverInfo.service = service
        addServerInfo(serverInfo)
    }
    
    func dvrBrowserDetectRemoveServer(_ browser: DVRemoteBrowser!, service: NetService!) {
        unregisterServer(service.name)
    }
    
    func dvrBrowser(_ browser: DVRemoteBrowser!, didNotSearch errorDict: [AnyHashable: Any]!) {
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - サーバー情報収集
    //-----------------------------------------------------------------------------------------
    fileprivate var queryingServers : [ServerInfo] = []
    fileprivate let tmpClient = DVRemoteClient.temporary()
    
    fileprivate func addServerInfo(_ serverInfo: ServerInfo){
        queryingServers.append(serverInfo)
        if queryingServers.count == 1 {
            queryServerInfo()
        }
    }
    
    fileprivate func queryServerInfo(){
        headerController.activityIndicator.startAnimating()
        tmpClient?.tmpDelegate = self
        tmpClient?.connect(toServer: queryingServers[0].service, withKey: nil, fromDevice: AppDelegate.deviceID())
    }
    
    func dvrClient(_ client: DVRemoteClient!, change state: DVRClientState) {
        if state == .authenticating || state == .connected{
            client.requestServerInfo()
        }else if state == .disconnected {
            headerController.activityIndicator.stopAnimating()
            queryingServers.remove(at: 0)
            if queryingServers.count > 0 {
                queryServerInfo()
            }
        }
    }
    
    func dvrClient(_ client: DVRemoteClient!, didRecieveServerInfo info: [AnyHashable: Any]!) {
        let serverInfo = queryingServers[0];
        serverInfo.attributes = info[DVRCNMETA_SERVER_INFO] as? [String : String]
        if let data = info[DVRCNMETA_SERVER_ICON] as! Data? {
            serverInfo.icon = UIImage(data: data)
        }
        if let data = info[DVRCNMETA_SERVER_IMAGE] as! Data? {
            serverInfo.image = UIImage(data: data)
        }
        registerServer(serverInfo)
        client.disconnect()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - セル状態設定
    //-----------------------------------------------------------------------------------------
    fileprivate func setupCell(_ cell : DataSourceCell, indexPath : IndexPath, animated : Bool) {
        let serverCount = servers.count;
        let isRemote = indexPath.row < serverCount
        let name = isRemote ? servers[indexPath.row].service.name : AppDelegate.deviceName()
        let icon = (isRemote ? servers[indexPath.row].icon : AppDelegate.deviceIcon())?.withRenderingMode(.alwaysTemplate)
        let description = isRemote ? servers[indexPath.row].attributes[DVRCNMETA_MACHINE_NAME] : nil
        cell.dataSourceLabel.text = name
        cell.descriptionLabel.text = description
        cell.accessoryType = .none
        cell.iconImageVIew.image = icon
        cell.iconImageVIew.contentMode = .scaleAspectFit
        
        if isRemote {
            let targetName = servers[indexPath.row].service.name
            cell.detailTransitor = {[unowned self](cell : DataSourceCell) in
                self.detailTargetName = targetName
                self.performSegue(withIdentifier: "DataSourceDetail", sender: self)
            }
        }else{
            cell.detailButton.isEnabled = false
            cell.detailButton.isHidden = true
        }
        
        let client = DVRemoteClient.shared()
        if client?.state != .disconnected && client?.service == nil && indexPath.row == serverCount {
            cell.accessoryType = .checkmark
        }else if client?.state != .disconnected && client?.service != nil && client?.service.name == name {
            cell.accessoryType = .checkmark
        }

        let block = {
            if isRemote && !self.servers[indexPath.row].isActive {
                cell.selectionStyle = .none
                cell.iconImageVIew.alpha = 0.27
                cell.dataSourceLabel.alpha = 0.27
                cell.descriptionLabel.alpha = 0.45
                //            cell.dataSourceLabel.textColor = UIColor.lightGrayColor()
                //            cell.descriptionLabel.textColor = UIColor.lightGrayColor()
            }else{
                cell.selectionStyle = .default
                cell.iconImageVIew.alpha = 1.0
                cell.dataSourceLabel.alpha = 1.0
                cell.descriptionLabel.alpha = 1.0
                //            cell.dataSourceLabel.textColor = UIColor.blackColor()
                //            cell.descriptionLabel.textColor = UIColor(red: 111/256, green: 113/256, blue: 121/256, alpha: 1)
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.35, animations: block)
        }else{
            UIView.performWithoutAnimation(block)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビュー用データソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServerCell", for: indexPath) as! DataSourceCell
        setupCell(cell, indexPath: indexPath, animated: false)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let serverCount = servers.count;
        let client = DVRemoteClient.shared()
        if indexPath.row == serverCount {
            var needConnect = false
            if client?.state != .disconnected && client?.service != nil {
                client?.disconnect()
                needConnect = true
            }else if client?.state == .disconnected {
                needConnect = true
            }
            if needConnect {
                let time = DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {() -> Void in
                    client?.connectToLocal()
                })
            }
        }else{
            if !servers[indexPath.row].isActive {
                return
            }
            let nextServer = servers[indexPath.row].service
            let nextKey = ConfigurationController.sharedController.authenticationgKeys[(nextServer?.name)!]
            if client?.state != .disconnected && (client?.service == nil || client?.service!.name != nextServer?.name) {
                client?.disconnect()
                client?.connect(toServer: nextServer, withKey: nextKey, fromDevice: AppDelegate.deviceID())
            }else if client?.state == .disconnected {
                client?.connect(toServer: nextServer, withKey:  nextKey, fromDevice: AppDelegate.deviceID())
            }
        }
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    fileprivate var headerController : DataSourceHeaderController!

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return 54
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return headerController.view
        }else{
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
    }
    
    fileprivate var footerController : SimpleFooterViewController!

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            if footerController.view.subviews.count > 0 {
                footerController.textLabel.text = NSLocalizedString("MSG_DATASOURCE_DESCTIPTION", comment: "")
            }
            return footerController.view
        }else{
            return super.tableView(tableView, viewForFooterInSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 150
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    fileprivate var detailTargetName = ""
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DataSourceDetail" {
            let target = segue.destination as! DataSourceDetailViewController
            let isPinned = pinnedServers.filter{$0.service.name == detailTargetName}.count > 0
            let indexes = servers.enumerated().filter{$0.element.service.name == detailTargetName}.map{$0.offset}
            if let index = indexes.first {
                servers[index].isPinned = isPinned
                target.serverInfo = servers[index]
            }
        }
    }
}
