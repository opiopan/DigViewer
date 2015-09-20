//
//  InformationViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/10.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit

class InfomationViewController: UIViewController {
    @IBOutlet var segmentedControll : UISegmentedControl?;
    @IBOutlet var placeholder : UIView?;
    var currentViewController : UIViewController?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let controller = self.viewControllerForSegmentIndex(self.segmentedControll!.selectedSegmentIndex)
        if let newController = controller{
            self.addChildViewController(newController)
            newController.view.frame = placeholder!.bounds;
            placeholder!.addSubview(newController.view)
            currentViewController = newController;
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //-----------------------------------------------------------------------------------------
    // コンテントビュー切り替え
    //-----------------------------------------------------------------------------------------
    // MARK: Changing content view
    func viewControllerForSegmentIndex(index:Int) -> UIViewController?{
        let viewIdentifiers = ["ExifViewController", "ImageListViewController"]
        if let storyboard = self.storyboard{
            return storyboard.instantiateViewControllerWithIdentifier(viewIdentifiers[index]) as UIViewController?
        }
        return nil
    }
    
    @IBAction func segmentChange(sender:UISegmentedControl){
//        let options = [UIViewAnimationOptions.TransitionFlipFromLeft, UIViewAnimationOptions.TransitionFlipFromRight]
        let controller = viewControllerForSegmentIndex(sender.selectedSegmentIndex)
        if let newController = controller{
            self.addChildViewController(newController);
            currentViewController!.view.removeFromSuperview()
            newController.view.frame = self.placeholder!.bounds
            self.placeholder!.addSubview(newController.view)
            currentViewController!.removeFromParentViewController()
            self.currentViewController = newController
//            self.transitionFromViewController(
//                currentViewController!, toViewController: newController, duration: 0.5,
//                options: options[sender.selectedSegmentIndex],
//                animations: {[unowned self]() -> Void  in
//                    self.currentViewController!.view .removeFromSuperview()
//                    newController.view.frame = self.placeholder!.bounds
//                    self.placeholder?.addSubview(newController.view)
//                },
//                completion: {[unowned self](result : Bool) -> Void in
//                    newController.didMoveToParentViewController(self)
//                    self.currentViewController!.removeFromParentViewController()
//                    self.currentViewController = newController
//                }
//            )
        }
    }
}
