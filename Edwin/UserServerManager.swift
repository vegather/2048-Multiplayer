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
            // data.auth is [uid: simplelogin:1, provider: password]
            MOONLog("Returned error \"\(error)\", data: \"\(data)\", authData: \"\(data?.auth)\"")
            
            if error == nil, let data = data {
                ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(data.uid).observeSingleEventOfType(FEventType.Value,
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
//                let errorCode = error!.code as NSInteger
                
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
        ServerManager.dataBase().unauth()
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
    
    static let CURRENT_USER_NAME_KEY  = "CurrentUserDisplayName"
    static let CURRENT_USER_EMAIL_KEY = "CurrentUserEmail"
    
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
    
    // Need this because apparently the email in authData.prividerData is not updated after 
    // a call to ServerManager.dataBase().changeEmailForUser
    private(set) static var currentUserEmail: String? {
        set {
            MOONLog("Setting email to \(newValue)")
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: CURRENT_USER_EMAIL_KEY)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let email = NSUserDefaults.standardUserDefaults().stringForKey(CURRENT_USER_EMAIL_KEY) {
                MOONLog("Returning email: \(email)")
                return email
            } else {
                let potentialEmail = ServerManager.dataBase().authData.providerData["email"] as? String
                MOONLog("Returning potentialEmail \(potentialEmail)")
                return potentialEmail
            }
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Creating And Editing Users
    // -------------------------------
    
    // Need to change the profilePicture back to non-optional
    class func createUserWithDisplayName(displayName: String, email: String, password: String, completionHandler:(errorMessage: String?) -> ()) {
        ServerManager.dataBase().createUser(email, password: password) { (createUserError: NSError!, createUserData: [NSObject : AnyObject]!) -> Void in
            // data is [uid: simplelogin:1]
            MOONLog("Created user returned error \"\(createUserError)\", data: \"\(createUserData)\"")
            
            if createUserError == nil {
                
                let newUser = [FireBaseKeys.Users.Email:        email,
                               FireBaseKeys.Users.DisplayName:  displayName,
                               FireBaseKeys.Users.Wins:         0,
                               FireBaseKeys.Users.Draws:        0,
                               FireBaseKeys.Users.Losses:       0] as NSDictionary
                
                let userUID = createUserData["uid"] as! String
                let newUserPath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(userUID)
                
                newUserPath.setValue(newUser, withCompletionBlock: { (setNewUserError: NSError!, ref: Firebase!) -> Void in
                    if setNewUserError == nil {
                        self.loginWithEmail(email, password: password, completionHandler: { (errorMessage: String?) -> () in
                            completionHandler(errorMessage: errorMessage)
                        })
                    } else {
                        MOONLog("ERROR: Got error while setting new user \(setNewUserError.localizedDescription)")
                    }
                })
            } else {
                completionHandler(errorMessage: "\(createUserError)")
            }
        }
    }
    
    class func changeCurrentUsersDisplayNameTo(newDisplayName: String, completionHandler: (errorMessage: String?) -> ()) {
        let uid = ServerManager.dataBase().authData.uid
        let displayNamePath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(uid).childByAppendingPath(FireBaseKeys.Users.DisplayName)
        
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
