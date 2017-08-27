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
    @IBOutlet weak var omitWarmUpSwitch: UISwitch!

    //-----------------------------------------------------------------------------------------
    // MARK: - 画面オープン・クローズ
    //-----------------------------------------------------------------------------------------
    fileprivate let configController = ConfigurationController.sharedController

    override func viewDidLoad() {
        super.viewDidLoad()
        collectCellCount()
        reflectToControl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reflectToControl()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }

    @IBAction func closeThisView(_ sender: UIBarButtonItem?) {
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - コントロール状態へ反映
    //-----------------------------------------------------------------------------------------
    func reflectToControl() {
        relateSpanSwitch.isOn = configController.mapRelationSpan
        relateSpanMethodCell.detailTextLabel!.text = MapDetailPreferencesViewController.spanRelationMethods[
            configController.mapRelationSpanMethod.rawValue
        ]
        turnToHeadingSwitch.isOn = configController.mapTurnToHeading
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
        omitWarmUpSwitch.isOn = !configController.mapNeedWarmUp
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 非表示セルの制御
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !configController.mapRelationSpan {
            return 1
        }else if section == 1 && !configController.mapTurnToHeading {
            return 1
        }else{
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    fileprivate var relationSectionCellCount = 0
    fileprivate var relationSectionCellIndexes : [IndexPath] = []
    fileprivate var savedRelationState = false
    fileprivate var headingSectionCellCount = 0
    fileprivate var headingSectionCellIndexes : [IndexPath] = []
    fileprivate var savedHeadingState = false
    
    fileprivate func collectCellCount() {
        relationSectionCellCount = super.tableView(tableView, numberOfRowsInSection: 0)
        for i in 1 ..< relationSectionCellCount {
            relationSectionCellIndexes.append(IndexPath(item: i, section: 0))
        }
        headingSectionCellCount = super.tableView(tableView, numberOfRowsInSection: 1)
        for i in 1 ..< headingSectionCellCount {
            headingSectionCellIndexes.append(IndexPath(item: i, section: 1))
        }
    }
    
    fileprivate func beginUpdateCellCount() {
        tableView.beginUpdates()
        configController.beginMapDetailConfigurationTransaction()
        savedRelationState = configController.mapRelationSpan
        savedHeadingState = configController.mapTurnToHeading
    }
    
    fileprivate func endUpdateCellCount() {
        if savedRelationState && !configController.mapRelationSpan {
            tableView.deleteRows(at: relationSectionCellIndexes, with: .automatic)
        }else if !savedRelationState && configController.mapRelationSpan {
            tableView.insertRows(at: relationSectionCellIndexes, with: .automatic)
        }
        if savedHeadingState && !configController.mapTurnToHeading {
            tableView.deleteRows(at: headingSectionCellIndexes, with: .automatic)
        }else if !savedHeadingState && configController.mapTurnToHeading {
            tableView.insertRows(at: headingSectionCellIndexes, with: .automatic)
        }
        configController.commitMapDetailConfigurationTransaction()
        tableView.endUpdates()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - UI要素のactionハンドラ
    //-----------------------------------------------------------------------------------------
    @IBAction func actionForSpanRelationSwitch(_ sender: UISwitch) {
        beginUpdateCellCount()
        configController.mapRelationSpan = sender.isOn
        endUpdateCellCount()
    }
    
    @IBAction func actionForTurnToHeadingSwitch(_ sender: UISwitch) {
        beginUpdateCellCount()
        configController.mapTurnToHeading = sender.isOn
        endUpdateCellCount()
    }

    @IBAction func actionForHeadingShiftSlider(_ sender: UISlider) {
        configController.mapHeadingShift = CGFloat(sender.value)
    }
    
    @IBAction func actionForSpanSlider(_ sender: UISlider) {
        configController.mapSpan = CGFloat(pow(10.0, Double(sender.value)))
        spanLabel.text = configController.mapSpanString
    }
    
    @IBAction func actionForTiltSlider(_ sender: UISlider) {
        configController.mapTilt = CGFloat(sender.value)
        tiltLabel.text = configController.mapTiltString
    }

    @IBAction func actionForOmitWarmUpSwitch(_ sender: UISwitch) {
        configController.mapNeedWarmUp = !sender.isOn
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - セル選択に応じたアクション
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let targetCell = tableView.cellForRow(at: indexPath) {
            if let identifier = targetCell.reuseIdentifier {
                if identifier == "ApplyCurrentMapCell" {
                    applyCurrentMap()
                }else if identifier == "RestoreDefaultSettingsCell" {
                    restoreDefaultSettings()
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func applyCurrentMap() {
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
    
    fileprivate func restoreDefaultSettings() {
        let alert = UIAlertController(
            title: NSLocalizedString("MAP_RESTORE_TITLE", comment: ""),
            message: NSLocalizedString("MAP_RESTORE_MESSAGE", comment: ""),
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default){
            [unowned self] action in
            self.beginUpdateCellCount()
            self.configController.mapRelationSpan = self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapRelationSpan)! as! Bool
            self.configController.mapRelationSpanMethod =
                MapRelationSpanMethod(rawValue: self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapRelationSpanMethod)! as! Int)!
            self.configController.mapTurnToHeading = self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapTurnToHeading)! as! Bool
            self.configController.mapHeadingShift =
                CGFloat(self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapHeadingShift)! as! Double)
            self.configController.mapSpan = CGFloat(self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapSpan)! as! Double)
            self.configController.mapTilt = CGFloat(self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapTilt)! as! Double)
            self.configController.mapPinColor = NSKeyedUnarchiver.unarchiveObject(
                with: self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapPinColor)! as! Data) as! UIColor
            self.configController.mapArrowColor = NSKeyedUnarchiver.unarchiveObject(
                with: self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapArrowColor)! as! Data) as! UIColor
            self.configController.mapFovColor = NSKeyedUnarchiver.unarchiveObject(
                with: self.configController.defaultValue(DVremoteCommonUI.UserDefaults.MapFOVColor)! as! Data) as! UIColor
            self.endUpdateCellCount()
            self.reflectToControl()
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Segue遷移処理
    //-----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let targetCell = tableView.cellForRow(at: tableView.indexPathForSelectedRow!) {
            if let identifier = targetCell.reuseIdentifier {
                if identifier == "SelectSpanMethodCell" {
                    let target = segue.destination as! ItemSelectorViewController
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
                    let target = segue.destination as! ItemSelectorViewController
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
                    let target = segue.destination as! ColorPickerViewController
                    let identity = ColorPickerIdentity()
                    identity.title = pinColorLabel.text
                    identity.color = configController.mapPinColor
                    identity.changeNotifier = {[unowned self](color:UIColor) in
                        self.configController.mapPinColor = color
                    }
                    target.identity = identity
                }else if identifier == "ArrowColorCell" {
                    let target = segue.destination as! ColorPickerViewController
                    let identity = ColorPickerIdentity()
                    identity.title = arrowColorLabel.text
                    identity.color = configController.mapArrowColor
                    identity.changeNotifier = {[unowned self](color:UIColor) in
                        self.configController.mapArrowColor = color
                    }
                    target.identity = identity
                }else if identifier == "CircleColorCell" {
                    let target = segue.destination as! ColorPickerViewController
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
