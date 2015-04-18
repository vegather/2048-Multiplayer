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
            
            if error == nil, let data = data {
                self.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(data.uid).observeSingleEventOfType(FEventType.Value,
                    withBlock: { (snapshot: FDataSnapshot!) -> Void in
                        let nameSnapshot = snapshot.childSnapshotForPath(FireBaseKeys.Users.DisplayName)
                        if nameSnapshot.exists() {
                            self.lastKnownCurrentUserDisplayName = nameSnapshot.value as! String
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler(errorMessage: nil)
                        })
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
    
    static let CURRENT_USER_NAME_KEY = "CurrentUserDisplayName"
    
    private(set) static var lastKnownCurrentUserDisplayName: String {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: CURRENT_USER_NAME_KEY)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let name = NSUserDefaults.standardUserDefaults().stringForKey(CURRENT_USER_NAME_KEY) {
                return name
            } else {
                NSUserDefaults.standardUserDefaults().setObject("You", forKey: CURRENT_USER_NAME_KEY)
                NSUserDefaults.standardUserDefaults().synchronize()
                return "You"
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
                
                let newUser = [FireBaseKeys.Users.Email: email, FireBaseKeys.Users.DisplayName : displayName] as NSDictionary
                let userUID = createUserData["uid"] as! String
                let newUserPath = self.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(userUID)
                
                newUserPath.setValue(newUser, withCompletionBlock: { (setNewUserError: NSError!, ref: Firebase!) -> Void in
                    if setNewUserError == nil {
                        self.loginWithEmail(email, password: password, completionHandler: { (errorMessage: String?) -> () in
                            completionHandler(errorMessage: errorMessage)
                        })
                    } else {
                        MWLog("ERROR: Got error while setting new user \(setNewUserError.localizedDescription)")
                    }
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
