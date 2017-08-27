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
    static fileprivate var headingDisplays = [
        NSLocalizedString("HEADING_DISPLAY_NONE", comment: ""),
        NSLocalizedString("HEADING_DISPLAY_ARROW", comment: ""),
        NSLocalizedString("HEADING_DISPLAY_FOV", comment: ""),
        NSLocalizedString("HEADING_DISPLAY_ARROW_AND_FOV", comment: ""),
    ]
    
    static fileprivate var summaryDisplays = [
        NSLocalizedString("SUMMARY_DISPLAY_NONE", comment: ""),
        NSLocalizedString("SUMMARY_DISPLAY_BALLOON", comment: ""),
        NSLocalizedString("SUMMARY_DISPLAY_PINNING", comment: ""),
    ]
    
    static fileprivate var dataSourceSeciotnIcons = [
        "icon_datasource",
    ]
    
    static fileprivate var mapSectionIcons = [
        "icon_maptype",
        "icon_maplabel",
        "icon_3dview",
        "icon_heading",
        "icon_summary",
        "icon_detailconfig",
    ]
    
    static fileprivate var otherSectionIcons = [
        "icon_lenslibrary",
        "icon_about",
    ]
    
    static fileprivate var icons : [[String]] = [
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
    fileprivate let configController = ConfigurationController.sharedController
    override func viewDidLoad() {
        super.viewDidLoad()
        reflectToControl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DVRemoteClient.shared().add(self)
        let client = DVRemoteClient.shared()
        connectionCell.detailTextLabel!.text = client?.state != .connected ? client?.stateString : AppDelegate.connectionName()
        headingDisplayCell.detailTextLabel!.text =
            PreferencesViewController.headingDisplays[configController.mapHeadingDisplay.rawValue]
        summaryDisplayCell.detailTextLabel!.text =
            PreferencesViewController.summaryDisplays[configController.mapSummaryDisplay.rawValue]
        lensLibraryCell.detailTextLabel!.text = "\(LensLibrary.shared().allLensProfiles.count)"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DVRemoteClient.shared().remove(self)
    }

    @IBAction func closeThisView(_ sender : UIBarButtonItem?){
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - コントロール状態へ反映
    //-----------------------------------------------------------------------------------------
    func reflectToControl() {
        mapTypeControl!.selectedSegmentIndex = configController.mapType.rawValue
        mapLabelSwitch.isOn = configController.mapShowLabel
        map3DSwitch.isOn = configController.map3DView
//        enableVolumeControl!.on = configController.enableVolumeButton
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 非表示セルの制御
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 && configController.mapType == .map {
            return super.tableView(tableView, numberOfRowsInSection: section) - 1
         }else{
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell! = nil
        var row = indexPath.row
        if indexPath.section == 1 && configController.mapType == .map && indexPath.row > 0 {
            let newIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            cell = super.tableView(tableView, cellForRowAt: newIndexPath)
            row += 1
        }else{
            cell = super.tableView(tableView, cellForRowAt: indexPath)
        }
        cell.imageView!.image = UIImage(named: PreferencesViewController.icons[indexPath.section][row])
        return cell
    }
    
    fileprivate var savedMapType : MapType = .map
    
    fileprivate func beginUpdateCellCount() {
        tableView.beginUpdates()
        savedMapType = configController.mapType
    }
    
    fileprivate func endUpdateCellCount() {
        let indexPaths = [IndexPath(row: 1, section: 1)]
        if savedMapType == .map && configController.mapType == .satellite {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }else if savedMapType == .satellite && configController.mapType == .map {
            tableView.deleteRows(at: indexPaths, with: .automatic)
        }
        tableView.endUpdates()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - UI要素のactionハンドラ
    //-----------------------------------------------------------------------------------------
    @IBAction func actionForMapType(_ sender : UISegmentedControl) {
        beginUpdateCellCount()
        configController.mapType = MapType(rawValue: sender.selectedSegmentIndex)!
        endUpdateCellCount()
        reflectToControl()
    }
    
    @IBAction func actionForMapLabelSwitch(_ sender: UISwitch) {
        configController.mapShowLabel = sender.isOn
    }
    
    @IBAction func actionForMap3DSwitch(_ sender: UISwitch) {
        configController.map3DView = sender.isOn
    }
    
    @IBAction func actionForEnableVolume(_ sender : UISwitch) {
        configController.enableVolumeButton = sender.isOn
        reflectToControl()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 接続状態を反映
    //-----------------------------------------------------------------------------------------
    func dvrClient(_ client: DVRemoteClient!, change state: DVRClientState) {
        let client = DVRemoteClient.shared()
        connectionCell.detailTextLabel!.text = client?.state != .connected ? client?.stateString : AppDelegate.connectionName()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let targetCell = tableView.cellForRow(at: tableView.indexPathForSelectedRow!) {
            if let identifier = targetCell.reuseIdentifier {
                if identifier == "selectHeadingCell" {
                    let target = segue.destination as! ItemSelectorViewController
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
                    let target = segue.destination as! ItemSelectorViewController
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
            tableView.deselectRow(at: index, animated: true)
        }
    }

}
