//
//  DataSourceDetailViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/15.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class DataSourceDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var cpuLabel: UILabel!
    @IBOutlet weak var memoryLabel: UILabel!
    @IBOutlet weak var dvVersionLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func closeServersView(sender : UIBarButtonItem?){
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    var serverInfo : ServerInfo? {
        didSet {
            if let info = serverInfo {
                var bounds = self.view.bounds
                bounds.origin.x += 50
                
                navigationItem.title = info.service.name
                imageView.image = info.image
                modelNameLabel.text = info.attributes[DVRCNMETA_MACHINE_NAME]
                
                serverLabel.text = nil
                userLabel.text = nil
                cpuLabel.text = nil
                memoryLabel.text = nil
                
                let components = info.service.name.componentsSeparatedByString("@")
                if components.count > 0 {
                    userLabel.text = NSLocalizedString("DSD_USER", comment: "") + components[0]
                }
                if components.count > 1 {
                    serverLabel.text = NSLocalizedString("DSD_SERVER", comment: "") + components[1]
                }
                if let cpu = info.attributes[DVRCNMETA_CPU] {
                    cpuLabel.text = NSLocalizedString("DSD_PROCESSOR", comment: "") + cpu
                }
                if let memory = info.attributes[DVRCNMETA_MEMORY_SIZE] {
                    memoryLabel.text = NSLocalizedString("DSD_MEMORY", comment: "") + memory
                }
                if let version = info.attributes[DVRCNMETA_DV_VERSION] {
                    dvVersionLabel.text = NSLocalizedString("DSD_DIGVIEWER", comment: "") + version
                }
                
                descriptionLabel.text = info.attributes[DVRCNMETA_DESCRIPTION]
            }
        }
    }
}
