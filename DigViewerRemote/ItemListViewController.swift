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

        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    deinit {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        DVRemoteClient.sharedClient().addClientDelegate(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビューのデータソース
    //-----------------------------------------------------------------------------------------
    var document : String? = nil
    var path : [String]? = nil
    var selectedNode : String? = nil
    var selectedNodeIndex : Int? = nil
    var nodeList : NSArray? = nil
    var thumbnailList : [UIImage] = []
    private var listRequireing = false
    private var checkedCell : Int? = nil
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nodeList == nil && document != nil && path != nil && !listRequireing {
            listRequireing = true
            nodeList = DVRemoteClient.sharedClient().nodeListForID(path, inDocument: document)
            if nodeList != nil {
                let time = dispatch_time(DISPATCH_TIME_NOW, 0)
                dispatch_after(time, dispatch_get_main_queue() ,{[unowned self]()->Void in
                    self.updateNodeList()
                })
            }
        }
        if nodeList != nil {
            return nodeList!.count
        }else{
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if nodeList == nil{
            return tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("NodeItemCell", forIndexPath: indexPath) as! NodeItemCell

        let node = nodeList![indexPath.row];
        let name = node[DVRCNMETA_ITEM_NAME] as? String
        var localID = node[DVRCNMETA_LOCAL_ID] as? String
        if localID == nil {
             localID = name
        }
        var nodeID = path
        nodeID!.append(localID!)
        if cell.nodeID == nil || cell.nodeID.last as? String != localID {
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
            cell.nodeID = nodeID
            cell.thumbnailView!.image = nil
        }
        if cell.thumbnailView!.image == nil{
            let download = !(tableView.dragging || tableView.decelerating)
            cell.thumbnailView!.image =
                DVRemoteClient.sharedClient().thumbnailForID(nodeID, inDocument: document!, downloadIfNeed: download)
        }
        
        return cell
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - セルタップ時の動作
    //-----------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodeList![indexPath.row];
        let isFolder = (node[DVRCNMETA_ITEM_IS_FOLDER] as? NSNumber)!.boolValue
        var imageID = node[DVRCNMETA_LOCAL_ID] as? String
        if imageID == nil {
            imageID = node[DVRCNMETA_ITEM_NAME] as? String
        }
        selectedNode =  isFolder ?  node[DVRCNMETA_ITEM_NAME] as? String : imageID
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
            nodeID!.append(selectedNode!)
            DVRemoteClient.sharedClient().moveToNode(nodeID, inDocument: document)
            if !traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular)) {
                (navigationController! as? ItemListNavigationController)?.backToMapView()
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ノードリストの更新
    //-----------------------------------------------------------------------------------------
    private func updateNodeList() {
        if let meta = DVRemoteClient.sharedClient().meta {
            let newDocument = meta[DVRCNMETA_DOCUMENT] as? String
            let newPath = meta[DVRCNMETA_ID] as? [String]
            var isCurrentFolder = false
            if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
                isCurrentFolder = true
                for var i = 0; i < path!.count; i++ {
                    if path![i] != newPath![i] {
                        isCurrentFolder = false
                        break
                    }
                }
            }
            if isCurrentFolder {
                let index = (meta[DVRCNMETA_INDEX_IN_PARENT] as? NSNumber)! as Int
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                checkedCell = index
                tableView!.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .Middle)
                if let cell = tableView!.cellForRowAtIndexPath(indexPath) {
                    cell.accessoryType = .Checkmark
                }
            }else if selectedNode != nil {
                for var i = 0; i < nodeList!.count; i++ {
                    let node = nodeList![i];
                    let name = node[DVRCNMETA_ITEM_NAME] as? String
                    if name == selectedNode {
                        tableView!.selectRowAtIndexPath(
                            NSIndexPath(forRow: i, inSection: 0), animated: false, scrollPosition: .Middle)
                        break
                    }
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - スクロール停止の判定
    //-----------------------------------------------------------------------------------------
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenRows()
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        loadImagesForOnscreenRows()
    }
    
    private func loadImagesForOnscreenRows(){
        if nodeList != nil && nodeList!.count > 0 {
            for cell in tableView.visibleCells {
                if (cell as! NodeItemCell).thumbnailView.image == nil {
                    let nodeID = (cell as! NodeItemCell).nodeID
                    (cell as! NodeItemCell).thumbnailView.image =
                        DVRemoteClient.sharedClient().thumbnailForID(nodeID, inDocument: document!, downloadIfNeed: true)
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
            updateNodeList()
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
    // MARK: - ユーザアクション
    //-----------------------------------------------------------------------------------------
    @IBAction func moveToBottom(sender: AnyObject) {
        let row = nodeList == nil || nodeList!.count == 0 ? 0 : nodeList!.count - 1
        let path = NSIndexPath(forRow: row, inSection: 0)
        tableView!.scrollToRowAtIndexPath(path, atScrollPosition: .Middle, animated: true)
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
