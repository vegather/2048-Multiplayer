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

struct FireBaseKeys {
    static let GameSessionsKey  = "GameSessions"
    static let UsersKey         = "Users"
    struct Users {
        static let DisplayName  = "DisplayName"
        static let Email        = "Email"
    }
}

struct GameKeys {
    static let BoardSizeKey     = "BoardSize"
    static let TurnDurationKey  = "TurnDuration"
    static let LastMoveKey      = "LastMove"
    static let OpponentKey      = "Opponent"
    static let InitialStateKey  = "InitialState"
    
    struct InitialState {
        static let Tile1Key     = "Tile1"
        static let Tile2Key     = "Tile2"
        
        struct Tile {
            static let PositionKey  = "Position"
            static let ValueKey     = "Value"
        }
    }
    
    struct LastMove {
        static let MoveDirectionKey = "MoveDirection"
        static let UpdaterKey       = "Updater"
        static let NewTileKey       = "NewTile"
        
        struct NewTile {
            static let PositionKey  = "Position"
            static let ValueKey     = "Value"
        }
    }
}

struct Direction {
    static let Up       = "Up"
    static let Down     = "Down"
    static let Left     = "Left"
    static let Right    = "Right"
}





class ServerManager {
    class func dataBase() -> Firebase {
        return Firebase(url: FIREBASE_URL)
    }
}
