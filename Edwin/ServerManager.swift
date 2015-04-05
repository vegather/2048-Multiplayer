//
//  ServerManager.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 05/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation
import UIKit

private let FIREBASE_URL = "https://project-edwin.firebaseio.com"

class ServerManager {
    
    
    // -------------------------------
    // MARK: Logging In And Out
    // -------------------------------
    
    class func loginWithEmail(email: String, password: String, completionHandler:(errorMessage: String?) -> ()) {
        
        let theDataBase = Firebase(url: FIREBASE_URL)
        theDataBase.authUser(email, password: password) { (error: NSError?, data: FAuthData?) -> Void in
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
        Firebase(url: FIREBASE_URL).unauth()
    }
    
    class var isLoggedIn: Bool {
        get {
            if Firebase(url: FIREBASE_URL).authData != nil {
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
    class func createUserWithEmail(email: String, password: String, profilePicture: UIImage?, completionHandler:(errorMessage: String?) -> ()) {
        let theDataBase = Firebase(url: FIREBASE_URL)
        theDataBase.createUser(email, password: password) { (createUserError: NSError!, createUserData: [NSObject : AnyObject]!) -> Void in
            // data is [uid: simplelogin:1]
            MWLog("Created user returned error \"\(createUserError)\", data: \"\(createUserData)\"")
            
            if createUserError == nil {
                self.loginWithEmail(email, password: password, completionHandler: { (errorMessage: String?) -> () in
                    completionHandler(errorMessage: errorMessage)
                })
            } else {
                completionHandler(errorMessage: "\(createUserError)")
            }
        }
    }
    
    // changeEmailForUser:(NSString *)email password:(NSString *)password toNewEmail:(NSString *)newEmail withCompletionBlock:(void ( ^ ) ( NSError *error ))block
    func changeCurrentUsersEmailTo(newEmail: String, completionHandler: (errorMessage: String?) -> ()) {
        
    }
    
    
    
    
}