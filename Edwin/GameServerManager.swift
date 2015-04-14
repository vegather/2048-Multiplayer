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
        let initialGameData = ["BoardSize" : dimension, "TurnDuration": turnDuration, "Opponent" : "_"]
        let dataBasePath = GameServerManager.dataBase().childByAppendingPath("GameSessions").childByAppendingPath(currentUserID)
        dataBasePath.onDisconnectRemoveValue() // If the app is closed, network is lost, or other error: Remove the game from Firebase
        
        dataBasePath.setValue(initialGameData, withCompletionBlock: { (error: NSError!, ref: Firebase!) -> Void in
            if error == nil {
                // No error
                
                // Need to start observing the value of the opponent key
                let handle = dataBasePath.observeEventType(FEventType.ChildAdded,
                    withBlock: { (snapshot: FDataSnapshot!) -> Void in
                        if snapshot != nil {
                            if snapshot.hasChild("Opponent") {
                                if let opponent = (snapshot.value as? NSDictionary)?.objectForKey("Opponent") as? String {
                                    self.creatorDelegate?.gotOpponentWithDisplayName(opponent)
                                } else {
                                    MWLog("")
                                }
                            } else {
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
        
        let dataBasePath = GameServerManager.dataBase().childByAppendingPath("GameSessions").childByAppendingPath("simplelogin:\(gamepin)")
        
        dataBasePath.observeSingleEventOfType(FEventType.Value,
            withBlock: { (gameSnapshot: FDataSnapshot!) -> Void in
                if gameSnapshot != nil  {
                    // There is a game with requested gamepin
                    dataBasePath.childByAppendingPath("InitialState").observeSingleEventOfType(FEventType.Value,
                        withBlock: { (initialStateSnapshot: FDataSnapshot!) -> Void in
                            if initialStateSnapshot != nil {
                                // The game has an initial state
                                dataBasePath.childByAppendingPath("Opponent").observeSingleEventOfType(FEventType.Value,
                                    withBlock: { (opponentSnapshot: FDataSnapshot!) -> Void in
                                        if (opponentSnapshot.value as? String) == "_" {
                                            // There is no opponent
                                            
                                        } else {
                                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                completionHandler(dimension: nil, turnDuration: nil, errorMessage: "The game with gamepin \(gamepin) already has an opponent")
                                            })
                                        }
                                    }, withCancelBlock: { (error:NSError!) -> Void in
                                        if error == nil {
                                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                completionHandler(dimension: nil, turnDuration: nil, errorMessage: "Unknown error while getting opponent for game with gamepin \(gamepin)")
                                            })
                                        } else {
                                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                completionHandler(dimension: nil, turnDuration: nil, errorMessage: error.localizedDescription)
                                            })
                                        }
                                    })
                            } else {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(dimension: nil, turnDuration: nil, errorMessage: "The game with gamepin \(gamepin) does not yet have an initial state")
                                })
                            }
                        }, withCancelBlock: { (error: NSError!) -> Void in
                            if error == nil {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(dimension: nil, turnDuration: nil, errorMessage: "Unknown error while getting initial state for game with gamepin \(gamepin)")
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
        GameServerManager.dataBase().removeAllObservers()
    }
    
    func deleteEventWithGamepin(gamepinToRemove: String) {
        GameServerManager.dataBase().childByAppendingPath("GameSessions").childByAppendingPath("simplelogin:\(gamepinToRemove)").removeValue()
    }
}
