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
            self.performSegue(withIdentifier: "FullImageView", sender: self)
        }
        
        let client = DVRemoteClient.shared()
        
        let meta = client?.meta
        if meta != nil {
            dvrClient(client, didRecieveMeta: meta)
        }
        let thumbnail = client?.thumbnail
        if meta != nil {
            dvrClient(client, didRecieveCurrentThumbnail: thumbnail)
        }

        DVRemoteClient.shared().add(self)
    }
    
    deinit{
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let client = DVRemoteClient.shared()
        client?.add(self)
        if client?.meta != nil {
            dvrClient(client, didRecieveMeta: client?.meta)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DVRemoteClient.shared().remove(self)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - InformationViewChildプロトコル
    //-----------------------------------------------------------------------------------------
    fileprivate var informationViewController : InfomationViewController?
    func setInformationViewController(_ controller: InfomationViewController) {
        informationViewController = controller
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(_ client: DVRemoteClient!, change state: DVRClientState) {
    }

    func dvrClient(_ client: DVRemoteClient!, didRecieveMeta meta: [AnyHashable: Any]!) {
        self.thumbnail = DVRemoteClient.shared().thumbnail
        self.meta = meta
    }
    
    func dvrClient(_ client: DVRemoteClient!, didRecieveCurrentThumbnail thumbnail: UIImage!) {
        self.thumbnail = thumbnail
    }

}
