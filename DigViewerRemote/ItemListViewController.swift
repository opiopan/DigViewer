//
//  ItemListViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/26.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class ItemListViewController: UITableViewController, DVRemoteClientDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        DVRemoteClient.sharedClient().addClientDelegate(self)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    deinit {
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table view data source
    //-----------------------------------------------------------------------------------------
    var document : String? = nil
    var path : [String]? = nil
    var selectedNode : String? = nil
    var nodeList : [[String : AnyObject]]? = nil
    var thumbnailList : [UIImage] = []
    private var listRequireing = false
    private var checkedCell : Int? = nil
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return document != nil && path != nil ? 1 : 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nodeList == nil && document != nil && path != nil && !listRequireing {
            listRequireing = true
            nodeList = DVRemoteClient.sharedClient().nodeListForID(path, inDocument: document) as! [[String: AnyObject]]?
        }
        if nodeList != nil {
            let time = dispatch_time(DISPATCH_TIME_NOW, 0)
            dispatch_after(time, dispatch_get_main_queue() ,{[unowned self]()->Void in
                self.updateNodeList()
            })
            return nodeList!.count
        }else{
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NodeItemCell", forIndexPath: indexPath) as! NodeItemCell

        let node = nodeList![indexPath.row];
        let name = node[DVRCNMETA_ITEM_NAME] as? String
        cell.mainLabel.text = name
        cell.subLabel.text = node[DVRCNMETA_ITEM_TYPE] as? String
        if node[DVRCNMETA_ITEM_IS_FOLDER] as? NSNumber != 0 {
            cell.accessoryType = .DisclosureIndicator
        }else{
            if indexPath.row == checkedCell {
                cell.accessoryType = .Checkmark
            }else{
                cell.accessoryType = .None
            }
        }
        var nodeID = path
        nodeID!.append(name!)
        cell.thumbnailView!.image = DVRemoteClient.sharedClient().thumbnailForID(nodeID, inDocument: document!)
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodeList![indexPath.row];
        selectedNode = node[DVRCNMETA_ITEM_NAME] as? String
        if node[DVRCNMETA_ITEM_IS_FOLDER] as? NSNumber != 0 {
            let newView = self.storyboard!.instantiateViewControllerWithIdentifier("ImageListViewController") as? ItemListViewController
            newView!.navigationItem.title = selectedNode
            newView!.document = document
            newView!.path = path
            newView!.path!.append(selectedNode!)
            newView!.selectedNode = nil
            var controllers = navigationController!.viewControllers
            controllers.append(newView!)
            navigationController!.setViewControllers(controllers, animated: true)
        }else{
            var nodeID = path
            nodeID!.append(((nodeList![indexPath.row])[DVRCNMETA_ITEM_NAME] as? String)!)
            DVRemoteClient.sharedClient().moveToNode(nodeID, inDocument: document)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ノードリストの更新
    //-----------------------------------------------------------------------------------------
    private func updateNodeList() {
        for var i = 0; i < nodeList!.count; i++ {
            let node = nodeList![i];
            let name = node[DVRCNMETA_ITEM_NAME] as? String
            if selectedNode != nil && name == selectedNode {
                tableView!.selectRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: false, scrollPosition: .Middle)
            }
        }
        if let meta = DVRemoteClient.sharedClient().meta {
            let newDocument = meta[DVRCNMETA_DOCUMENT] as? String
            let newPath = meta[DVRCNMETA_ID] as? [String]
            if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
                for var i = 0; i < path!.count; i++ {
                    if path![i] != newPath![i] {
                        return
                    }
                }
                let index = (meta[DVRCNMETA_INDEX_IN_PARENT] as? NSNumber)! as Int
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                checkedCell = index
                if let cell = tableView!.cellForRowAtIndexPath(indexPath) {
                    cell.accessoryType = .Checkmark
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, didRecieveNodeList newNodeList: [AnyObject]!, forNode nodeID: [AnyObject]!, inDocument documentName: String!) {
        if document != nil && documentName == document && path!.count == nodeID!.count {
            for var i = 0; i < path!.count; i++ {
                if path![i] != (nodeID![i] as! String) {
                    return
                }
            }
            nodeList = newNodeList as! [[String : AnyObject]]?
            tableView.reloadData()
        }
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        if checkedCell != nil {
            if let cell = tableView!.cellForRowAtIndexPath(NSIndexPath(forRow: checkedCell!, inSection: 0)) {
                cell.accessoryType = .None
            }
        }
        let newDocument = meta![DVRCNMETA_DOCUMENT] as? String
        let newPath = meta![DVRCNMETA_ID] as? [String]
        if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
            for var i = 0; i < path!.count; i++ {
                if path![i] != newPath![i] {
                    return
                }
            }
            let index = meta![DVRCNMETA_INDEX_IN_PARENT] as? NSNumber
            let indexPath = NSIndexPath(forRow: index! as Int, inSection: 0)
            checkedCell = index! as Int
            if let cell = tableView!.cellForRowAtIndexPath(indexPath) {
                cell.accessoryType = .Checkmark
            }
            tableView!.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
        }
    }

    func dvrClient(client: DVRemoteClient!, didRecieveThumbnail thumbnail: UIImage!, ofId nodeId: [AnyObject]!, inDocument documentName: String!, withIndex index: Int) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        if let cell = tableView!.cellForRowAtIndexPath(indexPath) {
            let itemCell = cell as! NodeItemCell
            if itemCell.thumbnailView!.image == nil {
                itemCell.thumbnailView.image = thumbnail
            }else{
                //NSLog("image exist:\(nodeId.last)")
            }
        }else{
            //NSLog("no cell:\(nodeId.last)")
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
