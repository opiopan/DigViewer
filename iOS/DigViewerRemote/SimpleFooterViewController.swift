//
//  SimpleFooterViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/10.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

class SimpleFooterViewController: UIViewController {
    @IBOutlet weak var textLabel: UILabel!

    @IBAction func openWebSite(_ sender: UIButton) {
        if let url = URL(string: "https://opiopan.github.io/DigViewer/"){
            UIApplication.shared.open(url)
        }
    }
}
