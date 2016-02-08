//
//  PairingViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/29.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class PairingViewController: UIViewController, DVRemoteClientDelegate {

    @IBOutlet weak var hashLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        DVRemoteClient.sharedClient().addClientDelegate(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }
    
    @IBAction func onCancel(sender: AnyObject) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        if state == .Connected {
            onCancel(self)
        }else if state == .Disconnected {
            onCancel(self)
        }
    }
}
