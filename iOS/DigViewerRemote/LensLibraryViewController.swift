//
//  LensLibraryViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2016/02/21.
//  Copyright © 2016年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonLib
import DVremoteCommonUI

class LensLibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var syncSourceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    //-----------------------------------------------------------------------------------------
    // MARK: - 画面オープン・クローズ
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        updateDataSource()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func closeThisView(sender: UIBarButtonItem?) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビューのデータソース
    //-----------------------------------------------------------------------------------------
    private var lensProfiles : [Lens]? = nil
    
    private func updateDataSource() {
        let syncSource = ConfigurationController.sharedController.lensLibrarySource
        syncSourceLabel.text = syncSource == nil ? NSLocalizedString("LL_NOSOURCE", comment: ""): syncSource
        lensProfiles = (LensLibrary.sharedLensLibrary().allLensProfiles as! [Lens]?)!.sort(){
            $0.name.caseInsensitiveCompare($1.name) == NSComparisonResult.OrderedAscending
        }
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return ConfigurationController.sharedController.lensLibrarySource == nil ? 0 : 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("LL_PROFILE_TITLE", comment: "")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lensProfiles!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LensProfileCell", forIndexPath: indexPath)
        
        let lens = lensProfiles![indexPath.row];
        cell.textLabel!.text = lens.name
        cell.detailTextLabel!.text = lens.lensSpecString
        
        return cell
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ライブラリリセット
    //-----------------------------------------------------------------------------------------
    @IBAction func resetLensLibrary(sender: AnyObject) {
        let alert = UIAlertController(
            title: NSLocalizedString("LL_RESET_TITLE", comment: ""),
            message: NSLocalizedString("LL_RESET_MESSAGE", comment: ""),
            preferredStyle: .Alert)
        let okAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .Default){
            [unowned self] action in
            LensLibrary.resetLensLibrary()
            let controller = ConfigurationController.sharedController
            controller.lensLibrarySource = nil
            controller.lensLibraryDate = 0
            self.updateDataSource()
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }

}
