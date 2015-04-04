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
    
    let DONE_BUTTON_MIN_DISTANCE_FROM_KEYBOARD:  CGFloat = 16
//    let TEXT_FIELD_MIN_DISTANCE_FROM_EDWIN_LABEL: CGFloat = 20
    
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
//            let movedTopOfUsernameFieldWithSpace = self.usernameTextField.frame.origin.y - distanceToMoveButton - TEXT_FIELD_MIN_DISTANCE_FROM_EDWIN_LABEL
//            let bottomOfEdwinLabel = edwinLabel.frame.origin.y + edwinLabel.frame.size.height
//            let edwinLabelShouldMoveIfPositive = bottomOfEdwinLabel - movedTopOfUsernameFieldWithSpace
//            
//            if edwinLabelShouldMoveIfPositive > 0 {
//                let newMiddleOfEdwinLabel = movedTopOfUsernameFieldWithSpace / 2.0
//                let newOverEdwinLabelConstraintConstant = newMiddleOfEdwinLabel - (edwinLabel.frame.size.height / 2.0)
//                overEdwinLabelConstraint.constant = newOverEdwinLabelConstraintConstant
//            }
            
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
    
    func keyboardWillHide(notification: NSNotification) {
        // Would prefer to do this with UIKeyboardAnimationCurveUserInfoKey, but can't get it working
        var animationCurve = UIViewAnimationCurve.EaseInOut
        NSNumber(integer: 7).getValue(&animationCurve)
        
        let durationOfAnimation = (notification.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as NSNumber).doubleValue
        
        underDoneButtonConstraint.constant = initialUnderDoneButtonConstraintConstant
//        overEdwinLabelConstraint.constant = initialOverEdwinLabelConstraintConstant
        view.setNeedsUpdateConstraints()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(durationOfAnimation)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        userNameLabel.resignFirstResponder()
        firstPasswordLabel.resignFirstResponder()
        secondPasswordLabel.resignFirstResponder()
        
        if segue.identifier == SegueIdentifier.PopFromCreateUser {
            // Prepare logout
            MWLog("Will exit Create user")
        }
    }

}
