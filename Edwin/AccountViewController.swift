//
//  AccountViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 20/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
    
    @IBOutlet weak var changeDisplayNameButton: UIButton!
    @IBOutlet weak var changeEmailButton: UIButton!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var backToMainMenuButton: UIButton!

    @IBOutlet weak var numberOfWinsLabel:   UILabel!
    @IBOutlet weak var numberOfLossesLabel: UILabel!
    @IBOutlet weak var numberOfDrawsLabel:  UILabel!
    
    @IBOutlet weak var numberOfWinsSpinner:   UIActivityIndicatorView!
    @IBOutlet weak var numberOfLossesSpinner: UIActivityIndicatorView!
    @IBOutlet weak var numberOfDrawsSpinner:  UIActivityIndicatorView!

    private var viewHasAppeared: Bool = false
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewHasAppeared == false {
            viewHasAppeared = true
            
            numberOfWinsLabel.hidden   = true
            numberOfLossesLabel.hidden = true
            numberOfDrawsLabel.hidden  = true
            
            numberOfWinsSpinner.hidden   = false
            numberOfLossesSpinner.hidden = false
            numberOfDrawsSpinner.hidden  = false
            
            numberOfWinsSpinner.startAnimating()
            numberOfLossesSpinner.startAnimating()
            numberOfDrawsSpinner.startAnimating()
            
            
            // Go fetch statistics data
            
            UserServerManager.getNumberOfWinsStatisticsByIncrementing(false) { (newNumberOfWins: Int) -> () in
                self.numberOfWinsLabel.text = "\(newNumberOfWins)"
                self.numberOfWinsLabel.hidden = false
                self.numberOfWinsSpinner.stopAnimating()
                self.numberOfWinsSpinner.hidden = true
            }
            
            UserServerManager.getNumberOfLossesStatisticsByIncrementing(false) { (newNumberOfLosses: Int) -> () in
                self.numberOfLossesLabel.text = "\(newNumberOfLosses)"
                self.numberOfLossesLabel.hidden = false
                self.numberOfLossesSpinner.stopAnimating()
                self.numberOfLossesSpinner.hidden = true
            }
            
            UserServerManager.getNumberOfDrawsStatisticsByIncrementing(false) { (newNumberOfDraws: Int) -> () in
                self.numberOfDrawsLabel.text = "\(newNumberOfDraws)"
                self.numberOfDrawsLabel.hidden = false
                self.numberOfDrawsSpinner.stopAnimating()
                self.numberOfDrawsSpinner.hidden = true
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Actions
    // -------------------------------
    
    @IBAction func changeDisplayNameButtonTapped() {
        
        let changeDisplayNameAlert = UIAlertController(
            title:          "Change Display Name",
            message:        "Choose your new display name.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        changeDisplayNameAlert.addTextFieldWithConfigurationHandler() { (textField: UITextField!) -> Void in
            textField.font            = UIFont(name: "AvenirNext-Regular", size: 14.0)
            textField.placeholder     = "Pick a Display Name"
            textField.text            = UserServerManager.lastKnownCurrentUserDisplayName
            textField.clearButtonMode = UITextFieldViewMode.WhileEditing
        }
        
        let changeButton = UIAlertAction(
            title: "Change",
            style: UIAlertActionStyle.Default)
            { (alert: UIAlertAction!) -> Void in
                self.disableButtons()
                
                if let textFields = changeDisplayNameAlert.textFields {
                    if textFields.count == 1 {
                        let newDisplayNameTextField = textFields[0] as UITextField
                        let newDisplayName = newDisplayNameTextField.text
                        
                        MOONLog("setting newDisplayName to: \(newDisplayName)")
                        
                        // Call UserServerManager
                        UserServerManager.changeCurrentUsersDisplayNameTo(newDisplayName!) { (errorMessage: String?) -> () in
                            self.enableButtons()
                            if let errorMessage = errorMessage {
                                MOONLog("Error setting displayName to \(newDisplayName)")
                                self.showAlertWithTitle("Could not change Display Name", andMessage: errorMessage)
                            } else {
                                MOONLog("Display got set successfully to \(newDisplayName).")
                            }
                        }
                        
                    } else {
                        MOONLog("ERROR: There is NOT one textField")
                        self.enableButtons()
                    }
                } else {
                    MOONLog("ERROR: No textFields")
                    self.enableButtons()
                }
            }
        
        let cancelButton = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        
        changeDisplayNameAlert.addAction(cancelButton)
        changeDisplayNameAlert.addAction(changeButton)
        
        presentViewController(changeDisplayNameAlert,
            animated:   true,
            completion: nil)
    }
    
    @IBAction func changeEmailButtonTapped() {
        
        let changeEmailNameAlert = UIAlertController(
            title:          "Change Email",
            message:        "Choose your new email.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        var currentUserEmail = ""
        if let mail = UserServerManager.currentUserEmail {
            currentUserEmail = mail
        }
        
        changeEmailNameAlert.addTextFieldWithConfigurationHandler() { (textField: UITextField!) -> Void in
            textField.font            = UIFont(name: "AvenirNext-Regular", size: 14.0)
            textField.placeholder     = "Enter your email"
            textField.text            = currentUserEmail
            textField.clearButtonMode = UITextFieldViewMode.WhileEditing
        }
        
        changeEmailNameAlert.addTextFieldWithConfigurationHandler() { (textField: UITextField!) -> Void in
            textField.font               = UIFont(name: "AvenirNext-Regular", size: 14.0)
            textField.placeholder        = "Enter your password"
            textField.clearButtonMode    = UITextFieldViewMode.WhileEditing
            textField.secureTextEntry    = true
            textField.keyboardAppearance = UIKeyboardAppearance.Dark
        }
        
        let changeButton = UIAlertAction(
            title: "Change",
            style: UIAlertActionStyle.Default)
        { (alert: UIAlertAction!) -> Void in
            self.disableButtons()
            
            if let textFields = changeEmailNameAlert.textFields {
                if textFields.count == 2 {
                    let newEmailTextField = textFields[0] as UITextField
                    let passwordTextField = textFields[1] as UITextField
                    let newEmail = newEmailTextField.text
                    let password = passwordTextField.text
                    
                    MOONLog("Attempting to change email to \(newEmail)")
                    
                    // Call UserServerManager
                    UserServerManager.changeCurrentUsersEmailTo(newEmail!, withPassword: password!)
                    { (errorMessage: String?) -> () in
                        self.enableButtons()
                        if let errorMessage = errorMessage {
                            MOONLog("Error setting email to \(newEmail)")
                            self.showAlertWithTitle("Could not change email", andMessage: errorMessage)
                        } else {
                            self.enableButtons()
                            MOONLog("Email got changed successfully to \(newEmail).")
                        }
                    }
                    
                } else {
                    MOONLog("ERROR: There are NOT two textField")
                    self.enableButtons()
                }
            } else {
                MOONLog("ERROR: No textFields")
                self.enableButtons()
            }
        }
        
        let cancelButton = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        
        changeEmailNameAlert.addAction(cancelButton)
        changeEmailNameAlert.addAction(changeButton)
        
        presentViewController(changeEmailNameAlert,
            animated:   true,
            completion: nil)
    }
    
    @IBAction func changePasswordButtonTapped() {
        
        let changePasswordAlert = UIAlertController(
            title:          "Change Password",
            message:        "Enter your old and new passwords.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        changePasswordAlert.addTextFieldWithConfigurationHandler() { (textField: UITextField!) -> Void in
            textField.font               = UIFont(name: "AvenirNext-Regular", size: 14.0)
            textField.placeholder        = "Enter your old password"
            textField.clearButtonMode    = UITextFieldViewMode.WhileEditing
            textField.secureTextEntry    = true
            textField.keyboardAppearance = UIKeyboardAppearance.Dark
        }
        
        changePasswordAlert.addTextFieldWithConfigurationHandler() { (textField: UITextField!) -> Void in
            textField.font               = UIFont(name: "AvenirNext-Regular", size: 14.0)
            textField.placeholder        = "Enter your new password"
            textField.clearButtonMode    = UITextFieldViewMode.WhileEditing
            textField.secureTextEntry    = true
            textField.keyboardAppearance = UIKeyboardAppearance.Dark
        }
        
        let changeButton = UIAlertAction(
            title: "Change",
            style: UIAlertActionStyle.Default)
            { (alert: UIAlertAction!) -> Void in
                self.disableButtons()
                
                if let textFields = changePasswordAlert.textFields {
                    if textFields.count == 2 {
                        let oldPasswordTextField = textFields[0] as UITextField
                        let newPasswordTextField = textFields[1] as UITextField
                        let oldPassword = oldPasswordTextField.text
                        let newPassword = newPasswordTextField.text
                        
                        MOONLog("Attempting to change password")
                        
                        // Call UserServerManager
                        UserServerManager.changeCurrentUsersPasswordFrom(oldPassword!, to: newPassword!)
                        { (errorMessage: String?) -> () in
                            self.enableButtons()
                            if let errorMessage = errorMessage {
                                MOONLog("Could not change password")
                                self.showAlertWithTitle("Could not change password", andMessage: errorMessage)
                            } else {
                                self.enableButtons()
                                MOONLog("Successfully changed password.")
                            }
                        }
                        
                    } else {
                        MOONLog("ERROR: There are NOT two textField")
                        self.enableButtons()
                    }
                } else {
                    MOONLog("ERROR: No textFields")
                    self.enableButtons()
                }
            }
        
        let cancelButton = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        
        changePasswordAlert.addAction(cancelButton)
        changePasswordAlert.addAction(changeButton)
        
        presentViewController(changePasswordAlert,
            animated:   true,
            completion: nil)
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func disableButtons() {
        changeDisplayNameButton.enabled = false
        changeEmailButton.enabled       = false
        changePasswordButton.enabled    = false
        backToMainMenuButton.enabled    = false
        
        changeDisplayNameButton.alpha = 0.4
        changeEmailButton.alpha       = 0.4
        changePasswordButton.alpha    = 0.4
        backToMainMenuButton.alpha    = 0.4
    }
    
    private func enableButtons() {
        changeDisplayNameButton.enabled = true
        changeEmailButton.enabled       = true
        changePasswordButton.enabled    = true
        backToMainMenuButton.enabled    = true
        
        changeDisplayNameButton.alpha = 1.0
        changeEmailButton.alpha       = 1.0
        changePasswordButton.alpha    = 1.0
        backToMainMenuButton.alpha    = 1.0
    }
    
    private func showAlertWithTitle(title: String, andMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let doneAction = UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(doneAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
