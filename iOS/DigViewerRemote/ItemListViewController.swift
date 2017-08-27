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
    }
    
    deinit {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DVRemoteClient.shared().add(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DVRemoteClient.shared().remove(self)
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
    fileprivate var listRequireing = false
    fileprivate var checkedCell : Int? = nil
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nodeList == nil && document != nil && path != nil && !listRequireing {
            listRequireing = true
            nodeList = DVRemoteClient.shared().nodeList(forID: path, inDocument: document) as NSArray?
            if nodeList != nil {
                let time = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time,execute: {[unowned self]()->Void in
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if nodeList == nil{
            return tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NodeItemCell", for: indexPath) as! NodeItemCell

        let node = nodeList![indexPath.row] as! [String : AnyObject];
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
                cell.accessoryType = .disclosureIndicator
            }else{
                if indexPath.row == checkedCell {
                    cell.accessoryType = .checkmark
                }else{
                    cell.accessoryType = .none
                }
            }
            cell.nodeID = nodeID! as [AnyObject]
            cell.thumbnailView!.image = nil
        }
        if cell.thumbnailView!.image == nil{
            let download = !(tableView.isDragging || tableView.isDecelerating)
            cell.thumbnailView!.image =
                DVRemoteClient.shared().thumbnail(forID: nodeID, inDocument: document!, downloadIfNeed: download)
        }
        
        return cell
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - セルタップ時の動作
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = nodeList![indexPath.row] as! [String : AnyObject];
        let isFolder = (node[DVRCNMETA_ITEM_IS_FOLDER] as? NSNumber)!.boolValue
        var imageID = node[DVRCNMETA_LOCAL_ID] as? String
        if imageID == nil {
            imageID = node[DVRCNMETA_ITEM_NAME] as? String
        }

        selectedNode =  isFolder ?  node[DVRCNMETA_ITEM_NAME] as? String : imageID
        if node[DVRCNMETA_ITEM_IS_FOLDER] as? NSNumber != 0 {
            var newPath = path!
            newPath.append(selectedNode!)
            
            var isCurrentFolder = false
            if let meta = DVRemoteClient.shared().meta {
                let currentDocument = meta[DVRCNMETA_DOCUMENT] as? String
                let currentPath = meta[DVRCNMETA_ID] as? [String]
                if document != nil && document == currentDocument && newPath.count == currentPath!.count - 1 {
                    isCurrentFolder = true
                    for i in 0 ..< newPath.count {
                        if newPath[i] != currentPath![i] {
                            isCurrentFolder = false
                            break
                        }
                    }
                }
            }

            var additionalView : UIViewController? = nil
            let client = DVRemoteClient.shared()
            if (client?.isConnectedToLocal)! && (client?.isAssetCollection(newPath, inDocument: document))!{
                let meta = DVRemoteClient.shared().meta!
                let newView = self.storyboard!.instantiateViewController(withIdentifier: "AssetListViewController") as? AssetListViewController
                newView!.navigationItem.title = selectedNode
                newView!.document = document
                newView!.path = newPath
                newView!.selectedNode = nil
                if isCurrentFolder {
                    newView!.selectedNodeIndex = (meta[DVRCNMETA_INDEX_IN_PARENT] as? NSNumber)! as? Int
                }else{
                    newView!.selectedNodeIndex = nil
                }
                newView!.assets = client?.assets(forID: newPath, inDocument: document) as? PHFetchResult<PHAsset>
                additionalView = newView
            }else{
                let newView = self.storyboard!.instantiateViewController(withIdentifier: "ImageListViewController") as? ItemListViewController
                newView!.navigationItem.title = selectedNode
                newView!.document = document
                newView!.path = newPath
                newView!.selectedNode = nil
                additionalView = newView
            }
            var controllers = navigationController!.viewControllers
            controllers.append(additionalView!)
            navigationController!.setViewControllers(controllers, animated: true)
        }else{
            var nodeID = path
            nodeID!.append(selectedNode!)
            DVRemoteClient.shared().move(toNode: nodeID, inDocument: document)
            let collection = UIApplication.shared.keyWindow!.traitCollection
            if !collection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular)) {
                (navigationController! as? ItemListNavigationController)?.backToMapView()
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ノードリストの更新
    //-----------------------------------------------------------------------------------------
    fileprivate func updateNodeList() {
        if let meta = DVRemoteClient.shared().meta {
            let newDocument = meta[DVRCNMETA_DOCUMENT] as? String
            let newPath = meta[DVRCNMETA_ID] as? [String]
            var isCurrentFolder = false
            if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
                isCurrentFolder = true
                for i in 0 ..< path!.count {
                    if path![i] != newPath![i] {
                        isCurrentFolder = false
                        break
                    }
                }
            }
            if isCurrentFolder {
                let index = (meta[DVRCNMETA_INDEX_IN_PARENT] as? NSNumber)! as? Int
                let indexPath = IndexPath(row: index!, section: 0)
                checkedCell = index
                tableView!.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
                if let cell = tableView!.cellForRow(at: indexPath) {
                    cell.accessoryType = .checkmark
                }
            }else if selectedNode != nil {
                for i in 0 ..< nodeList!.count {
                    let node = nodeList![i] as! [String : AnyObject];
                    let name = node[DVRCNMETA_ITEM_NAME] as? String
                    if name == selectedNode {
                        tableView!.selectRow(
                            at: IndexPath(row: i, section: 0), animated: false, scrollPosition: .middle)
                        break
                    }
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - スクロール停止の判定
    //-----------------------------------------------------------------------------------------
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenRows()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenRows()
    }
    
    fileprivate func loadImagesForOnscreenRows(){
        if nodeList != nil && nodeList!.count > 0 {
            for cell in tableView.visibleCells {
                if (cell as! NodeItemCell).thumbnailView.image == nil {
                    let nodeID = (cell as! NodeItemCell).nodeID
                    (cell as! NodeItemCell).thumbnailView.image =
                        DVRemoteClient.shared().thumbnail(forID: nodeID, inDocument: document!, downloadIfNeed: true)
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    func dvrClient(_ client: DVRemoteClient!, didRecieveNodeList newNodeList: [AnyObject]!, forNode nodeID: [AnyObject]!, inDocument documentName: String!) {
        if document != nil && documentName == document && path!.count == nodeID!.count {
            for i in 0 ..< path!.count {
                if path![i] != (nodeID![i] as! String) {
                    return
                }
            }
            nodeList = newNodeList as! [[String : AnyObject]]? as NSArray?
            tableView.reloadData()
            updateNodeList()
        }
    }
    
    func dvrClient(_ client: DVRemoteClient!, didRecieveMeta meta: [AnyHashable: Any]!) {
        if checkedCell != nil {
            if let cell = tableView!.cellForRow(at: IndexPath(row: checkedCell!, section: 0)) {
                cell.accessoryType = .none
            }
        }
        let newDocument = meta![DVRCNMETA_DOCUMENT] as? String
        let newPath = meta![DVRCNMETA_ID] as? [String]
        if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
            for i in 0 ..< path!.count {
                if path![i] != newPath![i] {
                    return
                }
            }
            let index = meta![DVRCNMETA_INDEX_IN_PARENT] as? NSNumber
            let indexPath = IndexPath(row: (index! as? Int)!, section: 0)
            checkedCell = (index! as? Int)!
            if let cell = tableView!.cellForRow(at: indexPath) {
                cell.accessoryType = .checkmark
            }
            tableView!.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        }
    }

    func dvrClient(_ client: DVRemoteClient!, didRecieveThumbnail thumbnail: UIImage!, ofId nodeId: [AnyObject]!, inDocument documentName: String!, with index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = tableView!.cellForRow(at: indexPath) {
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
    @IBAction func moveToBottom(_ sender: AnyObject) {
        let row = nodeList == nil || nodeList!.count == 0 ? 0 : nodeList!.count - 1
        let path = IndexPath(row: row, section: 0)
        tableView!.scrollToRow(at: path, at: .middle, animated: true)
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
