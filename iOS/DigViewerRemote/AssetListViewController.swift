//
//  AssetListViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/23.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

extension UICollectionView {
    func indexPathsForElementsInRect(_ rect:CGRect)->[IndexPath] {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElements(in: rect)
        return allLayoutAttributes == nil ? [] : allLayoutAttributes!.map{$0.indexPath}
    }
}

class AssetListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, DVRemoteClientDelegate{
    var document : String? = nil
    var path : [String]? = nil
    var selectedNode : String? = nil
    var selectedNodeIndex : Int? = nil
    var assets : PHFetchResult<PHAsset>? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetCachedAssets()
    }
    
    fileprivate var is1stTime = true;
    
    override func viewWillAppear(_ animated: Bool) {
        if assets != nil && selectedNodeIndex != nil && is1stTime{
            is1stTime = false
            let indexPath = IndexPath(row: selectedNodeIndex!, section: 0)
            let collectionView = self.collectionView!
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)){
                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            }
            DVRemoteClient.shared().add(self)
        }
        updateCachedAssets()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DVRemoteClient.shared().remove(self)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: コレクションビューのデータソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets == nil ? 0 : assets!.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as! AssetCell
    
        if selectedNodeIndex != nil && selectedNodeIndex! == indexPath.row {
            cell.checkMarkView.image = UIImage(named: "checkMark")
        }else{
            cell.checkMarkView.image = nil
        }

        let asset = assets!.object(at: indexPath.row) 
        let size = approximatelySize * Double(UIScreen.main.scale)
        let thumbnailSize = CGSize(width: size, height: size)
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil){
            image, info in
            if let image = image {
                cell.imageView.image = image
            }
        }
        if (asset.mediaSubtypes.rawValue & PHAssetMediaSubtype.photoPanorama.rawValue) != 0 {
            cell.badgeCell.image = UIImage(named: "badge_panorama")
        }else if (asset.mediaSubtypes.rawValue & PHAssetMediaSubtype.photoHDR.rawValue) != 0 {
            cell.badgeCell.image = UIImage(named: "badge_hdr")
        }else if (asset.mediaSubtypes.rawValue & PHAssetMediaSubtype.photoScreenshot.rawValue) != 0 {
            cell.badgeCell.image = UIImage(named: "badge_screenshot")
        }else{
            cell.badgeCell.image = nil
        }
        if #available(iOS 9.1, *) {
            if (asset.mediaSubtypes.rawValue & PHAssetMediaSubtype.photoLive.rawValue) != 0 {
                cell.badgeCell.image = UIImage(named: "badge_live")
            }
        }
    
        return cell
    }

    //-----------------------------------------------------------------------------------------
    // MARK: 最下行への移動
    //-----------------------------------------------------------------------------------------
    @IBAction func moveToBottom(_ sender: AnyObject) {
        if assets != nil {
            let indexPath = IndexPath(row: assets!.count - 1, section: 0)
            collectionView!.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: ハイライト＆選択制御
    //-----------------------------------------------------------------------------------------
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        changeSelecting(indexPath, job: .highlight)
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        changeSelecting(indexPath, job: .unhighlight)
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        changeSelecting(indexPath, job: .select)
        return true
    }
    
    fileprivate enum SelectingPhase {
        case none
        case highlighting
        case highlight
        case unhighlighting
        case unhighlight
    }
    
    fileprivate enum SelectingJob {
        case none
        case highlight
        case unhighlight
        case select
    }
    
    fileprivate var selectingPhase : SelectingPhase = .none
    fileprivate var selectingIndexPath : IndexPath?
    fileprivate var deferringJob : SelectingJob = .none
    fileprivate let highlightPeriod = 0.2
    
    fileprivate func changeSelecting(_ indexPath : IndexPath,  job : SelectingJob) {
        if selectingIndexPath != nil && selectingIndexPath! != indexPath {
            if let cell = collectionView!.cellForItem(at: selectingIndexPath!) as! AssetCell? {
                cell.imageView.alpha = 1.0
            }
            selectingIndexPath = nil
            selectingPhase = .none
            deferringJob = .none
        }
      
        selectingIndexPath = indexPath
        
        if job == .highlight {
            selectingPhase = .highlighting
            deferringJob = .none
            if let cell = collectionView!.cellForItem(at: indexPath) as! AssetCell? {
                UIView.animate(withDuration: highlightPeriod, animations: {
                    cell.imageView.alpha = 0.5
                }, completion: {
                    [unowned self] (Bool) in
                    if self.selectingIndexPath != nil && self.selectingIndexPath! == indexPath {
                        self.selectingPhase = .highlight
                        if self.deferringJob != .none {
                            self.changeSelecting(self.selectingIndexPath!, job: self.deferringJob)
                        }
                    }
                })
            }
        }else if job == .unhighlight {
            if selectingPhase == .highlight {
                selectingPhase = .unhighlighting
                if let cell = collectionView!.cellForItem(at: indexPath) as! AssetCell? {
                    UIView.animate(withDuration: highlightPeriod, animations: {
                        cell.imageView.alpha = 1.0
                    }, completion: {
                        [unowned self] (Bool) in
                        if self.selectingIndexPath != nil && self.selectingIndexPath! == indexPath {
                            self.selectingPhase = .unhighlight
                            if self.deferringJob != .none {
                                self.changeSelecting(self.selectingIndexPath!, job: self.deferringJob)
                            }
                        }
                    })
                }
                
            }else if selectingPhase == .highlighting {
                deferringJob = job
            }
        }else if job == .select {
            var nodeID = path
            let asset = assets!.object(at: indexPath.row) 
            nodeID!.append(asset.localIdentifier)
            DVRemoteClient.shared().move(toNode: nodeID, inDocument: document)
            if selectingPhase == .highlighting || selectingPhase == .unhighlighting {
                deferringJob = job
            }else{
                let condition = UITraitCollection(horizontalSizeClass: .regular)
                let isiPad = UIApplication.shared.keyWindow!.traitCollection.containsTraits(in: condition)
                if !isiPad {
                    (navigationController! as? ItemListNavigationController)?.backToMapView()
                }else if selectingPhase == .highlight {
                    changeSelecting(indexPath, job: .unhighlight)
                }
            }
            
        }
    }
    
    fileprivate let approximatelySize = 78.0
    fileprivate let separatorSize = 1.0
    
    
    //-----------------------------------------------------------------------------------------
    // MARK: レイアウト
    //-----------------------------------------------------------------------------------------
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewWidth = Double(collectionView.frame.size.width)
        let rowNum = Double(Int(viewWidth / approximatelySize))
        let size = (viewWidth - separatorSize * (rowNum - 1)) / rowNum
        
        return CGSize(width: size, height: size)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: DVRemoteClientDelegate
    //-----------------------------------------------------------------------------------------
    func dvrClient(_ client: DVRemoteClient!, didRecieveMeta meta: [AnyHashable: Any]!) {
        if selectedNodeIndex != nil {
            if let cell = collectionView!.cellForItem(at: IndexPath(row: selectedNodeIndex!, section: 0)) {
                (cell as! AssetCell).checkMarkView.image = nil
            }
        }
        let newDocument = meta![DVRCNMETA_DOCUMENT] as? String
        let newPath = meta![DVRCNMETA_ID] as? [String]
        if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
            for i in 0 ..< path!.count {
                if path![i] != newPath![i] {
                    return
                }
            }
            selectedNodeIndex = (meta![DVRCNMETA_INDEX_IN_PARENT] as? NSNumber)!.intValue
            let indexPath = IndexPath(row: selectedNodeIndex!, section: 0)
            if let cell = collectionView!.cellForItem(at: indexPath) {
                (cell as! AssetCell).checkMarkView.image = UIImage(named: "checkMark")
            }
            collectionView!.scrollToItem(at: indexPath, at:.centeredVertically , animated: true)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: UIScrollViewDelegate
    //-----------------------------------------------------------------------------------------
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - サムネールキャッシュ制御
    //-----------------------------------------------------------------------------------------
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var previousPreheatRect = CGRect.zero
    
    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRect.zero;
    }

    func updateCachedAssets() {
        let isViewVisible = isViewLoaded && view.window != nil
        if !isViewVisible {
            return
        }
        
        // The preheat window is twice the height of the visible rect.
        var preheatRect = collectionView!.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        /*
        Check if the collection view is showing an area that is significantly
        different to the last preheated area.
        */
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > collectionView!.bounds.height / 3.0 {
            
            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths:[IndexPath] = []
            var removedIndexPaths:[IndexPath] = []
            
            let collectionView = self.collectionView!
            computeDifferenceBetweenRect(previousPreheatRect, newRect: preheatRect, removedHandler: {
                let indexPaths = collectionView.indexPathsForElementsInRect($0)
                removedIndexPaths.append(contentsOf: indexPaths)
            }){
                let indexPaths = collectionView.indexPathsForElementsInRect($0)
                addedIndexPaths.append(contentsOf: indexPaths)
            }
            
            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths)
            
            // Update the assets the PHCachingImageManager is caching.
            let size = approximatelySize * Double(UIScreen.main.scale)
            let thumbnailSize = CGSize(width: size, height: size)
            imageManager.startCachingImages(
                for: assetsToStartCaching, targetSize:thumbnailSize, contentMode:.aspectFill, options:nil)
            imageManager.stopCachingImages(
                for: assetsToStopCaching, targetSize:thumbnailSize, contentMode:.aspectFill, options:nil)
            
            // Store the preheat rect to compare against in the future.
            previousPreheatRect = preheatRect
        }
    }

    func computeDifferenceBetweenRect(_ oldRect: CGRect, newRect: CGRect,
        removedHandler:(CGRect)->Void, addedHandler:(CGRect)->Void) {
        if newRect.intersects(oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            
            if (newMaxY > oldMaxY) {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            
            if (oldMinY > newMinY) {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            
            if (newMaxY < oldMaxY) {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            
            if (oldMinY < newMinY) {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(_ indexPaths:[IndexPath]) -> [PHAsset]{
        return assets == nil ? [] : indexPaths.map{assets![$0.item] }
    }
    
}
