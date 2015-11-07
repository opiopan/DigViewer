//
//  ColorPickerViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/07.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class ColorPickerIdentity {
    var title : String!
    var description : String!
    var color : UIColor!
    var changeNotifier : ((UIColor) -> (Void))? = nil
}

class ColorPickerViewController: UITableViewController {
    private struct ColorEntry {
        var name : String
        var color : UIColor
        init(name : String, color : UIColor){
            self.name = name
            self.color = color
        }
    }
    
    private let colorList : [ColorEntry] = [
        ColorEntry(name: NSLocalizedString("COLOR_BLACK", comment:""), color: UIColor.blackColor()),
        ColorEntry(name: NSLocalizedString("COLOR_WHITE", comment:""), color: UIColor.whiteColor()),
        ColorEntry(name: NSLocalizedString("COLOR_RED", comment:""), color: UIColor.redColor()),
        ColorEntry(name: NSLocalizedString("COLOR_GREEN", comment:""), color: UIColor.greenColor()),
        ColorEntry(name: NSLocalizedString("COLOR_BLUE", comment:""), color: UIColor.blueColor()),
        ColorEntry(name: NSLocalizedString("COLOR_CYAN", comment:""), color: UIColor.cyanColor()),
        ColorEntry(name: NSLocalizedString("COLOR_YELLOW", comment:""), color: UIColor.yellowColor()),
        ColorEntry(name: NSLocalizedString("COLOR_MAGENTA", comment:""), color: UIColor.magentaColor()),
        ColorEntry(name: NSLocalizedString("COLOR_ORANGE", comment:""), color: UIColor.orangeColor()),
        ColorEntry(name: NSLocalizedString("COLOR_PURPLE", comment:""), color: UIColor.purpleColor()),
        ColorEntry(name: NSLocalizedString("COLOR_BROWN", comment:""), color: UIColor.brownColor()),
    ]
    
    private var selectedIndex = 0

    //-----------------------------------------------------------------------------------------
    // MARK: - 画面オープン・クローズ
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func closeThisView(sender: UIBarButtonItem?) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Identity登録
    //-----------------------------------------------------------------------------------------
    var identity : ColorPickerIdentity = ColorPickerIdentity() {
        didSet {
            navigationItem.title = identity.title
            let src = identity.color
            var srcRed : CGFloat = 0
            var srcGreen : CGFloat = 0
            var srcBlue : CGFloat = 0
            var srcAlpha : CGFloat = 0
            src.getRed(&srcRed, green: &srcGreen , blue: &srcBlue, alpha: &srcAlpha)
            for var i = 0; i < colorList.count; i = i + 1 {
                let dest = colorList[i].color
                var destRed : CGFloat = 0
                var destGreen : CGFloat = 0
                var destBlue : CGFloat = 0
                var destAlpha : CGFloat = 0
                dest.getRed(&destRed, green: &destGreen, blue: &destBlue, alpha: &destAlpha)
                if srcRed == destRed && srcGreen == destGreen && srcBlue == destBlue && srcAlpha == destAlpha {
                    selectedIndex = i
                    break
                }
            }
            tableView.reloadData()
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table View データソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NamedColorCell", forIndexPath: indexPath) as! NamedColorCell

        cell.colorNameLabel.text = colorList[indexPath.row].name
        cell.color = colorList[indexPath.row].color
        if indexPath.row == selectedIndex {
            cell.accessoryType = .Checkmark
        }else{
            cell.accessoryType = .None
        }

        return cell
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - セル選択状態変更
    //-----------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let oldCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedIndex, inSection: 0))
        let newCell = tableView.cellForRowAtIndexPath(indexPath)
        selectedIndex = indexPath.row
        oldCell!.accessoryType = .None
        newCell!.accessoryType = .Checkmark
        identity.changeNotifier?(colorList[selectedIndex].color)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
