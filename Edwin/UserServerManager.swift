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
        ServerManager.dataBase().authUser(email, password: password) { (error: NSError?, data: FAuthData?) -> Void in
            MOONLog("Returned error \"\(error)\", data: \"\(data)\", authData: \"\(data?.auth)\"")
            
            if error == nil, let data = data {
                let userPath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(data.uid)
                userPath.observeSingleEventOfType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
                    let nameSnapshot = snapshot.childSnapshotForPath(FireBaseKeys.Users.DisplayName)
                    if nameSnapshot.exists() {
                        self.lastKnownCurrentUserDisplayName = nameSnapshot.value as! String
                    }
                
                    let userIdentifier = snapshot.childSnapshotForPath(FireBaseKeys.Users.Identifier)
                    if userIdentifier.exists() {
                        self.currentUserIdentifier = userIdentifier.value as? Int
                    }
                    
                    self.currentUserEmail = email
                        
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(errorMessage: nil)
                    }
                }
            } else {
                if let errorCode = FAuthenticationError(rawValue: error!.code) {
                    var errorMessage = ""
                    switch (errorCode) {
                        case .UserDoesNotExist: errorMessage = "That user does not exist"
                        case .InvalidEmail:     errorMessage = "That is not a valid email address"
                        case .InvalidPassword:  errorMessage = "Incorrect password"
                        default:                errorMessage = "Unknown error while logging in"
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(errorMessage: errorMessage)
                    }
                }
            }
        }
    }
    
    class func logout() {
        ServerManager.dataBase().unauth()
        
        currentUserIdentifier = nil
        currentUserEmail = nil
    }
    
    class var isLoggedIn: Bool {
        get {
            if ServerManager.dataBase().authData != nil {
                MOONLog("The user has authData: \(ServerManager.dataBase().authData.auth)")
                return true
            } else {
                MOONLog("Not logged in")
                return false
            }
        }
    }
    
    private struct UserDefaultKeys {
        static let DisplayName    = "CurrentUserDisplayName"
        static let Email          = "CurrentUserEmail"
        static let UserIdentifier = "CurrentUserIdentifier"
    }
    
    private(set) static var lastKnownCurrentUserDisplayName: String {
        get {
            if let name = NSUserDefaults.standardUserDefaults().stringForKey(UserDefaultKeys.DisplayName) {
                return name
            } else {
                NSUserDefaults.standardUserDefaults().setObject("You", forKey: UserDefaultKeys.DisplayName)
                NSUserDefaults.standardUserDefaults().synchronize()
                return "You"
            }
        }
        set {
            MOONLog("Setting display name to \(lastKnownCurrentUserDisplayName)")
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: UserDefaultKeys.DisplayName)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    // Need this because apparently the email in authData.providerData is not updated after
    // a call to ServerManager.dataBase().changeEmailForUser
    private(set) static var currentUserEmail: String? {
        get {
            let email = NSUserDefaults.standardUserDefaults().stringForKey(UserDefaultKeys.Email)
            MOONLog("Returning email: \(email)")
            return email
        }
        set {
            MOONLog("Setting email to \(newValue)")
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: UserDefaultKeys.Email)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private(set) static var currentUserIdentifier: Int? {
        get {
            let identifier = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultKeys.UserIdentifier) as? NSNumber
            MOONLog("Returning UserIdentifier: \(identifier)")
            return identifier?.integerValue
        }
        set {
            MOONLog("Setting currentUserIdentifier to \(newValue)")
            let userDefaults = NSUserDefaults.standardUserDefaults()
            if let identifier = newValue {
                userDefaults.setObject(NSNumber(integer: identifier), forKey: UserDefaultKeys.UserIdentifier)
            } else {
                userDefaults.setObject(nil, forKey: UserDefaultKeys.UserIdentifier)
            }
            userDefaults.synchronize()
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Creating And Editing Users
    // -------------------------------
    
    // Need to change the profilePicture back to non-optional
    // The completion handler will be called on an undefined thread.
    class func createUserWithDisplayName(
        displayName      : String,
        email            : String,
        password         : String,
        completionHandler: (errorMessage: String?) -> ())
    {
        ServerManager.dataBase().createUser(
            email,
            password: password,
            withValueCompletionBlock: { (createUserError: NSError!, createUserData: [NSObject : AnyObject]!) -> Void in
            
                MOONLog("Created user returned error \"\(createUserError)\", data: \"\(createUserData)\"")
                
                if createUserError == nil {
                    
                    let userIdentifierCounter = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UserIdentifierCounter)
                    
                    userIdentifierCounter.runTransactionBlock(
                        { (data: FMutableData!) -> FTransactionResult! in
                            var value = data.value as? Int
                            if value == nil { value = 0 }
                            data.value = value! + 1
                            return FTransactionResult.successWithValue(data)
                        },
                        andCompletionBlock: { (error: NSError?, committed: Bool, snapshot: FDataSnapshot?) in
                            // Make sure the transaction succeeded, fail otherwise
                            guard let newIdentifier = snapshot?.value as? NSNumber where error == nil && committed == true else {
                                MOONLog("ERROR: Got error \"\(error)\" in completion for transaction. Committed: \(committed), Snapshot: \(snapshot)")
                                
                                ServerManager.dataBase().removeUser(email, password: password) { _ in
                                    completionHandler(errorMessage: "Unable to create the user. Try again!")
                                }
                                return
                            }
                            
                            let newUser = [
                                FireBaseKeys.Users.Email:        email,
                                FireBaseKeys.Users.DisplayName:  displayName,
                                FireBaseKeys.Users.Wins:         0,
                                FireBaseKeys.Users.Draws:        0,
                                FireBaseKeys.Users.Losses:       0,
                                FireBaseKeys.Users.Identifier:   newIdentifier
                            ] as NSDictionary
                            
                            MOONLog("CREATED USER DATA: \(createUserData)")
                            
                            let userUID = createUserData["uid"] as! String
                            let newUserPath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(userUID)
                            
                            newUserPath.setValue(newUser, withCompletionBlock: { (setNewUserError: NSError!, ref: Firebase!) -> Void in
                                guard setNewUserError == nil else {
                                    MOONLog("ERROR: Got error while setting new user \(setNewUserError.localizedDescription)")
                                    
                                    ServerManager.dataBase().removeUser(email, password: password) { _ in
                                        completionHandler(errorMessage: "Unable to create the user. Try again!")
                                    }
                                    return
                                }
                                
                                // Everything went as planned, so we can log in
                                self.loginWithEmail(email, password: password) { completionHandler(errorMessage: $0) }
                            })
                        }
                    )
                
                } else {
                    completionHandler(errorMessage: "\(createUserError)")
                }
            }
        )
    }
    
    class func changeCurrentUsersDisplayNameTo(newDisplayName: String, completionHandler: (errorMessage: String?) -> ()) {
        let uid = ServerManager.dataBase().authData.uid
        let displayNamePath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey)
                                                      .childByAppendingPath(uid)
                                                      .childByAppendingPath(FireBaseKeys.Users.DisplayName)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            displayNamePath.setValue(newDisplayName, withCompletionBlock: { (error: NSError!, fireRef: Firebase!) -> Void in
                if error == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.lastKnownCurrentUserDisplayName = newDisplayName
                        completionHandler(errorMessage: nil)
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(errorMessage: error.localizedDescription)
                    }
                }
            })
        }
    }
    
    class func changeCurrentUsersEmailTo(newEmail: String, withPassword password: String, completionHandler: (errorMessage: String?) -> ()) {
        if let currentEmail = self.currentUserEmail {
        
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                ServerManager.dataBase().changeEmailForUser(
                    currentEmail,
                    password: password,
                    toNewEmail: newEmail) { (error: NSError!) -> Void in
                        if error == nil {
                            
                            self.currentUserEmail = newEmail
                            
                            let uid = ServerManager.dataBase().authData.uid
                            let emailPath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(uid).childByAppendingPath(FireBaseKeys.Users.Email)
                            emailPath.setValue(newEmail, withCompletionBlock: { (error2: NSError!, ref: Firebase!) -> Void in
                                if error2 == nil {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        completionHandler(errorMessage: nil)
                                    }
                                } else {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        completionHandler(errorMessage: error2.localizedDescription)
                                    }
                                }
                            })
                            
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(errorMessage: error.localizedDescription)
                            }
                        }
                }
            }
        } else {
            MOONLog("Could not get current email")
            completionHandler(errorMessage: "Could not get your current Email. Try logging out and back in.")
        }
    }
    
    class func changeCurrentUsersPasswordFrom(oldPassword: String, to newPassword: String, completionHandler: (errorMessage: String?) -> ()) {
        if let currentEmail = self.currentUserEmail {
            
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                ServerManager.dataBase().changePasswordForUser(
                    currentEmail,
                    fromOld: oldPassword,
                    toNew: newPassword,
                    withCompletionBlock: { (error: NSError!) -> Void in
                        if error == nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(errorMessage: nil)
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(errorMessage: error.localizedDescription)
                            }
                        }
                })
            }
        } else {
            MOONLog("Could not get current email")
            completionHandler(errorMessage: "Could not get your current Email. Try logging out and back in.")
        }
        
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Getting and Setting Stats
    // -------------------------------
    
    class func getNumberOfWinsStatisticsByIncrementing(shouldIncrement: Bool, completionHandler: (newNumberOfWins: Int) -> ()) {
        self.getStatisticsWithPathEnding(FireBaseKeys.Users.Wins, shouldIncrement: shouldIncrement, completionHandler: completionHandler)
    }
    
    class func getNumberOfLossesStatisticsByIncrementing(shouldIncrement: Bool, completionHandler: (newNumberOfLosses: Int) -> ()) {
        self.getStatisticsWithPathEnding(FireBaseKeys.Users.Losses, shouldIncrement: shouldIncrement, completionHandler: completionHandler)
    }
    
    class func getNumberOfDrawsStatisticsByIncrementing(shouldIncrement: Bool, completionHandler: (newNumberOfDraws: Int) -> ()) {
        self.getStatisticsWithPathEnding(FireBaseKeys.Users.Draws, shouldIncrement: shouldIncrement, completionHandler: completionHandler)
    }
    
    private class func getStatisticsWithPathEnding(pathEnding: String, shouldIncrement: Bool, completionHandler: (newNumberOfWins: Int) -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let currentUserWinsRef = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(ServerManager.dataBase().authData.uid).childByAppendingPath(pathEnding)
            
            currentUserWinsRef.runTransactionBlock({ (currentStats: FMutableData!) -> FTransactionResult! in
                    MOONLog("In runTransactionBlock. pathEnding: \(pathEnding), shouldIncrement: \(shouldIncrement)")
                
                    var value = currentStats.value as? Int
                    if value == nil {
                        value = 0
                    }
                    if shouldIncrement {
                        currentStats.value = value! + 1
                    } else {
                        currentStats.value = value!
                    }
                
                    return FTransactionResult.successWithValue(currentStats)
                }, andCompletionBlock: { (error: NSError!, committed: Bool, theData: FDataSnapshot!) -> Void in
                    
                    FTransactionResult.abort()
                    
                    if error == nil {
                        if committed {
                            MOONLog("Got new value: \(theData.value as! Int) for path ending \(pathEnding)")
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(newNumberOfWins: theData.value as! Int)
                            }
                        } else {
                            MOONLog("Did not commit pathEnding\(pathEnding), shouldIncrement: \(shouldIncrement)")
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(newNumberOfWins: 0)
                            }
                        }
                    } else {
                        MOONLog("CompletionBlock got error: \"\(error.localizedDescription)\" pathEnding\(pathEnding), shouldIncrement: \(shouldIncrement)")
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler(newNumberOfWins: 0)
                        }
                    }
                })
        }
    }
}
