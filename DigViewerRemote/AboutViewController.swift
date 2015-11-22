//
//  AboutViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/22.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var cautionLabel: UILabel!
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 画面オープン・クローズ
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let infoPlist =  NSBundle.mainBundle().infoDictionary

        let version = infoPlist!["CFBundleShortVersionString"] as! String
        let build = infoPlist!["OPBuildVersion"] as! String
        versionLabel.text = "Version \(version) (\(build))"
        
        let cautions = infoPlist!["OPCaution"] as! [String]
        if cautions.count > 0 {
            let cautionString = cautions.enumerate().reduce(""){
                var separator = ", "
                if $1.index == 0 {
                    separator = ""
                }else if $1.index == cautions.count - 1 {
                    separator = ", and "
                }
                return $0 + separator + $1.element
            }
            cautionLabel.text = "Caution:\nThis is NOT OFFICIAL BUILD which is \(cautionString)."
        }else{
            cautionLabel.text = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func closeThisView(sender: UIBarButtonItem?) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

}
