//
//  InformationViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/10.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit
import DVremoteCommonUI

protocol InformationViewChild {
    func setInformationViewController(_ controller : InfomationViewController)
}

class InfomationViewController: UIViewController {
    @IBOutlet var segmentedControll : UISegmentedControl?;
    @IBOutlet var placeholder : UIView?;
    var currentViewController : UIViewController?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControll!.selectedSegmentIndex = ConfigurationController.sharedController.informationViewType

        let time = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {[unowned self]() -> Void in
            let controller = self.viewControllerForSegmentIndex(self.segmentedControll!.selectedSegmentIndex)
            if let newController = controller{
                let frame = self.placeholder!.bounds
                self.addChildViewController(newController)
                newController.view.frame = frame
                self.placeholder!.addSubview(newController.view)
                self.currentViewController = newController;
            }
        })
    }
    
    deinit {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController!.setNavigationBarHidden(false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController!.setNavigationBarHidden(true, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - コンテントビュー切り替え
    //-----------------------------------------------------------------------------------------
    func viewControllerForSegmentIndex(_ index:Int) -> UIViewController?{
        ConfigurationController.sharedController.informationViewType = index
        let viewIdentifiers = ["ExifViewController", "ImageListNavigator"]
        if let storyboard = self.storyboard{
            let controller = storyboard.instantiateViewController(withIdentifier: viewIdentifiers[index]) as UIViewController?
            (controller as! InformationViewChild).setInformationViewController(self)
            return controller
        }
        return nil
    }
    
    @IBAction func segmentChange(_ sender:UISegmentedControl){
        let options = [UIViewAnimationOptions.transitionFlipFromRight, UIViewAnimationOptions.transitionFlipFromLeft]
        let controller = viewControllerForSegmentIndex(sender.selectedSegmentIndex)
        if let newController = controller{
            self.addChildViewController(newController);
            self.transition(
                from: currentViewController!, to: newController, duration: 0.5,
                options: options[sender.selectedSegmentIndex],
                animations: {[unowned self]() -> Void  in
                    self.currentViewController!.view .removeFromSuperview()
                    newController.view.frame = self.placeholder!.bounds
                    self.placeholder?.addSubview(newController.view)
                },
                completion: {[unowned self](result : Bool) -> Void in
                    newController.didMove(toParentViewController: self)
                    self.currentViewController!.removeFromParentViewController()
                    self.currentViewController = newController
                }
            )
        }
    }
}
