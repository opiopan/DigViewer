//
//  ItemSelectorViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/25.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class ItemSelectorIdentity {
    var title : String!
    var description : String!
    var items : [String]?
    var selectionIndex : Int = -1
    var changeNotifier : ((ItemSelectorIdentity, Int) -> (Void))? = nil
    
    init(){
        items = []
    }
}

class ItemSelectorViewController: UITableViewController {

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
    var identity : ItemSelectorIdentity = ItemSelectorIdentity() {
        didSet {
            navigationItem.title = identity.title
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
        return identity.items == nil ? 0 : identity.items!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemSelectorCell", for: indexPath)

        cell.textLabel!.text = identity.items![indexPath.row]
        cell.accessoryType = indexPath.row == identity.selectionIndex ? .checkmark : .none

        return cell
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - セル選択状態変更
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldCell = tableView.cellForRow(at: IndexPath(row: identity.selectionIndex, section: 0))
        let newCell = tableView.cellForRow(at: indexPath)
        identity.selectionIndex = indexPath.row
        oldCell!.accessoryType = .none
        newCell!.accessoryType = .checkmark
        identity.changeNotifier?(identity, indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
