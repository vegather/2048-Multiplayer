//
//  PopSegue.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 04/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

// Note that this segue will result in duplicate call to viewWillAppear and viewDidAppear
// viewDidLoad is just called once as normal though
class PopSegue: UIStoryboardSegue {
    override func perform() {
        // Assign the source and destination views to local variables.
        let secondVCView = sourceViewController     .view
        let firstVCView  = destinationViewController.view
        
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(firstVCView, aboveSubview: secondVCView)
        
        
        // Animate the transition.
        UIView.animateWithDuration(
            0.4,
            animations: {
                firstVCView.frame  = CGRectOffset(firstVCView.frame,  screenWidth, 0.0)
                secondVCView.frame = CGRectOffset(secondVCView.frame, screenWidth, 0.0)
            },
            completion: { _ in
                self.dismissViewControllersFrom(
                    self.sourceViewController,
                    allTheWayDownTo: self.destinationViewController,
                    animated: false
                )
            }
        )
    }
    
    // Recursively dismisses all the VCs downto to.
    private func dismissViewControllersFrom(from: UIViewController, allTheWayDownTo to: UIViewController, animated: Bool) {
        if from != to {
            if let presentingVC = from.presentingViewController {
                presentingVC.dismissViewControllerAnimated(animated) {
                    self.dismissViewControllersFrom(presentingVC, allTheWayDownTo: to, animated: animated)
                }
            }
        }
    }
}
