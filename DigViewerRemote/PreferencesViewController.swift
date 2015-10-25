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
    // MARK: - UI要素のactionハンドラ
    //-----------------------------------------------------------------------------------------
    @IBAction func actionForMapType(sender : UISegmentedControl) {
        configController.mapType = MapType(rawValue: sender.selectedSegmentIndex)!
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
