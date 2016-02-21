//
//  PreferencesViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/21.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI
import DVremoteCommonLib

class PreferencesViewController: UITableViewController, DVRemoteClientDelegate {
    static private var headingDisplays = [
        NSLocalizedString("HEADING_DISPLAY_NONE", comment: ""),
        NSLocalizedString("HEADING_DISPLAY_ARROW", comment: ""),
        NSLocalizedString("HEADING_DISPLAY_FOV", comment: ""),
        NSLocalizedString("HEADING_DISPLAY_ARROW_AND_FOV", comment: ""),
    ]
    
    static private var summaryDisplays = [
        NSLocalizedString("SUMMARY_DISPLAY_NONE", comment: ""),
        NSLocalizedString("SUMMARY_DISPLAY_BALLOON", comment: ""),
        NSLocalizedString("SUMMARY_DISPLAY_PINNING", comment: ""),
    ]
    
    static private var dataSourceSeciotnIcons = [
        "icon_datasource",
    ]
    
    static private var mapSectionIcons = [
        "icon_maptype",
        "icon_maplabel",
        "icon_3dview",
        "icon_heading",
        "icon_summary",
        "icon_detailconfig",
    ]
    
    static private var otherSectionIcons = [
        "icon_lenslibrary",
        "icon_about",
    ]
    
    static private var icons : [[String]] = [
        PreferencesViewController.dataSourceSeciotnIcons,
        PreferencesViewController.mapSectionIcons,
        PreferencesViewController.otherSectionIcons,
    ]
    
    @IBOutlet var mapTypeControl : UISegmentedControl?
    @IBOutlet weak var mapLabelSwitch: UISwitch!
    @IBOutlet weak var map3DSwitch: UISwitch!
    @IBOutlet var enableVolumeControl : UISwitch?
    @IBOutlet weak var connectionCell: UITableViewCell!
    @IBOutlet weak var headingDisplayCell: UITableViewCell!
    @IBOutlet weak var summaryDisplayCell: UITableViewCell!
    @IBOutlet weak var lensLibraryCell: UITableViewCell!
    
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
        connectionCell.detailTextLabel!.text = client.state != .Connected ? client.stateString : AppDelegate.connectionName()
        headingDisplayCell.detailTextLabel!.text =
            PreferencesViewController.headingDisplays[configController.mapHeadingDisplay.rawValue]
        summaryDisplayCell.detailTextLabel!.text =
            PreferencesViewController.summaryDisplays[configController.mapSummaryDisplay.rawValue]
        lensLibraryCell.detailTextLabel!.text = "\(LensLibrary.sharedLensLibrary().allLensProfiles.count)"
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
//        enableVolumeControl!.on = configController.enableVolumeButton
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
        var cell : UITableViewCell! = nil
        var row = indexPath.row
        if indexPath.section == 1 && configController.mapType == .Map && indexPath.row > 0 {
            let newIndexPath = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
            cell = super.tableView(tableView, cellForRowAtIndexPath: newIndexPath)
            row++
        }else{
            cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
        cell.imageView!.image = UIImage(named: PreferencesViewController.icons[indexPath.section][row])
        return cell
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
        connectionCell.detailTextLabel!.text = client.state != .Connected ? client.stateString : AppDelegate.connectionName()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let targetCell = tableView.cellForRowAtIndexPath(tableView.indexPathForSelectedRow!) {
            if let identifier = targetCell.reuseIdentifier {
                if identifier == "selectHeadingCell" {
                    let target = segue.destinationViewController as! ItemSelectorViewController
                    let identity = ItemSelectorIdentity()
                    identity.title = NSLocalizedString("HEADING_DISPLAY", comment: "")
                    identity.selectionIndex = configController.mapHeadingDisplay.rawValue
                    identity.description = nil
                    identity.items = PreferencesViewController.headingDisplays
                    identity.changeNotifier = {[unowned self](identity : ItemSelectorIdentity, index : Int) in
                        self.configController.mapHeadingDisplay = MapHeadingDisplay(rawValue: index)!
                    }
                    target.identity = identity
                }else if identifier == "selectSummaryCell" {
                    let target = segue.destinationViewController as! ItemSelectorViewController
                    let identity = ItemSelectorIdentity()
                    identity.title = NSLocalizedString("SUMMARY_DISPLAY", comment: "")
                    identity.selectionIndex = configController.mapSummaryDisplay.rawValue
                    identity.description = nil
                    identity.items = PreferencesViewController.summaryDisplays
                    identity.changeNotifier = {[unowned self](identity : ItemSelectorIdentity, index : Int) in
                        self.configController.mapSummaryDisplay = MapSummaryDisplay(rawValue: index)!
                    }
                    target.identity = identity
                }
            }
        }
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: true)
        }
    }

}
