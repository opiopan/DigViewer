//
//  ExifViewControllerBase.swift
//  DigViewerRemote
//
//  Created by opiopan on 2016/1/1.
//  Copyright (c) 2016年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonLib

public class ExifViewControllerBase: UITableViewController {
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit{
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override public func viewWillAppear(animated: Bool) {
    }
    
    override public func viewWillDisappear(animated: Bool) {
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - プロパティ設定
    //-----------------------------------------------------------------------------------------
    private var exifData : [ImageMetadataKV]! = nil
    private var gpsData : [ImageMetadataKV]! = nil
    private var sectionNames : [String] = [];
    private var sectionData : [[ImageMetadataKV]] = [];
    
    public var meta : [NSObject : AnyObject]! {
        didSet {
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
    }
    
    public var thumbnail : UIImage! {
        didSet {
            let index = NSIndexPath.init(forRow: 0, inSection: 0)
            if let cell = tableView!.cellForRowAtIndexPath(index) {
                if (cell as! InspectorImageCell).thumbnailView.image == nil {
                    (cell as! InspectorImageCell).thumbnailView.image = thumbnail
                    tableView.reloadData()
                }
            }
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビューのデータソース
    //-----------------------------------------------------------------------------------------
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionNames.count
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData[section].count
    }

    private static var cellForEstimate : LabelArrangableCell?
    private static var cellForEstimateSize : CGSize!
    private static var valueTextAttributes : [String : AnyObject]!
    private static var valueTextHeight = CGFloat(0)
    
    override public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            var rc = CGFloat(150)
            if let image = thumbnail {
                let ratio = image.size.height / image.size.width
                rc *= max(1.0, ratio)
                if rc / ratio > view.bounds.width {
                    rc = view.bounds.width * ratio
                }
            }
            return  rc + 8
        }else{
            if ExifViewControllerBase.cellForEstimate == nil {
                ExifViewControllerBase.cellForEstimate =
                    tableView.dequeueReusableCellWithIdentifier("ExifEntry") as? LabelArrangableCell
                setupCell(ExifViewControllerBase.cellForEstimate!, indexPath: indexPath)
                ExifViewControllerBase.cellForEstimate!.contentView.setNeedsLayout()
                ExifViewControllerBase.cellForEstimate!.contentView.layoutIfNeeded()
                let font = ExifViewControllerBase.cellForEstimate!.subTextLabel!.font
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
                ExifViewControllerBase.valueTextAttributes = [
                    NSFontAttributeName : font,
                    NSParagraphStyleAttributeName : paragraphStyle
                ]
                ExifViewControllerBase.valueTextHeight = ExifViewControllerBase.cellForEstimate!.subTextLabel.bounds.size.height
                ExifViewControllerBase.cellForEstimateSize =
                    ExifViewControllerBase.cellForEstimate!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            }
            
            setupCell(ExifViewControllerBase.cellForEstimate!, indexPath: indexPath)
            let text = ExifViewControllerBase.cellForEstimate!.subTextLabel.text
            let screenBounds = tableView.bounds
            let labelFrame = ExifViewControllerBase.cellForEstimate!.subTextLabel.frame
            let labelSize = CGSize(width: screenBounds.size.width - labelFrame.origin.x, height: labelFrame.size.height)
            var newLabelSize = labelSize
            if text != nil {
                newLabelSize.height = 1000
                let rect = (text! as NSString).boundingRectWithSize(
                    newLabelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                    attributes: ExifViewControllerBase.valueTextAttributes, context: nil)
                newLabelSize = rect.size
            }
            
            var size = ExifViewControllerBase.cellForEstimateSize
            if size.height < newLabelSize.height {
                size.height += (newLabelSize.height - labelSize.height)
            }
            
            return size.height + 1
        }
    }

    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionNames[section]
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 && indexPath.row == 0 ?
                   tableView.dequeueReusableCellWithIdentifier("ImageCell", forIndexPath: indexPath) :
                   tableView.dequeueReusableCellWithIdentifier("ExifEntry", forIndexPath: indexPath)

        setupCell(cell, indexPath: indexPath)
    
        return cell
    }
    
    private func setupCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let entry : ImageMetadataKV? = (sectionData[indexPath.section])[indexPath.row]
        if indexPath.section == 0 && indexPath.row == 0 {
            let imageCell = cell as! InspectorImageCell
            imageCell.thumbnailView!.image = thumbnail
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
    
    public var imageSelector : ((UIImageView) -> Void)? = nil

    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 && imageSelector != nil{
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                imageSelector!((cell as! InspectorImageCell).thumbnailView!)
            }
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
            var width : Double = 0
            if let exif = meta[DVRCNMETA_SUMMARY] as! [ImageMetadataKV]? {
                for entry in exif {
                    if let key = entry.key {
                        let size = (key as NSString).sizeWithAttributes(attributes)
                        width = max(width, Double(size.width))
                    }
                }
            }
            if let gps = meta[DVRCNMETA_GPS_SUMMARY] as! [ImageMetadataKV]? {
                for entry in gps {
                    if let key = entry.key {
                        let size = (key as NSString).sizeWithAttributes(attributes)
                        width = max(width, Double(size.width))
                    }
                }
            }
            calculatedFirstFieldWidth = width + 1
            return calculatedFirstFieldWidth!
        }
    }
}
