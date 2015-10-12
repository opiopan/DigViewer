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
    @IBOutlet var mapLabelControl : UITableViewCell?
    @IBOutlet var map3DControl : UITableViewCell?
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
        mapLabelControl!.accessoryType = configController.mapShowLabel ? .Checkmark : .None
        map3DControl!.accessoryType = configController.map3DView ? .Checkmark : .None
        enableVolumeControl!.on = configController.enableVolumeButton
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - UI要素のactionハンドラ
    //-----------------------------------------------------------------------------------------
    @IBAction func actionForMapType(sender : UISegmentedControl) {
        configController.mapType = MapType(rawValue: sender.selectedSegmentIndex)!
        reflectToControl()
    }
    
    @IBAction func actionForEnableVolume(sender : UISwitch) {
        configController.enableVolumeButton = sender.on
        reflectToControl()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 選択状態の変更
    //-----------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let targetCell = cell{
            if let identifier = targetCell.restorationIdentifier {
                if identifier == "ShowLabels" {
                    configController.mapShowLabel = !configController.mapShowLabel
                    reflectToControl()
                }else if identifier == "3DBirdsView" {
                    configController.map3DView = !configController.map3DView
                    reflectToControl()
                }
            }
        }
        
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 接続状態を反映
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        let client = DVRemoteClient.sharedClient()
        connectionCell.detailTextLabel!.text = client.state != .Connected ? client.stateString : client.serviceName
    }
}
