//
//  ExifViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit

class ExifViewController: UITableViewController, DVRemoteClientDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let client = DVRemoteClient.sharedClient()
        client.addClientDelegate(self)
        
        let meta = client.meta
        if meta != nil {
            dvrClient(client, didRecieveMeta: meta)
        }
        
        //tableView.tableFooterView = UIView();

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    deinit{
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
    }
    
    private var exifData : [ImageMetadataKV]! = nil
    private var gpsData : [ImageMetadataKV]! = nil
    private var sectionCount = 0;
    private var rowCount = 0;
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        exifData = meta[DVRCNMETA_SUMMARY] as! [ImageMetadataKV]
        gpsData = meta[DVRCNMETA_GPS_SUMMARY] as! [ImageMetadataKV]
        sectionCount = 1
        rowCount = exifData.count + (gpsData.count > 0 ? gpsData.count + 1 : 0)
        tableView.reloadData()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビューのデータソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowCount
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ExifEntry", forIndexPath: indexPath) as! LabelArrangableCell
        var entry : ImageMetadataKV? = nil
        if indexPath.row < exifData.count {
            entry = exifData[indexPath.row]
        }else if indexPath.row > exifData.count {
            entry = gpsData[indexPath.row - exifData.count - 1]
        }
        if entry != nil {
            cell.textLabel!.text = entry!.key
            cell.detailTextLabel!.text = entry!.value
            cell.textLabelWidth = firstFieldWidth(cell)
        }else{
            cell.textLabel!.text = ""
            cell.detailTextLabel!.text = ""
        }

        return cell
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 一列目のサイズ算出
    //-----------------------------------------------------------------------------------------
    private var calculatedFirstFieldWidth : Double? = nil
    
    private func firstFieldWidth(cell : UITableViewCell) -> Double {
        if let width = calculatedFirstFieldWidth {
            return width
        }else{
            let font = cell.textLabel!.font
            let attributes = [NSFontAttributeName : font]
            let meta = DVRemoteClient.sharedClient().templateMeta
            let exif = meta[DVRCNMETA_SUMMARY] as! [ImageMetadataKV]
            let gps = meta[DVRCNMETA_GPS_SUMMARY] as! [ImageMetadataKV]
            var width : Double = 0
            for entry in exif {
                if let key = entry.key {
                    let size = (key as NSString).sizeWithAttributes(attributes)
                    width = max(width, Double(size.width))
                }
            }
            for entry in gps {
                if let key = entry.key {
                    let size = (key as NSString).sizeWithAttributes(attributes)
                    width = max(width, Double(size.width))
                }
            }
            calculatedFirstFieldWidth = width
            return calculatedFirstFieldWidth!
        }
    }
}
