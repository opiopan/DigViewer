//
//  ExifViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI

class ExifViewController: ExifViewControllerBase, DVRemoteClientDelegate, InformationViewChild {

    override func viewDidLoad() {
        super.viewDidLoad()

        super.imageSelector = {
            [unowned self] (imageView) in
            self.performSegueWithIdentifier("FullImageView", sender: self)
        }
        
        let client = DVRemoteClient.sharedClient()
        
        let meta = client.meta
        if meta != nil {
            dvrClient(client, didRecieveMeta: meta)
        }
        let thumbnail = client.thumbnail
        if meta != nil {
            dvrClient(client, didRecieveCurrentThumbnail: thumbnail)
        }

        DVRemoteClient.sharedClient().addClientDelegate(self)
    }
    
    deinit{
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        let client = DVRemoteClient.sharedClient()
        client.addClientDelegate(self)
        if client.meta != nil {
            dvrClient(client, didRecieveMeta: client.meta)
        }
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
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
    }

    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        self.thumbnail = DVRemoteClient.sharedClient().thumbnail
        self.meta = meta
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveCurrentThumbnail thumbnail: UIImage!) {
        self.thumbnail = thumbnail
    }

}
