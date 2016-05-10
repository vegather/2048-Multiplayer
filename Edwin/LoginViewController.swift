//
//  LoginViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 04/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var underLoginConstraint: NSLayoutConstraint!
    @IBOutlet weak var overEdwinLabelConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createUserButton: UIButton!
    @IBOutlet weak var edwinLabel: UILabel!
    
    @IBOutlet weak var loginAsDemo1Button: UIButton!
    @IBOutlet weak var loginAsDemo2Button: UIButton!
    
    var initialUnderLoginConstraintConstant: CGFloat!
    var initialOverEdwinLabelConstraintConstant: CGFloat!
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        spinner.hidden = true
        
        usernameTextField.text = ""
        passwordTextField.text = ""
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(LoginViewController.keyboardWillShow(_:)),
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(LoginViewController.keyboardWillHide(_:)),
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        initialOverEdwinLabelConstraintConstant = overEdwinLabelConstraint.constant
        initialUnderLoginConstraintConstant = underLoginConstraint.constant
        
        usernameTextField.text = ""
        passwordTextField.text = ""
        
        if UserServerManager.isLoggedIn {
            MOONLog("The user was already logged in, so moving along")
            self.performSegueWithIdentifier(SegueIdentifier.PushMainMenuFromLogin, sender: self)
        } else {
            MOONLog("The user is NOT logged in. Waiting for user to login...")
        }
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
    
    let LOGIN_BUTTON_MIN_DISTANCE_FROM_KEYBOARD:  CGFloat = 16
    let TEXT_FIELD_MIN_DISTANCE_FROM_EDWIN_LABEL: CGFloat = 20
    
    func keyboardWillShow(notification: NSNotification) {
        // Would prefer to do this with UIKeyboardAnimationCurveUserInfoKey, but can't get it working
        var animationCurve = UIViewAnimationCurve.EaseInOut
        NSNumber(integer: 7).getValue(&animationCurve)
        let durationOfAnimation = (notification.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber).doubleValue
        let keyboardEndFrame = (notification.userInfo!["UIKeyboardFrameEndUserInfoKey"] as! NSValue).CGRectValue()
        
        let loginButtonBottom = loginButton.frame.origin.y + loginButton.frame.size.height
        let keyboardTopWithSpace = keyboardEndFrame.origin.y - LOGIN_BUTTON_MIN_DISTANCE_FROM_KEYBOARD
        let distanceToMoveButton = loginButtonBottom - keyboardTopWithSpace
        
//        if distanceToMoveButton > 0 {
            // Should move
            let movedTopOfUsernameFieldWithSpace = self.usernameTextField.frame.origin.y - distanceToMoveButton - TEXT_FIELD_MIN_DISTANCE_FROM_EDWIN_LABEL
            let bottomOfEdwinLabel = edwinLabel.frame.origin.y + edwinLabel.frame.size.height
            let edwinLabelShouldMoveIfPositive = bottomOfEdwinLabel - movedTopOfUsernameFieldWithSpace
            
            if edwinLabelShouldMoveIfPositive > 0 {
                let newMiddleOfEdwinLabel = movedTopOfUsernameFieldWithSpace / 2.0
                let newOverEdwinLabelConstraintConstant = newMiddleOfEdwinLabel - (edwinLabel.frame.size.height / 2.0)
                overEdwinLabelConstraint.constant = newOverEdwinLabelConstraintConstant
            }
            
            underLoginConstraint.constant += (distanceToMoveButton * underLoginConstraint.multiplier)
            view.setNeedsUpdateConstraints()
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(durationOfAnimation)
            UIView.setAnimationCurve(animationCurve)
            UIView.setAnimationBeginsFromCurrentState(true)
            view.layoutIfNeeded()
            UIView.commitAnimations()
//        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Would prefer to do this with UIKeyboardAnimationCurveUserInfoKey, but can't get it working
        var animationCurve = UIViewAnimationCurve.EaseInOut
        NSNumber(integer: 7).getValue(&animationCurve)
        
        let durationOfAnimation = (notification.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber).doubleValue
        
        underLoginConstraint.constant = initialUnderLoginConstraintConstant
        overEdwinLabelConstraint.constant = initialOverEdwinLabelConstraintConstant
        view.setNeedsUpdateConstraints()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(durationOfAnimation)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    
    
    
    // -------------------------------
    // MARK: Login User
    // -------------------------------
    
    private func loginAsRegularUser() {
        if usernameTextField.text!.characters.count > 0 &&
            passwordTextField.text!.characters.count > 0
        {
            loginWithEmail(usernameTextField.text!, password: passwordTextField.text!)
        } else {
            dismissKeyboard()
            showAlertWithTitle("Missing fields", andMessage: "You need to fill in both the email field, and the password to log in")
        }
    }
    
    @IBAction func loginAsDemo1() {
        loginWithEmail("demo1@demo1.com", password: "demo1")
    }
    
    @IBAction func loginAsDemo2() {
        loginWithEmail("demo2@demo2.com", password: "demo2")
    }
    
    private func loginWithEmail(email: String, password: String) {
        dismissKeyboard()
        spinner.hidden = false
        spinner.startAnimating()
        setButtonsEnabled(false)
        
        MOONLog("Will ask serverManager to login user")
        
        UserServerManager.loginWithEmail(email, password: password) { errorMessage  in
            self.spinner.stopAnimating()
            self.setButtonsEnabled(true)
            
            if let error = errorMessage {
                // Got error
                self.showAlertWithTitle("Could not log in", andMessage: error)
            } else {
                // Successfully logged in
                self.performSegueWithIdentifier(SegueIdentifier.PushMainMenuFromLogin, sender: self)
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Custom Segue Management
    // -------------------------------
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == SegueIdentifier.PushMainMenuFromLogin {
            MOONLog("Should perform the PushMainMenu segue")
            
            if UserServerManager.isLoggedIn {
                return true
            } else {
                loginAsRegularUser()
                return false
            }
        } else if identifier == SegueIdentifier.PushCreateUser {
            MOONLog("Should perform the PushCreateUser segue")
            return true
        } else {
            MOONLog("Should NOT perform an unknown segue")
            return false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        dismissKeyboard()
        
        if segue.identifier == SegueIdentifier.PushMainMenuFromLogin {
//            let _ = segue.destinationViewController as! MainMenuViewController
            // Prepare the main menu
            MOONLog("Preparing the Main Menu")
        } else if segue.identifier == SegueIdentifier.PushCreateUser {
//            let _ = segue.destinationViewController as! CreateUserViewController
            // Prepare create user
            MOONLog("Preparing Create User")
        } else {
            MOONLog("Preparing for an unknown segue")
        }
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        
        if let id = identifier{
            if id == SegueIdentifier.PopToLoginFromMainMenu {
                MOONLog("Providing unwind segue for PopToLoginFromMainMenu")
                let unwindSegue = PopSegue(identifier: id,
                    source: fromViewController,
                    destination: toViewController,
                    performHandler: { () -> Void in
                })
                
                return unwindSegue
            }
            else if id == SegueIdentifier.PopToLoginFromCreateUser {
                MOONLog("Providing unwind segue for PopToLoginFromCreateUser")
                let unwindSegue = PopSegue(identifier: id,
                    source: fromViewController,
                    destination: toViewController,
                    performHandler: { () -> Void in
                })
                
                return unwindSegue
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)!
    }
    
    @IBAction func returnToLoginFromSegueAction(sender: UIStoryboardSegue){
        if sender.identifier == SegueIdentifier.PopToLoginFromCreateUser {
            // Came back from create user
            MOONLog("Came back from Create User")
        } else if sender.identifier == SegueIdentifier.PopToLoginFromMainMenu {
            // Came back from main menu
            MOONLog("Came back from Main Menu")
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Keyboard Dismissal
    // -------------------------------
    
    private func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func setButtonsEnabled(value: Bool) {
        usernameTextField .enabled = value
        passwordTextField .enabled = value
        loginButton       .enabled = value
        createUserButton  .enabled = value
        loginAsDemo1Button.enabled = value
        loginAsDemo2Button.enabled = value
    }
    
    private func showAlertWithTitle(title: String, andMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let doneAction = UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(doneAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
