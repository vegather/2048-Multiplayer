//
//  CreateUserViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 04/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class CreateUserViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var createUserLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UITextField!
    @IBOutlet weak var firstPasswordLabel: UITextField!
    @IBOutlet weak var secondPasswordLabel: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var underDoneButtonConstraint: NSLayoutConstraint!
    
    var initialUnderDoneButtonConstraintConstant: CGFloat!
    
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userNameLabel.delegate = self
        firstPasswordLabel.delegate = self
        secondPasswordLabel.delegate = self
        spinner.hidden = true
        
        // We certainly do NOT want a user to be logged in at this point
        ServerManager.logout()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("keyboardWillShow:"),
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("keyboardWillHide:"),
            name: UIKeyboardWillHideNotification,
            object: nil)
        
        initialUnderDoneButtonConstraintConstant = underDoneButtonConstraint.constant
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    
    
    
    // -------------------------------
    // MARK: Text Field Delegate
    // -------------------------------
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Keyboard Animation Handling
    // -------------------------------
    
    private let DONE_BUTTON_MIN_DISTANCE_FROM_KEYBOARD:  CGFloat = 16
    
    // Need to be public unfortunately
    func keyboardWillShow(notification: NSNotification) {
        // Would prefer to do this with UIKeyboardAnimationCurveUserInfoKey, but can't get it working
        var animationCurve = UIViewAnimationCurve.EaseInOut
        NSNumber(integer: 7).getValue(&animationCurve)
        let durationOfAnimation = (notification.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as NSNumber).doubleValue
        let keyboardEndFrame = (notification.userInfo!["UIKeyboardFrameEndUserInfoKey"] as NSValue).CGRectValue()
        
        let doneButtonBottom = doneButton.frame.origin.y + doneButton.frame.size.height
        let keyboardTopWithSpace = keyboardEndFrame.origin.y - DONE_BUTTON_MIN_DISTANCE_FROM_KEYBOARD
        let distanceToMoveButton = doneButtonBottom - keyboardTopWithSpace
        
        if distanceToMoveButton > 0 {
            // Should move
            underDoneButtonConstraint.constant += (distanceToMoveButton * underDoneButtonConstraint.multiplier)
            view.setNeedsUpdateConstraints()
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(durationOfAnimation)
            UIView.setAnimationCurve(animationCurve)
            UIView.setAnimationBeginsFromCurrentState(true)
            view.layoutIfNeeded()
            UIView.commitAnimations()
        }
    }
    
    // Need to be public unfortunately
    func keyboardWillHide(notification: NSNotification) {
        // Would prefer to do this with UIKeyboardAnimationCurveUserInfoKey, but can't get it working
        var animationCurve = UIViewAnimationCurve.EaseInOut
        NSNumber(integer: 7).getValue(&animationCurve)
        
        let durationOfAnimation = (notification.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as NSNumber).doubleValue
        
        underDoneButtonConstraint.constant = initialUnderDoneButtonConstraintConstant
        view.setNeedsUpdateConstraints()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(durationOfAnimation)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Logging in
    // -------------------------------
    
    private func createUser() {
        userNameLabel.resignFirstResponder()
        firstPasswordLabel.resignFirstResponder()
        secondPasswordLabel.resignFirstResponder()
        
        if countElements(userNameLabel.text) > 0 &&
           countElements(firstPasswordLabel.text) > 0 &&
           countElements(secondPasswordLabel.text) > 0
        {
            if firstPasswordLabel.text == secondPasswordLabel.text {
                // Create user
                spinner.hidden = false
                spinner.startAnimating()
                
                MWLog("Will ask ServerManager to create user")
                
                ServerManager.createUserWithEmail(userNameLabel.text, password: firstPasswordLabel.text, profilePicture: nil, completionHandler: { (errorMessage: String?) -> () in
                    self.spinner.stopAnimating()
                    if let error = errorMessage {
                        // Got error
                        self.showAlertWithTitle("Could not create user", andMessage: error)
                    } else {
                        // Success
                        self.performSegueWithIdentifier(SegueIdentifier.PushMainMenuFromCreateUser, sender: self)
                    }
                })
            } else {
                // Non-matching password fields
                showAlertWithTitle("Passwords not matching", andMessage: "The two passwords you entered should match. They don't right now.")
            }
        } else {
            // Show error
            showAlertWithTitle("Empty fields", andMessage: "You need to fill in all the fields to create a user")
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == SegueIdentifier.PopFromCreateUser {
            return true
        } else if identifier == SegueIdentifier.PushMainMenuFromCreateUser {
            if ServerManager.isLoggedIn {
                return true
            } else {
                createUser()
            }
        }
        
        // Otherwise
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        userNameLabel.resignFirstResponder()
        firstPasswordLabel.resignFirstResponder()
        secondPasswordLabel.resignFirstResponder()
        
        if segue.identifier == SegueIdentifier.PopFromCreateUser {
            // Prepare logout
            MWLog("Will exit Create user")
        } else if segue.identifier == SegueIdentifier.PushMainMenuFromCreateUser {
            
        }
    }

    
    
    
    
    // -------------------------------
    // MARK: Show error alert
    // -------------------------------
    
    private func showAlertWithTitle(title: String, andMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let doneAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(doneAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
