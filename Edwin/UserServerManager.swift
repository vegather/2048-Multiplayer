//
//  UserServerManager.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 05/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

class UserServerManager: ServerManager {
    
    
    
    // -------------------------------
    // MARK: Logging In And Out
    // -------------------------------
    
    class func loginWithEmail(email: String, password: String, completionHandler:(errorMessage: String?) -> ()) {
        dataBase().authUser(email, password: password) { (error: NSError?, data: FAuthData?) -> Void in
            // data.auth is [uid: simplelogin:1, provider: password]
            MWLog("Returned error \"\(error)\", data: \"\(data)\", authData: \"\(data?.auth)\"")
            
            if error == nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(errorMessage: nil)
                })
            } else {
                let errorCode = error!.code as NSInteger
                
                if let errorCode = FAuthenticationError(rawValue: error!.code) {
                    switch (errorCode) {
                    case .UserDoesNotExist:
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler(errorMessage: "That user does not exist")
                        })
                    case .InvalidEmail:
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler(errorMessage: "That is not a valid email address")
                        })
                    case .InvalidPassword:
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler(errorMessage: "Incorrect password")
                        })
                    default:
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler(errorMessage: "Unknown error while logging in")
                        })
                    }
                }
            }
        }
    }
    
    class func logout() {
        dataBase().unauth()
    }
    
    class var isLoggedIn: Bool {
        get {
            if dataBase().authData != nil {
                return true
            } else {
                return false
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Creating And Editing Users
    // -------------------------------
    
    // Need to change the profilePicture back to non-optional
    class func createUserWithDisplayName(displayName: String, email: String, password: String, completionHandler:(errorMessage: String?) -> ()) {
        dataBase().createUser(email, password: password) { (createUserError: NSError!, createUserData: [NSObject : AnyObject]!) -> Void in
            // data is [uid: simplelogin:1]
            MWLog("Created user returned error \"\(createUserError)\", data: \"\(createUserData)\"")
            
            if createUserError == nil {
                self.loginWithEmail(email, password: password, completionHandler: { (errorMessage: String?) -> () in
                    
                    let newUser = ["email": email, "displayName" : displayName] as NSDictionary
                    self.dataBase().childByAppendingPath("users").childByAppendingPath(self.dataBase().authData.uid).setValue(newUser)
                    
                    completionHandler(errorMessage: errorMessage)
                })
            } else {
                completionHandler(errorMessage: "\(createUserError)")
            }
        }
    }
    
    func changeCurrentUsersDisplayNameTo(newDisplayName: String, completionHandler: (errorMessage: String?) -> ()) {
        
    }
    
    func changeCurrentUsersEmailTo(newEmail: String, completionHandler: (errorMessage: String?) -> ()) {
        
    }
    
    func changeCurrentUsersPasswordTo(newPassword: String, completionHandler: (errorMessage: String?) -> ()) {
        
    }
    
}