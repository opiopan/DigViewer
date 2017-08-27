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
    fileprivate struct ColorEntry {
        var name : String
        var color : UIColor
        init(name : String, color : UIColor){
            self.name = name
            self.color = color
        }
    }
    
    fileprivate let colorList : [ColorEntry] = [
        ColorEntry(name: NSLocalizedString("COLOR_BLACK", comment:""), color: UIColor.black),
        ColorEntry(name: NSLocalizedString("COLOR_WHITE", comment:""), color: UIColor.white),
        ColorEntry(name: NSLocalizedString("COLOR_RED", comment:""), color: UIColor.red),
        ColorEntry(name: NSLocalizedString("COLOR_GREEN", comment:""), color: UIColor.green),
        ColorEntry(name: NSLocalizedString("COLOR_BLUE", comment:""), color: UIColor.blue),
        ColorEntry(name: NSLocalizedString("COLOR_CYAN", comment:""), color: UIColor.cyan),
        ColorEntry(name: NSLocalizedString("COLOR_YELLOW", comment:""), color: UIColor.yellow),
        ColorEntry(name: NSLocalizedString("COLOR_MAGENTA", comment:""), color: UIColor.magenta),
        ColorEntry(name: NSLocalizedString("COLOR_ORANGE", comment:""), color: UIColor.orange),
        ColorEntry(name: NSLocalizedString("COLOR_PURPLE", comment:""), color: UIColor.purple),
        ColorEntry(name: NSLocalizedString("COLOR_BROWN", comment:""), color: UIColor.brown),
    ]
    
    fileprivate var selectedIndex = 0

    //-----------------------------------------------------------------------------------------
    // MARK: - 画面オープン・クローズ
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func closeThisView(_ sender: UIBarButtonItem?) {
        self.presentingViewController!.dismiss(animated: true, completion: nil)
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
            src?.getRed(&srcRed, green: &srcGreen , blue: &srcBlue, alpha: &srcAlpha)
            for i in 0 ..< colorList.count {
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NamedColorCell", for: indexPath) as! NamedColorCell

        cell.colorNameLabel.text = colorList[indexPath.row].name
        cell.color = colorList[indexPath.row].color
        if indexPath.row == selectedIndex {
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }

        return cell
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - セル選択状態変更
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldCell = tableView.cellForRow(at: IndexPath(row: selectedIndex, section: 0))
        let newCell = tableView.cellForRow(at: indexPath)
        selectedIndex = indexPath.row
        oldCell!.accessoryType = .none
        newCell!.accessoryType = .checkmark
        identity.changeNotifier?(colorList[selectedIndex].color)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
