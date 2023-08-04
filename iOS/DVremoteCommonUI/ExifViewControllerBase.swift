//
//  ExifViewControllerBase.swift
//  DigViewerRemote
//
//  Created by opiopan on 2016/1/1.
//  Copyright (c) 2016年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonLib

open class ExifViewControllerBase: UITableViewController {
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit{
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override open func viewWillAppear(_ animated: Bool) {
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - プロパティ設定
    //-----------------------------------------------------------------------------------------
    fileprivate var exifData : [ImageMetadataKV]! = nil
    fileprivate var gpsData : [ImageMetadataKV]! = nil
    fileprivate var sectionNames : [String] = [];
    fileprivate var sectionData : [[ImageMetadataKV]] = [];
    
    open var meta : [AnyHashable: Any]! {
        didSet {
            exifData = meta[DVRCNMETA_SUMMARY] as? [ImageMetadataKV]
            if let tmp = meta[DVRCNMETA_GPS_SUMMARY]{
                gpsData = tmp as? [ImageMetadataKV]
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
    
    open var thumbnail : UIImage! {
        didSet {
            let index = IndexPath.init(row: 0, section: 0)
            if let cell = tableView!.cellForRow(at: index) {
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
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return sectionNames.count
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData[section].count
    }

    fileprivate static var cellForEstimate : LabelArrangableCell?
    fileprivate static var cellForEstimateSize : CGSize!
    fileprivate static var valueTextAttributes : [NSAttributedString.Key : AnyObject]!
    fileprivate static var valueTextHeight = CGFloat(0)
    
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
                    tableView.dequeueReusableCell(withIdentifier: "ExifEntry") as? LabelArrangableCell
                setupCell(ExifViewControllerBase.cellForEstimate!, indexPath: indexPath)
                ExifViewControllerBase.cellForEstimate!.contentView.setNeedsLayout()
                ExifViewControllerBase.cellForEstimate!.contentView.layoutIfNeeded()
                let font = ExifViewControllerBase.cellForEstimate!.subTextLabel!.font
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
                ExifViewControllerBase.valueTextAttributes = [
                    NSAttributedString.Key.font : font!,
                    NSAttributedString.Key.paragraphStyle : paragraphStyle
                ]
                ExifViewControllerBase.valueTextHeight = ExifViewControllerBase.cellForEstimate!.subTextLabel.bounds.size.height
                ExifViewControllerBase.cellForEstimateSize =
                ExifViewControllerBase.cellForEstimate!.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            }
            
            setupCell(ExifViewControllerBase.cellForEstimate!, indexPath: indexPath)
            let text = ExifViewControllerBase.cellForEstimate!.subTextLabel.text
            let screenBounds = tableView.bounds
            let labelFrame = ExifViewControllerBase.cellForEstimate!.subTextLabel.frame
            let labelSize = CGSize(width: screenBounds.size.width - labelFrame.origin.x, height: labelFrame.size.height)
            var newLabelSize = labelSize
            if text != nil {
                newLabelSize.height = 1000
                let rect = (text! as NSString).boundingRect(
                    with: newLabelSize, options: NSStringDrawingOptions.usesLineFragmentOrigin,
                    attributes: ExifViewControllerBase.valueTextAttributes, context: nil)
                newLabelSize = rect.size
            }
            
            var size = ExifViewControllerBase.cellForEstimateSize
            if (size?.height)! < newLabelSize.height {
                size?.height += (newLabelSize.height - labelSize.height)
            }
            
            return size!.height + 1
        }
    }

    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionNames[section]
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 && indexPath.row == 0 ?
                   tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) :
                   tableView.dequeueReusableCell(withIdentifier: "ExifEntry", for: indexPath)

        setupCell(cell, indexPath: indexPath)
    
        return cell
    }
    
    fileprivate func setupCell(_ cell: UITableViewCell, indexPath: IndexPath) {
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
    
    open var imageSelector : ((UIImageView) -> Void)? = nil

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && imageSelector != nil{
            if let cell = tableView.cellForRow(at: indexPath) {
                imageSelector!((cell as! InspectorImageCell).thumbnailView!)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - 一列目のサイズ算出
    //-----------------------------------------------------------------------------------------
    fileprivate var calculatedFirstFieldWidth : Double? = nil
    
    fileprivate func firstFieldWidth(_ cell : UITableViewCell) -> Double {
        if let width = calculatedFirstFieldWidth {
            return width
        }else{
            let font = (cell as! LabelArrangableCell).mainLabel!.font
            let attributes = [NSAttributedString.Key.font : font!]
            var width : Double = 0
            if let exif = meta[DVRCNMETA_SUMMARY] as! [ImageMetadataKV]? {
                for entry in exif {
                    if let key = entry.key {
                        let size = (key as NSString).size(withAttributes: attributes)
                        width = max(width, Double(size.width))
                    }
                }
            }
            if let gps = meta[DVRCNMETA_GPS_SUMMARY] as! [ImageMetadataKV]? {
                for entry in gps {
                    if let key = entry.key {
                        let size = (key as NSString).size(withAttributes: attributes)
                        width = max(width, Double(size.width))
                    }
                }
            }
            calculatedFirstFieldWidth = width + 1
            return calculatedFirstFieldWidth!
        }
    }
}
