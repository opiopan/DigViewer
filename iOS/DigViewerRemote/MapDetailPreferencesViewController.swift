//
//  MapDetailPreferencesViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/24.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI

class MapDetailPreferencesViewController: UITableViewController {
    static var spanRelationMethods = [
        NSLocalizedString("SPAN_RELATION_METHOD_LONG_SIDE", comment: ""),
        NSLocalizedString("SPAN_RELATION_METHOD_SHORT_SIDE", comment: ""),
    ]
    
    static var summaryPinningStyles = [
        NSLocalizedString("SUMMARY_PINNING_STYLE_TOOLBAR", comment: ""),
        NSLocalizedString("SUMMARY_PINNING_STYLE_LOWER_LEFT", comment: ""),
        NSLocalizedString("SUMMARY_PINNING_STYLE_LOWER_RIGHT", comment: ""),
    ]
    
    @IBOutlet weak var relateSpanSwitch: UISwitch!
    @IBOutlet weak var relateSpanMethodCell: UITableViewCell!
    @IBOutlet weak var turnToHeadingSwitch: UISwitch!
    @IBOutlet weak var headingShiftSlider: UISlider!
    @IBOutlet weak var spanSlider: UISlider!
    @IBOutlet weak var spanLabel: UILabel!
    @IBOutlet weak var tiltSlider: UISlider!
    @IBOutlet weak var tiltLabel: UILabel!
    @IBOutlet weak var pinColorView: UIView!
    @IBOutlet weak var pinColorLabel: UILabel!
    @IBOutlet weak var arrowColorView: UIView!
    @IBOutlet weak var arrowColorLabel: UILabel!
    @IBOutlet weak var fovColorView: UIView!
    @IBOutlet weak var fovColorLabel: UILabel!
    @IBOutlet weak var summaryPinningStyleCell: UITableViewCell!

    //-----------------------------------------------------------------------------------------
    // MARK: - 画面オープン・クローズ
    //-----------------------------------------------------------------------------------------
    private let configController = ConfigurationController.sharedController

    override func viewDidLoad() {
        super.viewDidLoad()
        collectCellCount()
        reflectToControl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        reflectToControl()
    }
    
    override func viewWillDisappear(animated: Bool) {
    }

    @IBAction func closeThisView(sender: UIBarButtonItem?) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - コントロール状態へ反映
    //-----------------------------------------------------------------------------------------
    func reflectToControl() {
        relateSpanSwitch.on = configController.mapRelationSpan
        relateSpanMethodCell.detailTextLabel!.text = MapDetailPreferencesViewController.spanRelationMethods[
            configController.mapRelationSpanMethod.rawValue
        ]
        turnToHeadingSwitch.on = configController.mapTurnToHeading
        headingShiftSlider.value = Float(configController.mapHeadingShift)
        spanLabel.text = configController.mapSpanString
        spanSlider.value = Float(log10(configController.mapSpan))
        tiltLabel.text = configController.mapTiltString
        tiltSlider.value = Float(configController.mapTilt)
        pinColorView.backgroundColor = configController.mapPinColor
        arrowColorView.backgroundColor = configController.mapArrowColor
        fovColorView.backgroundColor = configController.mapFovColor
        summaryPinningStyleCell.detailTextLabel!.text = MapDetailPreferencesViewController.summaryPinningStyles[
            configController.mapSummaryPinningStyle.rawValue
        ]
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 非表示セルの制御
    //-----------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !configController.mapRelationSpan {
            return 1
        }else if section == 1 && !configController.mapTurnToHeading {
            return 1
        }else{
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    private var relationSectionCellCount = 0
    private var relationSectionCellIndexes : [NSIndexPath] = []
    private var savedRelationState = false
    private var headingSectionCellCount = 0
    private var headingSectionCellIndexes : [NSIndexPath] = []
    private var savedHeadingState = false
    
    private func collectCellCount() {
        relationSectionCellCount = super.tableView(tableView, numberOfRowsInSection: 0)
        for var i = 1; i < relationSectionCellCount; i++ {
            relationSectionCellIndexes.append(NSIndexPath(forItem: i, inSection: 0))
        }
        headingSectionCellCount = super.tableView(tableView, numberOfRowsInSection: 1)
        for var i = 1; i < headingSectionCellCount; i++ {
            headingSectionCellIndexes.append(NSIndexPath(forItem: i, inSection: 1))
        }
    }
    
    private func beginUpdateCellCount() {
        tableView.beginUpdates()
        configController.beginMapDetailConfigurationTransaction()
        savedRelationState = configController.mapRelationSpan
        savedHeadingState = configController.mapTurnToHeading
    }
    
    private func endUpdateCellCount() {
        if savedRelationState && !configController.mapRelationSpan {
            tableView.deleteRowsAtIndexPaths(relationSectionCellIndexes, withRowAnimation: .Automatic)
        }else if !savedRelationState && configController.mapRelationSpan {
            tableView.insertRowsAtIndexPaths(relationSectionCellIndexes, withRowAnimation: .Automatic)
        }
        if savedHeadingState && !configController.mapTurnToHeading {
            tableView.deleteRowsAtIndexPaths(headingSectionCellIndexes, withRowAnimation: .Automatic)
        }else if !savedHeadingState && configController.mapTurnToHeading {
            tableView.insertRowsAtIndexPaths(headingSectionCellIndexes, withRowAnimation: .Automatic)
        }
        configController.commitMapDetailConfigurationTransaction()
        tableView.endUpdates()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - UI要素のactionハンドラ
    //-----------------------------------------------------------------------------------------
    @IBAction func actionForSpanRelationSwitch(sender: UISwitch) {
        beginUpdateCellCount()
        configController.mapRelationSpan = sender.on
        endUpdateCellCount()
    }
    
    @IBAction func actionForTurnToHeadingSwitch(sender: UISwitch) {
        beginUpdateCellCount()
        configController.mapTurnToHeading = sender.on
        endUpdateCellCount()
    }

    @IBAction func actionForHeadingShiftSlider(sender: UISlider) {
        configController.mapHeadingShift = CGFloat(sender.value)
    }
    
    @IBAction func actionForSpanSlider(sender: UISlider) {
        configController.mapSpan = CGFloat(pow(10.0, Double(sender.value)))
        spanLabel.text = configController.mapSpanString
    }
    
    @IBAction func actionForTiltSlider(sender: UISlider) {
        configController.mapTilt = CGFloat(sender.value)
        tiltLabel.text = configController.mapTiltString
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - セル選択に応じたアクション
    //-----------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let targetCell = tableView.cellForRowAtIndexPath(indexPath) {
            if let identifier = targetCell.reuseIdentifier {
                if identifier == "ApplyCurrentMapCell" {
                    applyCurrentMap()
                }else if identifier == "RestoreDefaultSettingsCell" {
                    restoreDefaultSettings()
                }
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private func applyCurrentMap() {
        beginUpdateCellCount()
        let controller = self.navigationController as! PreferencesNavigationController
        configController.mapSpan = CGFloat(MapGeometry.mapToSpan(controller.mapView))
        let camera = controller.mapView.camera
        if configController.map3DView || camera.pitch > 2 {
            configController.mapTilt = camera.pitch
        }
        configController.mapRelationSpan = false
        endUpdateCellCount()
        reflectToControl()
    }
    
    private func restoreDefaultSettings() {
        let alert = UIAlertController(
            title: NSLocalizedString("MAP_RESTORE_TITLE", comment: ""),
            message: NSLocalizedString("MAP_RESTORE_MESSAGE", comment: ""),
            preferredStyle: .Alert)
        let okAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .Default){
            [unowned self] action in
            self.beginUpdateCellCount()
            self.configController.mapRelationSpan = self.configController.defaultValue(UserDefaults.MapRelationSpan)! as! Bool
            self.configController.mapRelationSpanMethod =
                MapRelationSpanMethod(rawValue: self.configController.defaultValue(UserDefaults.MapRelationSpanMethod)! as! Int)!
            self.configController.mapTurnToHeading = self.configController.defaultValue(UserDefaults.MapTurnToHeading)! as! Bool
            self.configController.mapHeadingShift =
                CGFloat(self.configController.defaultValue(UserDefaults.MapHeadingShift)! as! Double)
            self.configController.mapSpan = CGFloat(self.configController.defaultValue(UserDefaults.MapSpan)! as! Double)
            self.configController.mapTilt = CGFloat(self.configController.defaultValue(UserDefaults.MapTilt)! as! Double)
            self.configController.mapPinColor = NSKeyedUnarchiver.unarchiveObjectWithData(
                self.configController.defaultValue(UserDefaults.MapPinColor)! as! NSData) as! UIColor
            self.configController.mapArrowColor = NSKeyedUnarchiver.unarchiveObjectWithData(
                self.configController.defaultValue(UserDefaults.MapArrowColor)! as! NSData) as! UIColor
            self.configController.mapFovColor = NSKeyedUnarchiver.unarchiveObjectWithData(
                self.configController.defaultValue(UserDefaults.MapFOVColor)! as! NSData) as! UIColor
            self.endUpdateCellCount()
            self.reflectToControl()
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Segue遷移処理
    //-----------------------------------------------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let targetCell = tableView.cellForRowAtIndexPath(tableView.indexPathForSelectedRow!) {
            if let identifier = targetCell.reuseIdentifier {
                if identifier == "SelectSpanMethodCell" {
                    let target = segue.destinationViewController as! ItemSelectorViewController
                    let identity = ItemSelectorIdentity()
                    identity.title = NSLocalizedString("SPAN_RELATION_METHOD", comment: "")
                    identity.selectionIndex = configController.mapRelationSpanMethod.rawValue
                    identity.description = nil
                    identity.items = MapDetailPreferencesViewController.spanRelationMethods
                    identity.changeNotifier = {[unowned self](identity : ItemSelectorIdentity, index : Int) in
                        self.configController.mapRelationSpanMethod = MapRelationSpanMethod(rawValue: index)!
                    }
                    target.identity = identity
                }else if identifier == "SelectPinningStyleCell" {
                    let target = segue.destinationViewController as! ItemSelectorViewController
                    let identity = ItemSelectorIdentity()
                    identity.title = targetCell.textLabel!.text
                    identity.selectionIndex = configController.mapSummaryPinningStyle.rawValue
                    identity.description = nil
                    identity.items = MapDetailPreferencesViewController.summaryPinningStyles
                    identity.changeNotifier = {[unowned self](identity : ItemSelectorIdentity, index : Int) in
                        self.configController.mapSummaryPinningStyle = MapSummaryPinningStyle(rawValue: index)!
                    }
                    target.identity = identity
                }else if identifier == "PinColorCell" {
                    let target = segue.destinationViewController as! ColorPickerViewController
                    let identity = ColorPickerIdentity()
                    identity.title = pinColorLabel.text
                    identity.color = configController.mapPinColor
                    identity.changeNotifier = {[unowned self](color:UIColor) in
                        self.configController.mapPinColor = color
                    }
                    target.identity = identity
                }else if identifier == "ArrowColorCell" {
                    let target = segue.destinationViewController as! ColorPickerViewController
                    let identity = ColorPickerIdentity()
                    identity.title = arrowColorLabel.text
                    identity.color = configController.mapArrowColor
                    identity.changeNotifier = {[unowned self](color:UIColor) in
                        self.configController.mapArrowColor = color
                    }
                    target.identity = identity
                }else if identifier == "CircleColorCell" {
                    let target = segue.destinationViewController as! ColorPickerViewController
                    let identity = ColorPickerIdentity()
                    identity.title = fovColorLabel.text
                    identity.color = configController.mapFovColor
                    identity.changeNotifier = {[unowned self](color:UIColor) in
                        self.configController.mapFovColor = color
                    }
                    target.identity = identity
                }
            }
        }
    }

}
