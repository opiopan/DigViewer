//
//  AssetListViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/11/23.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit

extension UICollectionView {
    func indexPathsForElementsInRect(rect:CGRect)->[NSIndexPath] {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElementsInRect(rect)
        return allLayoutAttributes == nil ? [] : allLayoutAttributes!.map{$0.indexPath}
    }
}

class AssetListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, DVRemoteClientDelegate{
    var document : String? = nil
    var path : [String]? = nil
    var selectedNode : String? = nil
    var selectedNodeIndex : Int? = nil
    var assets : PHFetchResult? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetCachedAssets()
    }
    
    private var is1stTime = true;
    
    override func viewWillAppear(animated: Bool) {
        if assets != nil && selectedNodeIndex != nil && is1stTime{
            is1stTime = false
            let indexPath = NSIndexPath(forRow: selectedNodeIndex!, inSection: 0)
            let collectionView = self.collectionView!
            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredVertically, animated: false)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue()){
                collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredVertically, animated: false)
            }
            DVRemoteClient.sharedClient().addClientDelegate(self)
        }
        updateCachedAssets()
    }
    
    override func viewWillDisappear(animated: Bool) {
        DVRemoteClient.sharedClient().removeClientDelegate(self)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: コレクションビューのデータソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets == nil ? 0 : assets!.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AssetCell", forIndexPath: indexPath) as! AssetCell
    
        if selectedNodeIndex != nil && selectedNodeIndex! == indexPath.row {
            cell.checkMarkView.image = UIImage(named: "checkMark")
        }else{
            cell.checkMarkView.image = nil
        }

        let asset = assets!.objectAtIndex(indexPath.row) as! PHAsset
        let size = approximatelySize * Double(UIScreen.mainScreen().scale)
        let thumbnailSize = CGSize(width: size, height: size)
        //cell.imageView.image = LocalSession.thumbnailForAsset(asset, withSize: CGFloat(size))
        imageManager.requestImageForAsset(asset, targetSize: thumbnailSize, contentMode: .AspectFill, options: nil){
            if let image = $0.0 {
                cell.imageView.image = image
            }
        }
        
        return cell
    }

    //-----------------------------------------------------------------------------------------
    // MARK: 最下行への移動
    //-----------------------------------------------------------------------------------------
    @IBAction func moveToBottom(sender: AnyObject) {
        if assets != nil {
            let indexPath = NSIndexPath(forRow: assets!.count - 1, inSection: 0)
            collectionView!.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: UICollectionViewDelegate
    //-----------------------------------------------------------------------------------------
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        var nodeID = path
        let asset = assets!.objectAtIndex(indexPath.row) as! PHAsset
        nodeID!.append(asset.localIdentifier)
        DVRemoteClient.sharedClient().moveToNode(nodeID, inDocument: document)
        if !traitCollection.containsTraitsInCollection(UITraitCollection(horizontalSizeClass: .Regular)) {
            (navigationController! as? ItemListNavigationController)?.backToMapView()
        }
        
        return true
    }
    
    private let approximatelySize = 78.0
    private let separatorSize = 2.0
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let viewWidth = Double(collectionView.frame.size.width)
        let rowNum = Double(Int(viewWidth / approximatelySize))
        let size = (viewWidth - separatorSize * (rowNum - 1)) / rowNum
        
        return CGSize(width: size, height: size)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: DVRemoteClientDelegate
    //-----------------------------------------------------------------------------------------
    func dvrClient(client: DVRemoteClient!, didRecieveMeta meta: [NSObject : AnyObject]!) {
        if selectedNodeIndex != nil {
            if let cell = collectionView!.cellForItemAtIndexPath(NSIndexPath(forRow: selectedNodeIndex!, inSection: 0)) {
                (cell as! AssetCell).checkMarkView.image = nil
            }
        }
        let newDocument = meta![DVRCNMETA_DOCUMENT] as? String
        let newPath = meta![DVRCNMETA_ID] as? [String]
        if document != nil && path != nil && document == newDocument && path!.count == newPath!.count - 1 {
            for var i = 0; i < path!.count; i++ {
                if path![i] != newPath![i] {
                    return
                }
            }
            selectedNodeIndex = (meta![DVRCNMETA_INDEX_IN_PARENT] as? NSNumber)!.integerValue
            let indexPath = NSIndexPath(forRow: selectedNodeIndex!, inSection: 0)
            if let cell = collectionView!.cellForItemAtIndexPath(indexPath) {
                (cell as! AssetCell).checkMarkView.image = UIImage(named: "checkMark")
            }
            collectionView!.scrollToItemAtIndexPath(indexPath, atScrollPosition:.CenteredVertically , animated: true)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: UIScrollViewDelegate
    //-----------------------------------------------------------------------------------------
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        updateCachedAssets()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - サムネールキャッシュ制御
    //-----------------------------------------------------------------------------------------
    private let imageManager = PHCachingImageManager()
    private var previousPreheatRect = CGRectZero
    
    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRectZero;
    }

    func updateCachedAssets() {
        let isViewVisible = isViewLoaded() && view.window != nil
        if !isViewVisible {
            return
        }
        
        // The preheat window is twice the height of the visible rect.
        var preheatRect = collectionView!.bounds
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect))
        
        /*
        Check if the collection view is showing an area that is significantly
        different to the last preheated area.
        */
        let delta = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(previousPreheatRect))
        if delta > CGRectGetHeight(collectionView!.bounds) / 3.0 {
            
            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths:[NSIndexPath] = []
            var removedIndexPaths:[NSIndexPath] = []
            
            let collectionView = self.collectionView!
            computeDifferenceBetweenRect(previousPreheatRect, newRect: preheatRect, removedHandler: {
                let indexPaths = collectionView.indexPathsForElementsInRect($0)
                removedIndexPaths.appendContentsOf(indexPaths)
            }){
                let indexPaths = collectionView.indexPathsForElementsInRect($0)
                addedIndexPaths.appendContentsOf(indexPaths)
            }
            
            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths)
            
            // Update the assets the PHCachingImageManager is caching.
            let size = approximatelySize * Double(UIScreen.mainScreen().scale)
            let thumbnailSize = CGSize(width: size, height: size)
            imageManager.startCachingImagesForAssets(
                assetsToStartCaching, targetSize:thumbnailSize, contentMode:.AspectFill, options:nil)
            imageManager.stopCachingImagesForAssets(
                assetsToStopCaching, targetSize:thumbnailSize, contentMode:.AspectFill, options:nil)
            
            // Store the preheat rect to compare against in the future.
            previousPreheatRect = preheatRect
        }
    }

    func computeDifferenceBetweenRect(oldRect: CGRect, newRect: CGRect,
        removedHandler:(CGRect)->Void, addedHandler:(CGRect)->Void) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)
            
            if (newMaxY > oldMaxY) {
                let rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            
            if (oldMinY > newMinY) {
                let rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            
            if (newMaxY < oldMaxY) {
                let rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            
            if (oldMinY < newMinY) {
                let rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(indexPaths:[NSIndexPath]) -> [PHAsset]{
        return assets == nil ? [] : indexPaths.map{assets![$0.item] as! PHAsset}
    }
    
}
