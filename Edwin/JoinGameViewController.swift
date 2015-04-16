//
//  JoinGameViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 06/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class JoinGameViewController: UIViewController {

    @IBOutlet weak var gamePinTextField: UITextField!
    @IBOutlet weak var underJoinGameButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var joinButton: UIButton!
    
    var initialUnderJoinGameButtonConstraintConstant: CGFloat!
    var gameServer = GameServerManager()
    var gameSetup: GameSetup<TileValue>?
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
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
        
        initialUnderJoinGameButtonConstraintConstant = underJoinGameButtonConstraint.constant
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    
    
    
    
    // -------------------------------
    // MARK: Keyboard Animation Handling
    // -------------------------------
    
    private let JOIN_GAME_BUTTON_MIN_DISTANCE_FROM_KEYBOARD:  CGFloat = 16
    
    // Need to be public unfortunately
    func keyboardWillShow(notification: NSNotification) {
        // Would prefer to do this with UIKeyboardAnimationCurveUserInfoKey, but can't get it working
        var animationCurve = UIViewAnimationCurve.EaseInOut
        NSNumber(integer: 7).getValue(&animationCurve)
        let durationOfAnimation = (notification.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber).doubleValue
        let keyboardEndFrame = (notification.userInfo!["UIKeyboardFrameEndUserInfoKey"] as! NSValue).CGRectValue()
        
        let joinGameButtonBottom = joinButton.frame.origin.y + joinButton.frame.size.height
        let keyboardTopWithSpace = keyboardEndFrame.origin.y - JOIN_GAME_BUTTON_MIN_DISTANCE_FROM_KEYBOARD
        let distanceToMoveButton = joinGameButtonBottom - keyboardTopWithSpace
        
        if distanceToMoveButton > 0 {
            // Should move
            underJoinGameButtonConstraint.constant += (distanceToMoveButton * underJoinGameButtonConstraint.multiplier)
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
        
        let durationOfAnimation = (notification.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber).doubleValue
        
        underJoinGameButtonConstraint.constant = initialUnderJoinGameButtonConstraintConstant
        view.setNeedsUpdateConstraints()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(durationOfAnimation)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }

    
    
    
    // -------------------------------
    // MARK: Actions
    // -------------------------------
    
    @IBAction func joinGameButtonTapped() {
        dismissKeyboard()
        
        if let gamePin = enteredGamepin() {
            self.gameServer.joinGameWithGamepin(gamePin,
                completionHandler:
                { (dimension: Int!, turnDuration: Int!, errorMessage: String?) -> () in
                    if let errorMessage = errorMessage {
                        self.showAlertWithTitle("Alert while joining game", andMessage: errorMessage)
                    } else {
                        // Move to the game
                        
                    }
                })
        } else {
            showAlertWithTitle("No gamepin", andMessage: "You need to enter the gamepin that is showing on your opponents screen.")
        }
    }
    
    private func enteredGamepin() -> String? {
        if count(gamePinTextField.text) > 0 {
            return gamePinTextField.text
        } else {
            return nil
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Keyboard Dismissal
    // -------------------------------
    
    private func dismissKeyboard() {
        gamePinTextField.resignFirstResponder()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        dismissKeyboard()
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Show error alert
    // -------------------------------
    
    private func showAlertWithTitle(title: String, andMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let doneAction = UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(doneAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
