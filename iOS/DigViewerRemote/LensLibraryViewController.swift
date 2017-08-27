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
    
    @IBAction func closeThisView(_ sender: UIBarButtonItem?) {
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビューのデータソース
    //-----------------------------------------------------------------------------------------
    fileprivate var lensProfiles : [Lens]? = nil
    
    fileprivate func updateDataSource() {
        let syncSource = ConfigurationController.sharedController.lensLibrarySource
        syncSourceLabel.text = syncSource == nil ? NSLocalizedString("LL_NOSOURCE", comment: ""): syncSource
        lensProfiles = (LensLibrary.shared().allLensProfiles as! [Lens]?)!.sorted(){
            $0.name.caseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending
        }
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return ConfigurationController.sharedController.lensLibrarySource == nil ? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("LL_PROFILE_TITLE", comment: "")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lensProfiles!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LensProfileCell", for: indexPath)
        
        let lens = lensProfiles![indexPath.row];
        cell.textLabel!.text = lens.name
        cell.detailTextLabel!.text = lens.lensSpecString
        
        return cell
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - ライブラリリセット
    //-----------------------------------------------------------------------------------------
    @IBAction func resetLensLibrary(_ sender: AnyObject) {
        let alert = UIAlertController(
            title: NSLocalizedString("LL_RESET_TITLE", comment: ""),
            message: NSLocalizedString("LL_RESET_MESSAGE", comment: ""),
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default){
            [unowned self] action in
            LensLibrary.resetLensLibrary()
            let controller = ConfigurationController.sharedController
            controller.lensLibrarySource = nil
            controller.lensLibraryDate = 0
            self.updateDataSource()
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }

}
