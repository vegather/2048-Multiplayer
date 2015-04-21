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
            MWLog("Returned error \"\(error)\", data: \"\(data)\", authData: \"\(data?.auth)\"")
            
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
        ServerManager.dataBase().unauth()
    }
    
    class var isLoggedIn: Bool {
        get {
            if ServerManager.dataBase().authData != nil {
                MWLog("The user has authData: \(ServerManager.dataBase().authData.auth)")
                return true
            } else {
                MWLog("Not logged in")
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
    
    static var currentUserEmail: String? {
        get {
            return ServerManager.dataBase().authData.providerData["email"] as? String
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Creating And Editing Users
    // -------------------------------
    
    // Need to change the profilePicture back to non-optional
    class func createUserWithDisplayName(displayName: String, email: String, password: String, completionHandler:(errorMessage: String?) -> ()) {
        ServerManager.dataBase().createUser(email, password: password) { (createUserError: NSError!, createUserData: [NSObject : AnyObject]!) -> Void in
            // data is [uid: simplelogin:1]
            MWLog("Created user returned error \"\(createUserError)\", data: \"\(createUserData)\"")
            
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
                        MWLog("ERROR: Got error while setting new user \(setNewUserError.localizedDescription)")
                    }
                })
            } else {
                completionHandler(errorMessage: "\(createUserError)")
            }
        }
    }
    
    class func changeCurrentUsersDisplayNameTo(newDisplayName: String, completionHandler: (errorMessage: String?) -> ()) {
        let uid = ServerManager.dataBase().authData.uid
        
    }
    
    class func changeCurrentUsersEmailTo(newEmail: String, withPassword password: String, completionHandler: (errorMessage: String?) -> ()) {
        if let currentEmail = ServerManager.dataBase().authData.providerData["email"] as? String {
        
            ServerManager.dataBase().changeEmailForUser(
                currentEmail,
                password: password,
                toNewEmail: newEmail) { (error: NSError!) -> Void in
                    if error != nil {
                        
                    } else {
                        completionHandler(errorMessage: nil)
                    }
            }
        } else {
            MWLog("Could not get current email")
            completionHandler(errorMessage: "Could not get your current Email. Try logging out and back in.")
        }
    }
    
    class func changeCurrentUsersPasswordFrom(oldPassword: String, to newPassword: String, completionHandler: (errorMessage: String?) -> ()) {
        if let currentEmail = ServerManager.dataBase().authData.providerData["email"] as? String {
            
        } else {
            MWLog("Could not get current email")
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
                    MWLog("In runTransactionBlock. pathEnding: \(pathEnding), shouldIncrement: \(shouldIncrement)")
                
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
                            MWLog("Got new value: \(theData.value as! Int) for path ending \(pathEnding)")
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(newNumberOfWins: theData.value as! Int)
                            }
                        } else {
                            MWLog("Did not commit pathEnding\(pathEnding), shouldIncrement: \(shouldIncrement)")
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(newNumberOfWins: 0)
                            }
                        }
                    } else {
                        MWLog("CompletionBlock got error: \"\(error.localizedDescription)\" pathEnding\(pathEnding), shouldIncrement: \(shouldIncrement)")
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler(newNumberOfWins: 0)
                        }
                    }
                })
        }
    }
}
