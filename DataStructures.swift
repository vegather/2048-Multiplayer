//
//  DataStructures.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 28/02/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation
import UIKit

class GameResult: CustomStringConvertible {
    var players:                Players
    var boardSize:              Int
    var turnDuration:           Int
    var won:                    Bool?   // nil means draw. Only applicable for multiplayer games
    var currentUserScore:       Int
    var opponentScore:          Int!    // Only applicable for multiplayer games
    var currentUserDisplayName: String
    var opponentDisplayName:    String! // Only applicable for multiplayer games
    var gameEndScreenshot:      UIImage
    
    // Use this for singleplayer games
    init(
        players:                Players,
        boardSize:              Int,
        turnDuration:           Int,
        currentUserScore:       Int,
        currentUserDisplayName: String,
        gameEndScreenshot:      UIImage)
    {
        self.players                = players
        self.boardSize              = boardSize
        self.turnDuration           = turnDuration
        self.currentUserScore       = currentUserScore
        self.currentUserDisplayName = currentUserDisplayName
        self.gameEndScreenshot      = gameEndScreenshot
    }
    
    // Use this for multiplayer games
    convenience init(
        players:                Players,
        boardSize:              Int,
        turnDuration:           Int,
        won:                    Bool?,
        currentUserScore:       Int,
        opponentScore:          Int,
        currentUserDisplayName: String,
        opponentDisplayName:    String,
        gameEndScreenshot:      UIImage)
    {
        self.init(
            players:                players,
            boardSize:              boardSize,
            turnDuration:           turnDuration,
            currentUserScore:       currentUserScore,
            currentUserDisplayName: currentUserDisplayName,
            gameEndScreenshot:      gameEndScreenshot)
        
        self.won = won
        self.opponentScore = opponentScore
        self.opponentDisplayName = opponentDisplayName
    }
    
    var description: String {
        get {
            return "GameResult(players: \(players), boardSize: \(boardSize), turnDuration: \(turnDuration), won: \(won), currentUserScore: \(currentUserScore), opponentScore: \(opponentScore), currentUserDisplayName: \(currentUserDisplayName), opponentDisplayName: \(opponentDisplayName), gameEndScreenShot.size: \(gameEndScreenshot.size))"
        }
    }
}

class GameSetup<T: Evolvable>: CustomStringConvertible {
    
    var players:                Players
    var setupForCreating:       Bool
    var dimension:              Int
    var turnDuration:           Int
    var firstTile:              T!
    var firstCoordinate:        Coordinate!
    var secondTile:             T!
    var secondCoordinate:       Coordinate!
    var opponentDisplayName:    String!   // Primarily used when joining a game
    var gameServer:             GameServerManager! // Primarily used when joining a game
    
    init(
        players:                Players,
        setupForCreating:       Bool,
        dimension:              Int,
        turnDuration:           Int)
    {
        self.players            = players
        self.setupForCreating   = setupForCreating
        self.dimension          = dimension
        self.turnDuration       = turnDuration
    }
    
    convenience init(
        players:                Players,
        setupForCreating:       Bool,
        dimension:              Int,
        turnDuration:           Int,
        firstValue:             T!,
        firstCoordinate:        Coordinate!,
        secondValue:            T!,
        secondCoordinate:       Coordinate!,
        opponentDisplayName:    String!,
        gameServer:             GameServerManager!)
    {
        self.init(players: players, setupForCreating: setupForCreating, dimension: dimension, turnDuration: turnDuration)
        self.firstTile              = firstValue
        self.firstCoordinate        = firstCoordinate
        self.secondTile             = secondValue
        self.secondCoordinate       = secondCoordinate
        self.opponentDisplayName    = opponentDisplayName
        self.gameServer             = gameServer
    }
    
    func isReady() -> Bool {
        return firstTile        != nil &&
               firstCoordinate  != nil &&
               secondTile       != nil &&
               secondCoordinate != nil
    }
    
    var description: String {
        get {
            return "GameSetup(players: \(players), setupForCreating: \(setupForCreating), dimension: \(dimension), turnDuration: \(turnDuration), firstTile: \(firstTile), firstCoordinate: \(firstCoordinate), secondTile: \(secondTile), secondCoordinate: \(secondCoordinate), opponentDisplayName: \(opponentDisplayName))"
        }
    }
}

enum Players: CustomStringConvertible {
    case Single
    case Multi
    
    var description: String {
        get {
            switch self {
            case .Single:
                return "Single Player"
            case .Multi:
                return "Multi Player"
            }
        }
    }
}

enum MoveDirection: CustomStringConvertible {
    case Up
    case Down
    case Left
    case Right
    
    var description: String {
        get {
            switch self {
            case .Up:
                return "Up"
            case .Down:
                return "Down"
            case .Left:
                return "Left"
            case .Right:
                return "Right"
            }
        }
    }
}

protocol Evolvable: Equatable, CustomStringConvertible {
    func evolve() -> Self?
    static func getBaseValue() -> Self  // Gets the lowest value
    var scoreValue: Int { get } // The score increase that this piece should amount to
    init(scoreValue: Int)
}

enum TileValue: Int, Evolvable {
    case Two                                            = 2
    case Four                                           = 4
    case Eight                                          = 8
    case Sixteen                                        = 16
    case ThirtyTwo                                      = 32
    case SixtyFour                                      = 64
    case OneHundredAndTwentyEight                       = 128
    case TwoHundredAndFiftySix                          = 256
    case FiveHundredAndTwelve                           = 512
    case OneThousandAndTwentyFour                       = 1024
    case TwoThousandAndFourtyEight                      = 2048
    case FourThousandAndNinetySix                       = 4096
    case EightThousandOneHundredAndNinetyTwo            = 8192
    case SixteenThousandThreeHundredAndEightyFour       = 16384
    case ThirtyTwoThousandSevenHundredAndSixtyEight     = 32768
    case SixtyFiveThousandFiveHundredAndThirtySix       = 65536
    case OneHundredAndThirtyOneThousandAndSeventyTwo    = 131072 // Seriously doubt anyone will get higher than this
    
    func evolve() -> TileValue? {
        switch self {
        case .Two:                                          return TileValue.Four
        case .Four:                                         return TileValue.Eight
        case .Eight:                                        return TileValue.Sixteen
        case .Sixteen:                                      return TileValue.ThirtyTwo
        case .ThirtyTwo:                                    return TileValue.SixtyFour
        case .SixtyFour:                                    return TileValue.OneHundredAndTwentyEight
        case .OneHundredAndTwentyEight:                     return TileValue.TwoHundredAndFiftySix
        case .TwoHundredAndFiftySix:                        return TileValue.FiveHundredAndTwelve
        case .FiveHundredAndTwelve:                         return TileValue.OneThousandAndTwentyFour
        case .OneThousandAndTwentyFour:                     return TileValue.TwoThousandAndFourtyEight
        case .TwoThousandAndFourtyEight:                    return TileValue.FourThousandAndNinetySix
        case .FourThousandAndNinetySix:                     return TileValue.EightThousandOneHundredAndNinetyTwo
        case .EightThousandOneHundredAndNinetyTwo:          return TileValue.SixteenThousandThreeHundredAndEightyFour
        case .SixteenThousandThreeHundredAndEightyFour:     return TileValue.ThirtyTwoThousandSevenHundredAndSixtyEight
        case .ThirtyTwoThousandSevenHundredAndSixtyEight:   return TileValue.SixtyFiveThousandFiveHundredAndThirtySix
        case .SixtyFiveThousandFiveHundredAndThirtySix:     return TileValue.OneHundredAndThirtyOneThousandAndSeventyTwo
        case .OneHundredAndThirtyOneThousandAndSeventyTwo:  return nil
        }
    }
    
    // Should probably be a failable initializer
    init(scoreValue: Int) {
        self = TileValue(rawValue: scoreValue)!
    }
    
    static func getBaseValue() -> TileValue {
        return TileValue.Two
    }
    
    var scoreValue: Int {
        get {
            return self.rawValue
        }
    }
    
    var description: String {
        get {
            return "TileValue(\(self.rawValue))"
        }
    }
}

// Operator from the Equatable protocol which TileValue conforms to has to be defined globally
func ==(lhs: TileValue, rhs: TileValue) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

struct Coordinate: CustomStringConvertible, Equatable {
    let x: Int
    let y: Int
    
    var description: String {
        get {
            return "Coordinate(x: \(x), y: \(y))"
        }
    }
}

// Operator from the Equatable protocol which Coordinate conforms to has to be defined globally
func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

// This class should preferable by a struct, but Swift currently can't handle generic enums (see MoveAction)
// that have more than one associated value if one of the values are of the generic type. Having this be a 
// class works because it is a reference type, and pointers have a fixed size. The size of value types 
// (like structs and enums) can't be determined at compile time. Should change this back to a struct as soon 
//  as Apple implements "non-fixed multi-payload enum layout"
class GamePiece<T: Evolvable>: CustomStringConvertible {
    let value:    T
    let position: Coordinate
    
    init(value: T, position: Coordinate) {
        self.value = value
        self.position = position
    }
    
    var description: String {
        get {
            return "GamePiece(value: \(value), position: \(position))"
        }
    }
}

// These will be generated by the GameBoard and move all the way to the view so the changes can be properly animated
enum MoveAction<T: Evolvable>: CustomStringConvertible {
    case Spawn(gamePiece: GamePiece<T>) // Spawns a new tile
    case Move(from: Coordinate, to: Coordinate) // Moves a tile
    case Merge(from: Coordinate, andFrom: Coordinate, toGamePiece: GamePiece<T>) // Merge two tiles
    
    var description: String {
        get {
            switch self {
            case let .Spawn(gamePiece):
                return "Spawn(gamePiece: \(gamePiece)"
            case let .Move(from, to):
                return "Move(from: \(from), to: \(to))"
            case let .Merge(from, to, toGamePiece):
                return "Merge(from: \(from), and: \(to), toGamePiece: \(toGamePiece))"
            }
        }
    }
}
