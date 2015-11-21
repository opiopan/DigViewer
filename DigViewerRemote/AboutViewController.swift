//
//  AboutViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/22.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    
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

}
