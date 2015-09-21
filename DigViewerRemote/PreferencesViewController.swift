//
//  PreferencesViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/21.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class PreferencesViewController: UITableViewController {
    @IBOutlet var mapTypeControl : UISegmentedControl?
    @IBOutlet var mapLabelControl : UITableViewCell?
    @IBOutlet var map3DControl : UITableViewCell?
    @IBOutlet var enableVolumeControl : UISwitch?
    
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
        closeThisView(nil)
    }
    
    @IBAction func actionForEnableVolume(sender : UISwitch) {
        configController.enableVolumeButton = sender.on
        closeThisView(nil)
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
                    closeThisView(nil)
                }else if identifier == "3DBirdsView" {
                    configController.map3DView = !configController.map3DView
                    closeThisView(nil)
                }
            }
        }
        
    }
}
