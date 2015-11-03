//
//  PreferencesViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/21.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class PreferencesViewController: UITableViewController, DVRemoteClientDelegate {
    @IBOutlet var mapTypeControl : UISegmentedControl?
    @IBOutlet weak var mapLabelSwitch: UISwitch!
    @IBOutlet weak var map3DSwitch: UISwitch!
    @IBOutlet var enableVolumeControl : UISwitch?
    @IBOutlet weak var connectionCell: UITableViewCell!
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 画面オープン・クローズ
    //-----------------------------------------------------------------------------------------
    private let configController = ConfigurationController.sharedController
    override func viewDidLoad() {
        super.viewDidLoad()
        reflectToControl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        DVRemoteClient.sharedClient().addClientDelegate(self)
        let client = DVRemoteClient.sharedClient()
        connectionCell.detailTextLabel!.text = client.state != .Connected ? client.stateString : client.serviceName
    }
    
    override func viewWillDisappear(animated: Bool) {
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    @IBAction func closeThisView(sender : UIBarButtonItem?){
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - コントロール状態へ反映
    //-----------------------------------------------------------------------------------------
    func reflectToControl() {
        mapTypeControl!.selectedSegmentIndex = configController.mapType.rawValue
        mapLabelSwitch.on = configController.mapShowLabel
        map3DSwitch.on = configController.map3DView
        enableVolumeControl!.on = configController.enableVolumeButton
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 非表示セルの制御
    //-----------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 && configController.mapType == .Map {
            return super.tableView(tableView, numberOfRowsInSection: section) - 1
         }else{
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 1 && configController.mapType == .Map && indexPath.row > 0 {
            let newIndexPath = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
            return super.tableView(tableView, cellForRowAtIndexPath: newIndexPath)
        }else{
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    private var savedMapType : MapType = .Map
    
    private func beginUpdateCellCount() {
        tableView.beginUpdates()
        savedMapType = configController.mapType
    }
    
    private func endUpdateCellCount() {
        let indexPaths = [NSIndexPath(forRow: 1, inSection: 1)]
        if savedMapType == .Map && configController.mapType == .Satellite {
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }else if savedMapType == .Satellite && configController.mapType == .Map {
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
        tableView.endUpdates()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - UI要素のactionハンドラ
    //-----------------------------------------------------------------------------------------
    @IBAction func actionForMapType(sender : UISegmentedControl) {
        beginUpdateCellCount()
        configController.mapType = MapType(rawValue: sender.selectedSegmentIndex)!
        endUpdateCellCount()
        reflectToControl()
    }
    
    @IBAction func actionForMapLabelSwitch(sender: UISwitch) {
        configController.mapShowLabel = sender.on
    }
    
    @IBAction func actionForMap3DSwitch(sender: UISwitch) {
        configController.map3DView = sender.on
    }
    
    @IBAction func actionForEnableVolume(sender : UISwitch) {
        configController.enableVolumeButton = sender.on
        reflectToControl()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 接続状態を反映
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        let client = DVRemoteClient.sharedClient()
        connectionCell.detailTextLabel!.text = client.state != .Connected ? client.stateString : client.serviceName
    }
    
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: true)
        }
    }

}
