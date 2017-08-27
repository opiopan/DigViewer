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
    
    override func viewWillAppear(_ animated: Bool) {
        DVRemoteClient.shared().add(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DVRemoteClient.shared().remove(self)
    }
    
    @IBAction func onCancel(_ sender: AnyObject) {
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    func dvrClient(_ client: DVRemoteClient!, change state: DVRClientState) {
        if state == .connected {
            onCancel(self)
        }else if state == .disconnected {
            onCancel(self)
        }
    }
}
