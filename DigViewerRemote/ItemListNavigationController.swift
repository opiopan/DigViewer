//
//  ItemListNavigationController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/26.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class ItemListNavigationController: UINavigationController, DVRemoteClientDelegate, InformationViewChild {

    override func viewDidLoad() {
        super.viewDidLoad()

        arrangeSubviewsInAccordanceWithCurrentNode(false)
    }
    
    deinit{
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
    // MARK: - InformationViewChildプロトコル
    //-----------------------------------------------------------------------------------------
    private var informationViewController : InfomationViewController?
    func setInformationViewController(controller: InfomationViewController) {
        informationViewController = controller
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - カレントノードに合わせたビュー階層構築
    //-----------------------------------------------------------------------------------------
    private var document : String? = nil;
    
    private func arrangeSubviewsInAccordanceWithCurrentNode(animated : Bool){
        if let meta = DVRemoteClient.sharedClient().meta {
            let newDocument = meta[DVRCNMETA_DOCUMENT] as! String
            let path = meta[DVRCNMETA_ID] as! [String]
            var views: [UIViewController] = []
            var currentPath: [String] = []
            if document != nil && document == newDocument {
                for var i = 0; i < path.count - 1; i++ {
                    if i < viewControllers.count && viewControllers[i].navigationItem.title == path[i] {
                        currentPath.append(path[i])
                        views.append(viewControllers[i])
                    }else{
                        break;
                    }
                }
            }
            if (views.count > 0){
                (views.last as? ItemListViewController)?.selectedNode = path[views.count]
            }
            
            for var i = views.count; i < path.count - 1; i++ {
                currentPath.append(path[i])
                let view = self.storyboard!.instantiateViewControllerWithIdentifier("ImageListViewController") as? ItemListViewController
                view!.navigationItem.title = path[i]
                view!.document = newDocument
                view!.path = currentPath
                view!.selectedNode = path[i + 1]
                if i == path.count - 1 {
                    view!.selectedNodeIndex = meta[DVRCNMETA_INDEX_IN_PARENT] as? Int
                }else{
                    view!.selectedNodeIndex = nil
                }
                views.append(view!)
            }
            //(views.last! as! ItemListViewController).tableView!.reloadData()
            document = newDocument
            setViewControllers(views, animated: animated)
        }else{
            document = nil
            viewControllers = []
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコルの実装
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        var needRearrange = false
        let newDocument = meta![DVRCNMETA_DOCUMENT] as? String
        let newPath = meta![DVRCNMETA_ID] as? [String]
        let lastController = viewControllers.last as! ItemListViewController?
        let path = lastController != nil ? lastController!.path : nil
        if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
            for var i = 0; i < path!.count; i++ {
                if path![i] != newPath![i] {
                    needRearrange = true
                    break
                }
            }
            
        }else{
            needRearrange = true
        }
        
        if needRearrange{
            arrangeSubviewsInAccordanceWithCurrentNode(true)
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

    func backToMapView (){
        if let controller = self.informationViewController!.navigationController!.navigationController {
            controller.popViewControllerAnimated(true)
        }
    }
}
