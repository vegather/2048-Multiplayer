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
    func opponentDidPerformMoveInDirection<T: Evolvable>(direction: MoveDirection, whichSpawnedTile newTile: T, atCoordinate coordinate: Coordinate)
}


class GameServerManager: ServerManager {
    
    var creatorDelegate: GameCreatorDelegate?
    var gameDelegate: GameDelegate?
    
    private var creatorOfCurrentGame: String? // This will be used to reference a game
    
    
    
    // -------------------------------
    // MARK: Creating and Joining Games
    // -------------------------------
    
    func createGameWithDimension<T: Evolvable>(_: T, dimension: Int, turnDuration: Int, completionHandler: (gamePin: String!, errorMessage: String?) -> ()) {
        // Overwrites previous game
        self.creatorOfCurrentGame = ServerManager.dataBase().authData.uid
        let initialGameData = [GameKeys.BoardSizeKey    : dimension,
                               GameKeys.TurnDurationKey : turnDuration,
                               GameKeys.LastMoveKey     : [GameKeys.LastMove.MoveDirectionKey   : "_",
                                                          GameKeys.LastMove.UpdaterKey          : "_",
                                                          GameKeys.LastMove.NewTileKey          : [GameKeys.LastMove.NewTile.PositionKey    : "_",
                                                                                                   GameKeys.LastMove.NewTile.ValueKey       : "_"]
                                                           ]
                              ]
        
        let dataBasePath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.GameSessionsKey).childByAppendingPath(self.creatorOfCurrentGame!)
        dataBasePath.onDisconnectRemoveValue() // If the app is closed, network is lost, or other error: Remove the game from Firebase
        
        dataBasePath.setValue(initialGameData, withCompletionBlock: { (error: NSError!, ref: Firebase!) -> Void in
            if error == nil {
                // No error
                
                dataBasePath.childByAppendingPath(GameKeys.LastMoveKey).observeEventType(FEventType.Value)
                    { (lastMoveSnapshot: FDataSnapshot!) -> Void in
                        MOONLog("Got last move: \(lastMoveSnapshot)")
                        
                        self.processNewLastMove(T(scoreValue: T.getBaseValue().scoreValue), lastMoveSnapshot: lastMoveSnapshot)
                }
                
                // Need to start observing the value of the opponent key
                _ = dataBasePath.observeEventType(FEventType.ChildAdded,
                    withBlock: { (snapshot: FDataSnapshot!) -> Void in
                        MOONLog("A child was added to the current game. Snapshot: \(snapshot), KEY: \(snapshot.key)")
                        if snapshot != nil {
                            if snapshot.key == GameKeys.OpponentKey {
                                if let opponentUID = snapshot.value as? String {
                                    MOONLog("Got opponent with uid \(opponentUID)")
                                    let userPath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath(opponentUID)
                                    userPath.observeSingleEventOfType(FEventType.Value,
                                        withBlock: { (snapshot: FDataSnapshot!) -> Void in
                                            MOONLog("Got userdata \"\(snapshot)\" for uid \"\(opponentUID)\"")
                                            if let opponentName = snapshot.childSnapshotForPath(FireBaseKeys.Users.DisplayName).value as? String {
                                                MOONLog("Opponent name \"\(opponentName)\"")
                                                self.creatorDelegate?.gotOpponentWithDisplayName(opponentName)
                                            } else {
                                                MOONLog("User with uid \(opponentUID) does not have a display name")
                                            }
                                    })
                                    
                                } else {
                                    MOONLog("ERROR: Could not get an opponent for value: \(snapshot.value)")
                                }
                            } else {
                                MOONLog("ERROR: Will call completionHandler with \"No opponent yet\"")
                                dispatch_async(dispatch_get_main_queue()) {
                                    completionHandler(gamePin: nil, errorMessage: "No opponent yet")
                                }
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(gamePin: nil, errorMessage: "Got child but no opponent")
                            }
                        }
                    }, withCancelBlock: { (error: NSError!) -> Void in
                        if error == nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(gamePin: nil, errorMessage: "Unknown error while listening for observer")
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(gamePin: nil, errorMessage: error.localizedDescription)
                            }
                        }
                })
                
                var gamePin: String
                if self.creatorOfCurrentGame!.hasPrefix("simplelogin:") {
                    gamePin = ((self.creatorOfCurrentGame! as NSString).substringFromIndex("simplelogin:".characters.count) as String)
                } else {
                    gamePin = self.creatorOfCurrentGame!
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(gamePin: gamePin, errorMessage: nil)
                }
                
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(gamePin: nil, errorMessage: error.localizedDescription)
                }
            }
        })
    }
    
    func addInitialStateToCurrentGame<T: Evolvable>(
        firstTile firstTile: T,
        hasCoordinate firstCoordinate: Coordinate,
        secondTile: T,
        hasCoordinate secondCoordinate: Coordinate,
        completionHandler:(errorMessage: String?) -> ())
    {
        let currentUserID = ServerManager.dataBase().authData.uid
        let dataBasePath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.GameSessionsKey).childByAppendingPath(currentUserID).childByAppendingPath(GameKeys.InitialStateKey)
        
        let initialState = [GameKeys.InitialState.Tile1Key:
                                    [GameKeys.InitialState.Tile.PositionKey : "\(firstCoordinate.x),\(firstCoordinate.y)",
                                     GameKeys.InitialState.Tile.ValueKey    : "\(firstTile.scoreValue)"],
                            GameKeys.InitialState.Tile2Key:
                                    [GameKeys.InitialState.Tile.PositionKey : "\(secondCoordinate.x),\(secondCoordinate.y)",
                                     GameKeys.InitialState.Tile.ValueKey    : "\(secondTile.scoreValue)"]
                           ]
        
        dataBasePath.setValue(initialState, withCompletionBlock: { (error: NSError!, ref: Firebase!) -> Void in
            if error == nil {
                // No error
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
    
    func joinGameWithGamepin<T: Evolvable>(gamepin: String, completionHandler: (gameSetup: GameSetup<T>!, errorMessage: String?) -> ()) {
        // Check if game with gamepin exists
        // Check if that game does not have an opponent
        // Set self as opponent
        // Call completionHandler
        
        let gameEntryPoint = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.GameSessionsKey).childByAppendingPath("simplelogin:\(gamepin)")
        
        gameEntryPoint.observeSingleEventOfType(FEventType.Value,
            withBlock: { (gameSnapshot: FDataSnapshot!) -> Void in
                if gameSnapshot.exists() {
                    if gameSnapshot.childSnapshotForPath(GameKeys.InitialStateKey).exists() == true {
                        // The game has an initial state
                        if gameSnapshot.childSnapshotForPath(GameKeys.OpponentKey).exists() == false {
                            // There is no opponent yet
                            
                            MOONLog("Delegate1: \(self.gameDelegate)")
                            
                            gameEntryPoint.childByAppendingPath(GameKeys.LastMoveKey).observeEventType(FEventType.Value)
                                { (lastMoveSnapshot: FDataSnapshot!) -> Void in
                                    MOONLog("Got last move: \(lastMoveSnapshot)")
                                    MOONLog("Delegate2: \(self.gameDelegate)")
                                    
                                    self.processNewLastMove(T(scoreValue: T.getBaseValue().scoreValue), lastMoveSnapshot: lastMoveSnapshot)
                                }
                            
                            let userPath = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.UsersKey).childByAppendingPath("simplelogin:\(gamepin)")
                            userPath.observeSingleEventOfType(FEventType.Value)
                                { (userSnapshot: FDataSnapshot!) -> Void in
                                    MOONLog("Got userdata \"\(userSnapshot)\" for uid \"simplelogin\(gamepin)\"")
                                    if let opponentName = userSnapshot.childSnapshotForPath(FireBaseKeys.Users.DisplayName).value as? String {
                                        MOONLog("Game creator (opponent) name \"\(opponentName)\"")
                                        
                                        // ####  WARNING!!  ####
                                        // SHOULD USE MORE PROTECTION IN HERE! THIS MIGHT CRASH!! AND IT DOES!
                                        
                                        self.creatorOfCurrentGame = "simplelogin:\(gamepin)"
                                        
                                        gameEntryPoint.childByAppendingPath(GameKeys.OpponentKey).setValue(ServerManager.dataBase().authData.uid)
                                        
                                        let boardSizeSnapshot       = gameSnapshot.childSnapshotForPath(GameKeys.BoardSizeKey)
                                        let turnDurationSnapshot    = gameSnapshot.childSnapshotForPath(GameKeys.TurnDurationKey)
                                        let initialStateSnapshot    = gameSnapshot.childSnapshotForPath(GameKeys.InitialStateKey)
                                        
                                        if boardSizeSnapshot.exists() && turnDurationSnapshot.exists() && initialStateSnapshot.exists() {
                                        
                                            let gameDimension           = boardSizeSnapshot.value as! Int
                                            let gameTurnDuration        = turnDurationSnapshot.value as! Int
                                            
                                            let tileOneSnapshot         = initialStateSnapshot.childSnapshotForPath(GameKeys.InitialState.Tile1Key)
                                            let tileTwoSnapshot         = initialStateSnapshot.childSnapshotForPath(GameKeys.InitialState.Tile2Key)
                                            
                                            let tileOneValueString      = tileOneSnapshot.childSnapshotForPath(GameKeys.InitialState.Tile.ValueKey).value    as! String
                                            let tileOneCoordinateString = tileOneSnapshot.childSnapshotForPath(GameKeys.InitialState.Tile.PositionKey).value as! String
                                            let tileTwoValueString      = tileTwoSnapshot.childSnapshotForPath(GameKeys.InitialState.Tile.ValueKey).value    as! String
                                            let tileTwoCoordinateString = tileTwoSnapshot.childSnapshotForPath(GameKeys.InitialState.Tile.PositionKey).value as! String
                                            
                                            let tileOneValue = T(scoreValue: Int(tileOneValueString)!)
                                            let tileTwoValue = T(scoreValue: Int(tileTwoValueString)!)
                                            
                                            let tileOneCoordinateParts = tileOneCoordinateString.componentsSeparatedByString(",")
                                            let tileTwoCoordinateParts = tileTwoCoordinateString.componentsSeparatedByString(",")
                                            
                                            let tileOneCoordinate = Coordinate(x: Int(tileOneCoordinateParts[0])!, y: Int(tileOneCoordinateParts[1])!)
                                            let tileTwoCoordinate = Coordinate(x: Int(tileTwoCoordinateParts[0])!, y: Int(tileTwoCoordinateParts[1])!)
                                            
                                            let setup = GameSetup(
                                                players:                Players.Multi,
                                                setupForCreating:       false,
                                                dimension:              gameDimension,
                                                turnDuration:           gameTurnDuration,
                                                firstValue:             tileOneValue,
                                                firstCoordinate:        tileOneCoordinate,
                                                secondValue:            tileTwoValue,
                                                secondCoordinate:       tileTwoCoordinate,
                                                opponentDisplayName:    opponentName,
                                                gameServer:             self)

                                            dispatch_async(dispatch_get_main_queue()) {
                                                completionHandler(gameSetup: setup, errorMessage: nil)
                                            }
                                        } else {
                                            dispatch_async(dispatch_get_main_queue()) {
                                                MOONLog("Missing boardSize, turnDuration, or initialState")
                                                completionHandler(gameSetup: nil, errorMessage: "There is no game with gamepin \(gamepin)")
                                            }
                                        }
                                    } else {
                                        dispatch_async(dispatch_get_main_queue()) {
                                            completionHandler(gameSetup: nil, errorMessage: "User with uid simplelogin:\(gamepin) does not have a display name")
                                        }
                                    }
                                }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completionHandler(gameSetup: nil, errorMessage: "The game already have an opponent")
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler(gameSetup: nil, errorMessage: "The game is not completely created yet. Wait for prompt on opponents screen.")
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(gameSetup: nil, errorMessage: "There is no game with gamepin \(gamepin)")
                    }
                }
                
            }) { (error: NSError!) -> Void in
                if error == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(gameSetup: nil, errorMessage: "Unknown error while getting game with gamepin \(gamepin)")
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(gameSetup: nil, errorMessage: error.localizedDescription)
                    }
                }
        }
    }
    
    func performedMoveInDirection<T: Evolvable>(direction: MoveDirection, whichSpawnedTile newTile: T, atCoordinate coordinate: Coordinate) {
        // Update the LastMove on the server
        // Use updateChildValues to not overwrite
        if let creator = self.creatorOfCurrentGame {
            let gameEntryPoint = ServerManager.dataBase().childByAppendingPath(FireBaseKeys.GameSessionsKey).childByAppendingPath(creator)
            let lastMoveEntryPoint = gameEntryPoint.childByAppendingPath(GameKeys.LastMoveKey)
            
            var directionString = "_"
            switch direction {
            case MoveDirection.Up:
                directionString = Direction.Up
            case MoveDirection.Down:
                directionString = Direction.Down
            case MoveDirection.Left:
                directionString = Direction.Left
            case MoveDirection.Right:
                directionString = Direction.Right
            }
            
            let coordinateString = "\(coordinate.x),\(coordinate.y)"
            let valueString = "\(newTile.scoreValue)"
            
            let newMoveData = [GameKeys.LastMove.MoveDirectionKey  : directionString,
                               GameKeys.LastMove.UpdaterKey        : ServerManager.dataBase().authData.uid,
                               GameKeys.LastMove.NewTileKey        : [GameKeys.LastMove.NewTile.PositionKey   : coordinateString,
                                                                      GameKeys.LastMove.NewTile.ValueKey      : valueString]
                              ]
            
            lastMoveEntryPoint.setValue(newMoveData)
            
            MOONLog("Updated LastMove with direction: \(directionString), spawnCoordinate: \(coordinateString), spawnValue: \(valueString)")
            
        } else {
            MOONLog("ERROR: No game? Or something")
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func processNewLastMove<T: Evolvable>(_: T, lastMoveSnapshot: FDataSnapshot!) {
        let directionSnapshot           = lastMoveSnapshot.childSnapshotForPath(GameKeys.LastMove.MoveDirectionKey)
        let newTileCoordinateSnapshot   = lastMoveSnapshot.childSnapshotForPath(GameKeys.LastMove.NewTileKey).childSnapshotForPath(GameKeys.LastMove.NewTile.PositionKey)
        let newTileValueSnapshot        = lastMoveSnapshot.childSnapshotForPath(GameKeys.LastMove.NewTileKey).childSnapshotForPath(GameKeys.LastMove.NewTile.ValueKey)
        let updaterSnapshot             = lastMoveSnapshot.childSnapshotForPath(GameKeys.LastMove.UpdaterKey)
        
        if directionSnapshot.exists() && newTileCoordinateSnapshot.exists() && newTileValueSnapshot.exists() {
        
            let moveDirectionString   = directionSnapshot.value as! String
            let spawnCoordinateString = newTileCoordinateSnapshot.value as! String
            let spawnValueString      = newTileValueSnapshot.value as! String
            let updaterString         = updaterSnapshot.value as! String
            
            MOONLog("Got moveDirectionString: \(moveDirectionString), spawnCoordinateString: \(spawnCoordinateString), spawnValueString: \(spawnValueString)")
            
            if moveDirectionString != "_" && spawnCoordinateString != "_" && spawnValueString != "_" && updaterString != "_" {
                if updaterString != ServerManager.dataBase().authData.uid {
                
                    var direction: MoveDirection
                    switch moveDirectionString {
                    case Direction.Up:
                        direction = MoveDirection.Up
                    case Direction.Down:
                        direction = MoveDirection.Down
                    case Direction.Left:
                        direction = MoveDirection.Left
                    case Direction.Right:
                        direction = MoveDirection.Right
                    default:
                        direction = MoveDirection.Up // Just a default
                    }
                    
                    let tileCoordinateParts = spawnCoordinateString.componentsSeparatedByString(",")
                    let tileCoordinate = Coordinate(x: Int(tileCoordinateParts[0])!, y: Int(tileCoordinateParts[1])!)
                    
                    let tileValue = T(scoreValue: Int(spawnValueString)!)
                    
                    MOONLog("Generated direction: \(direction), spawnCoordinate: \(tileCoordinate), spawnValue: \(tileValue)")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        MOONLog("Notifying \(self.gameDelegate)")
                        self.gameDelegate?.opponentDidPerformMoveInDirection(direction, whichSpawnedTile: tileValue, atCoordinate: tileCoordinate)
                    }
                } else {
                    MOONLog("That last move was done by the current user")
                }
            } else {
                MOONLog("ERROR: At least one of the fields does not exist")
            }
        } else {
            MOONLog("ERROR: Bad format")
        }
    }
    
    
    
    // -------------------------------
    // MARK: Cleanup
    // -------------------------------
    
    func stopListeningForChanges() {
        MOONLog()
        ServerManager.dataBase().removeAllObservers()
    }
    
    func deleteEventWithGamepin(gamepinToRemove: String) {
        MOONLog("Gamepin to remove: \(gamepinToRemove)")
        ServerManager.dataBase().childByAppendingPath(FireBaseKeys.GameSessionsKey).childByAppendingPath("simplelogin:\(gamepinToRemove)").removeValue()
    }
}

