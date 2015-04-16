//
//  GameServerManager.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 05/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

protocol GameCreatorDelegate {
    func gotOpponentWithDisplayName(displayName: String)
}

protocol GameDelegate {
    func opponentDidPerformMoveInDirection(direction: MoveDirection, whichSpawnedTile newTile: TileValue, atCoordinate coordinate: Coordinate)
}

class GameServerManager: ServerManager {
    
    var creatorDelegate: GameCreatorDelegate?
    var gameDelegate: GameDelegate?
    
    private var creatorOfCurrentGame: String? // This will be used to reference a game
    
    
    
    
    // -------------------------------
    // MARK: Creating and Joining Games
    // -------------------------------
    
    func createGameWithDimension(dimension: Int, turnDuration: Int, completionHandler: (gamePin: String!, errorMessage: String?) -> ()) {
        // Overwrites previous game
        let currentUserID = GameServerManager.dataBase().authData.uid
        let initialGameData = ["BoardSize" : dimension, "TurnDuration": turnDuration]
        let dataBasePath = GameServerManager.dataBase().childByAppendingPath("GameSessions").childByAppendingPath(currentUserID)
        dataBasePath.onDisconnectRemoveValue() // If the app is closed, network is lost, or other error: Remove the game from Firebase
        
        dataBasePath.setValue(initialGameData, withCompletionBlock: { (error: NSError!, ref: Firebase!) -> Void in
            if error == nil {
                // No error
                
                // Need to start observing the value of the opponent key
                let handle = dataBasePath.observeEventType(FEventType.ChildAdded,
                    withBlock: { (snapshot: FDataSnapshot!) -> Void in
                        MWLog("A child was added to the current game. Snapshot: \(snapshot), KEY: \(snapshot.key)")
                        if snapshot != nil {
                            if snapshot.key == "Opponent" {
                                if let opponentUID = snapshot.value as? String {
                                    MWLog("Got opponent with uid \(opponentUID)")
                                    let userPath = GameServerManager.dataBase().childByAppendingPath("users").childByAppendingPath(opponentUID)
                                    userPath.observeSingleEventOfType(FEventType.Value,
                                        withBlock: { (snapshot: FDataSnapshot!) -> Void in
                                            MWLog("Got userdata \"\(snapshot)\" for uid \"\(opponentUID)\"")
                                            if let opponentName = snapshot.childSnapshotForPath("displayName").value as? String {
                                                MWLog("Opponent name \"\(opponentName)\"")
                                                self.creatorDelegate?.gotOpponentWithDisplayName(opponentName)
                                            } else {
                                                MWLog("User with uid \(opponentUID) does not have a display name")
                                            }
                                    })
                                    
                                } else {
                                    MWLog("Could not get an opponent for value: \(snapshot.value)")
                                }
                            } else {
                                MWLog("Will call completionHandler with \"No opponent yet\"")
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(gamePin: nil, errorMessage: "No opponent yet")
                                })
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completionHandler(gamePin: nil, errorMessage: "Got child but no opponent")
                            })
                        }
                    }, withCancelBlock: { (error: NSError!) -> Void in
                        if error == nil {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completionHandler(gamePin: nil, errorMessage: "Unknown error while listening for observer")
                            })
                        } else {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completionHandler(gamePin: nil, errorMessage: error.localizedDescription)
                            })
                        }
                })
                
                var gamePin: String
                if currentUserID.hasPrefix("simplelogin:") {
                    gamePin = ((currentUserID as NSString).substringFromIndex(count("simplelogin:")) as String)
                } else {
                    gamePin = currentUserID
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(gamePin: gamePin, errorMessage: nil)
                })
                
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(gamePin: nil, errorMessage: error.localizedDescription)
                })
            }
        })
    }
    
    func addInitialStateToCurrentGame(
        #firstTile: TileValue,
        hasCoordinate firstCoordinate: Coordinate,
        secondTile: TileValue,
        hasCoordinate secondCoordinate: Coordinate,
        completionHandler:(errorMessage: String?) -> ())
    {
        let currentUserID = GameServerManager.dataBase().authData.uid
        let dataBasePath = GameServerManager.dataBase().childByAppendingPath("GameSessions").childByAppendingPath(currentUserID).childByAppendingPath("InitialState")
        let initialState = ["tile1":
                                    ["Position" : "\(firstCoordinate.x),\(firstCoordinate.y)",
                                     "Value"    : "\(firstTile.scoreValue)"],
                            "tile2":
                                    ["Position" : "\(secondCoordinate.x),\(secondCoordinate.y)",
                                     "Value"    : "\(secondTile.scoreValue)"]
                           ]
        
        dataBasePath.setValue(initialState, withCompletionBlock: { (error: NSError!, ref: Firebase!) -> Void in
            if error == nil {
                // No error
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(errorMessage: nil)
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(errorMessage: error.localizedDescription)
                })
            }
        })
    }
    
    func joinGameWithGamepin(gamepin: String, completionHandler: (dimension: Int!, turnDuration: Int!, errorMessage: String?) -> ()) {
        // Check if game with gamepin exists
        // Check if that game does not have an opponent
        // Set self as opponent
        // Call completionHandler
        
        let gameEntryPoint = GameServerManager.dataBase().childByAppendingPath("GameSessions").childByAppendingPath("simplelogin:\(gamepin)")
        
        gameEntryPoint.observeSingleEventOfType(FEventType.Value,
            withBlock: { (gameSnapshot: FDataSnapshot!) -> Void in
                if gameSnapshot != nil  {
                    // There is a game with requested gamepin
                    gameEntryPoint.observeSingleEventOfType(FEventType.Value,
                        withBlock: { (gameSnapshot: FDataSnapshot!) -> Void in
                            if gameSnapshot.childSnapshotForPath("InitialState").exists() == false { // WARNING! WARNING! WARNING! Set to true
                                // The game has an initial state
                                if gameSnapshot.childSnapshotForPath("Opponent").exists() == false {
                                    // There is no opponent yet
                                    gameEntryPoint.childByAppendingPath("Opponent").setValue(GameServerManager.dataBase().authData.uid)
                                    
                                    let gameDimension = gameSnapshot.childSnapshotForPath("BoardSize").value as! Int
                                    let gameTurnDuration = gameSnapshot.childSnapshotForPath("TurnDuration").value as! Int
                                    
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        completionHandler(dimension: gameDimension, turnDuration: gameTurnDuration, errorMessage: nil)
                                    })
                                    
                                } else {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        completionHandler(dimension: nil, turnDuration: nil, errorMessage: "")
                                    })
                                }
                            } else {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(dimension: nil, turnDuration: nil, errorMessage: "The game has no initial state")
                                })
                            }
                        }, withCancelBlock: { (error: NSError!) -> Void in
                            if error == nil {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(dimension: nil, turnDuration: nil, errorMessage: "Unknown error while getting initial the game with gamepin \(gamepin)")
                                })
                            } else {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(dimension: nil, turnDuration: nil, errorMessage: error.localizedDescription)
                                })
                            }
                        })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(dimension: nil, turnDuration: nil, errorMessage: "There is no game with gamepin \(gamepin)")
                    })
                }
            }) { (error: NSError!) -> Void in
                if error == nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(dimension: nil, turnDuration: nil, errorMessage: "Unknown error while getting game with gamepin \(gamepin)")
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(dimension: nil, turnDuration: nil, errorMessage: error.localizedDescription)
                    })
                }
        }
    }
    
    func performedMoveInDirection<T: Evolvable>(direction: MoveDirection, whichSpawnedTile newTile: T, atCoordinate coordinate: Coordinate) {
        // Update the LastMove on the server
        // Use updateChildValues
        
        
    }
    
    
    
    
    // -------------------------------
    // MARK: Cleanup
    // -------------------------------
    
    func stopListeningForChanges() {
        MWLog()
        GameServerManager.dataBase().removeAllObservers()
    }
    
    func deleteEventWithGamepin(gamepinToRemove: String) {
        MWLog("Gamepin to remove: \(gamepinToRemove)")
        GameServerManager.dataBase().childByAppendingPath("GameSessions").childByAppendingPath("simplelogin:\(gamepinToRemove)").removeValue()
    }
}














//dataBasePath.childByAppendingPath("Opponent").observeSingleEventOfType(FEventType.Value,
//    withBlock: { (opponentSnapshot: FDataSnapshot!) -> Void in
//        if opponentSnapshot.exists() == false {
//            // There is no opponent, so create it
//            dataBasePath.childByAppendingPath("Opponent").setValue(GameServerManager.dataBase().authData.uid)
//            
//        } else {
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                completionHandler(dimension: nil, turnDuration: nil, errorMessage: "The game with gamepin \(gamepin) already has an opponent")
//            })
//        }
//    }, withCancelBlock: { (error:NSError!) -> Void in
//        if error == nil {
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                completionHandler(dimension: nil, turnDuration: nil, errorMessage: "Unknown error while getting opponent for game with gamepin \(gamepin)")
//            })
//        } else {
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                completionHandler(dimension: nil, turnDuration: nil, errorMessage: error.localizedDescription)
//            })
//        }
//})