//
//  ExifViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit

class ExifViewController: UITableViewController, DVRemoteClientDelegate, InformationViewChild {

    override func viewDidLoad() {
        super.viewDidLoad()

        let client = DVRemoteClient.sharedClient()
        
        let meta = client.meta
        if meta != nil {
            dvrClient(client, didRecieveMeta: meta)
        }

        DVRemoteClient.sharedClient().addClientDelegate(self)
        
        //tableView.tableFooterView = UIView();

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    deinit{
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
    
    //-----------------------------------------------------------------------------------------
    // MARK: - InformationViewChildプロトコル
    //-----------------------------------------------------------------------------------------
    private var informationViewController : InfomationViewController?
    func setInformationViewController(controller: InfomationViewController) {
        informationViewController = controller
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - DVRemoteClientDelegateプロトコル
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
    }
    
    private var exifData : [ImageMetadataKV]! = nil
    private var gpsData : [ImageMetadataKV]! = nil
    private var sectionNames : [String] = [];
    private var sectionData : [[ImageMetadataKV]] = [];
    
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        exifData = meta[DVRCNMETA_SUMMARY] as! [ImageMetadataKV]
        if let tmp = meta[DVRCNMETA_GPS_SUMMARY]{
            gpsData = tmp as! [ImageMetadataKV]
        }else{
            gpsData = nil
        }
        
        sectionNames = [NSLocalizedString("EXIF-BASIC", comment:"")];
        sectionData = [[]];
        for entry in exifData {
            if entry.key == nil {
                sectionNames.append(entry.remark)
                sectionData.append([])
            }else{
                var data = sectionData.last
                data!.append(entry)
                sectionData[sectionData.count - 1] = data!
            }
        }
        if gpsData != nil{
            sectionNames.append(NSLocalizedString("EXIF-LOCATION", comment:""))
            sectionData.append([])
            for entry in gpsData {
                var data = sectionData.last
                data!.append(entry)
                sectionData[sectionData.count - 1] = data!
            }
        }
        tableView.reloadData()
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveCurrentThumbnail thumbnail: UIImage!) {
        let index = NSIndexPath.init(forRow: 0, inSection: 0)
        if let cell = tableView!.cellForRowAtIndexPath(index) {
            if (cell as! InspectorImageCell).thumbnailView.image == nil {
                (cell as! InspectorImageCell).thumbnailView.image = thumbnail
                tableView.reloadData()
            }
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビューのデータソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionNames.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let data = sectionData[section]
        return section == 0 ? data.count - 1 : data.count
    }

    private static var cellForEstimate : LabelArrangableCell?
    private static var cellForEstimateSize : CGSize!
    private static var valueTextAttributes : [String : AnyObject]!
    private static var valueTextHeight = CGFloat(0)
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            var rc = CGFloat(152)
            if let image = DVRemoteClient.sharedClient().thumbnail {
                var ratio = image.size.height / image.size.width
                ratio = min(1.0, ratio)
                ratio = max(0.3, ratio)
                rc *= ratio
            }
            return  rc + 8
        }else{
            if ExifViewController.cellForEstimate == nil {
                ExifViewController.cellForEstimate =
                    tableView.dequeueReusableCellWithIdentifier("ExifEntry") as? LabelArrangableCell
                setupCell(ExifViewController.cellForEstimate!, indexPath: indexPath)
                ExifViewController.cellForEstimate!.contentView.setNeedsLayout()
                ExifViewController.cellForEstimate!.contentView.layoutIfNeeded()
                let font = ExifViewController.cellForEstimate!.subTextLabel!.font
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
                ExifViewController.valueTextAttributes = [
                    NSFontAttributeName : font,
                    NSParagraphStyleAttributeName : paragraphStyle
                ]
                ExifViewController.valueTextHeight = ExifViewController.cellForEstimate!.subTextLabel.bounds.size.height
                ExifViewController.cellForEstimateSize =
                    ExifViewController.cellForEstimate!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            }
            
            setupCell(ExifViewController.cellForEstimate!, indexPath: indexPath)
            let text = ExifViewController.cellForEstimate!.subTextLabel.text
            let screenBounds = tableView.bounds
            let labelFrame = ExifViewController.cellForEstimate!.subTextLabel.frame
            let labelSize = CGSize(width: screenBounds.size.width - labelFrame.origin.x, height: labelFrame.size.height)
            var newLabelSize = labelSize
            if text != nil {
                newLabelSize.height = 1000
                let rect = (text! as NSString).boundingRectWithSize(
                    newLabelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                    attributes: ExifViewController.valueTextAttributes, context: nil)
                newLabelSize = rect.size
            }
            
            var size = ExifViewController.cellForEstimateSize
            if size.height < newLabelSize.height {
                size.height += (newLabelSize.height - labelSize.height)
            }
            
            return size.height + 1
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionNames[section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 && indexPath.row == 0 ?
                   tableView.dequeueReusableCellWithIdentifier("ImageCell", forIndexPath: indexPath) :
                   tableView.dequeueReusableCellWithIdentifier("ExifEntry", forIndexPath: indexPath)

        setupCell(cell, indexPath: indexPath)
    
        return cell
    }
    
    private func setupCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        var entry : ImageMetadataKV? = nil
        if indexPath.section == 0 && indexPath.row == 0 {
            entry = exifData[0]
        }else if indexPath.section == 0 {
            entry = exifData[indexPath.row + 1]
        }else{
            entry = (sectionData[indexPath.section])[indexPath.row]
        }
        if indexPath.section == 0 && indexPath.row == 0 {
            let imageCell = cell as! InspectorImageCell
            let entry2 = exifData[1]
            imageCell.mainLabel!.text = entry!.value
            imageCell.subLabel!.text = entry2.value
            imageCell.thumbnailView!.image = DVRemoteClient.sharedClient().thumbnail
        }else{
            if entry != nil {
                let exifCell = cell as! LabelArrangableCell
                exifCell.mainLabel!.text = entry!.key
                exifCell.subTextLabel!.text = entry!.value
                exifCell.textLabelWidth = CGFloat(firstFieldWidth(cell))
            }else{
                (cell as! LabelArrangableCell).mainLabel!.text = ""
                (cell as! LabelArrangableCell).subTextLabel!.text = ""
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 0){
            performSegueWithIdentifier("FullImageView", sender: tableView)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 一列目のサイズ算出
    //-----------------------------------------------------------------------------------------
    private var calculatedFirstFieldWidth : Double? = nil
    
    private func firstFieldWidth(cell : UITableViewCell) -> Double {
        if let width = calculatedFirstFieldWidth {
            return width
        }else{
            let font = (cell as! LabelArrangableCell).mainLabel!.font
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
            calculatedFirstFieldWidth = width + 1
            return calculatedFirstFieldWidth!
        }
    }
}
