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

    @IBAction func closeThisView(sender: UIBarButtonItem?) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
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
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return identity.items == nil ? 0 : identity.items!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemSelectorCell", forIndexPath: indexPath)

        cell.textLabel!.text = identity.items![indexPath.row]
        cell.accessoryType = indexPath.row == identity.selectionIndex ? .Checkmark : .None

        return cell
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - セル選択状態変更
    //-----------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let oldCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: identity.selectionIndex, inSection: 0))
        let newCell = tableView.cellForRowAtIndexPath(indexPath)
        identity.selectionIndex = indexPath.row
        oldCell!.accessoryType = .None
        newCell!.accessoryType = .Checkmark
        identity.changeNotifier?(identity, indexPath.row)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
