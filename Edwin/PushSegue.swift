//
//  PushSegue.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 04/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

// Note that this segue will result in duplicate call to viewWillAppear and viewDidAppear
// viewDidLoad is just called once as normal though
class PushSegue: UIStoryboardSegue {
    override func perform() {
        // Assign the source and destination views to local variables.
        var firstVCView =  (self.sourceViewController      as UIViewController).view as UIView!
        var secondVCView = (self.destinationViewController as UIViewController).view as UIView!
        
        // Get the screen width and height.
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        // Specify the initial position of the destination view.
        secondVCView.frame = CGRectMake(screenWidth, 0, screenWidth, screenHeight)
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(secondVCView, aboveSubview: firstVCView)
        
        
        // Animate the transition.
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            firstVCView.frame = CGRectOffset(firstVCView.frame, -screenWidth, 0.0)
            secondVCView.frame = CGRectOffset(secondVCView.frame, -screenWidth, 0.0)
            
            }) { (Finished) -> Void in
//                if (self.sourceViewController.presentedViewController != nil) {
//                    self.sourceViewController.dismissViewControllerAnimated(false, completion: nil)
//                }
//                secondVCView.removeFromSuperview()
                
                self.sourceViewController.presentViewController(self.destinationViewController as UIViewController,
                    animated: false,
                    completion: nil)
        }
    }
}
