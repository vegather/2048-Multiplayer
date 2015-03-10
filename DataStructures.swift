//
//  DataStructures.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 28/02/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

enum MoveDirection: Printable {
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

protocol Evolvable: Equatable, Printable {
    func evolve() -> Self?
    class func getBaseValue() -> Self
    var scoreValue: Int { get } // The score increase that this piece should amount to
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
        default:                                            return nil
        }
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
            return "\(self.rawValue)"
        }
    }
}

// Operator from the Equatable protocol which TileValue conforms to has to be defined globally
func ==(lhs: TileValue, rhs: TileValue) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

struct Coordinate: Printable {
    let x: Int
    let y: Int
    
    var description: String {
        get {
            return "Coordinate(x: \(x), y: \(y))"
        }
    }
}

// This class should preferable by a struct, but Swift currently can't handle generic enums (see MoveAction)
// that have more than one associated value if one of the values are of the generic type. Having this be a 
// class works because it is a reference type, and pointers have a fixed size. The size of copied types 
// (like structs and enums) can't be determined at compile time. Should change this back to a struct as soon 
//  as Apple implements "non-fixed multi-payload enum layout"
class GamePiece<T: Evolvable>: Printable {
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
enum MoveAction<T: Evolvable>: Printable {
    case Spawn(position: Coordinate, value: T) // Spawns a new tile
    case Move(from: Coordinate, to: Coordinate) // Moves a tile
    case Merge(from: Coordinate, andFrom: Coordinate, toGamePiece: GamePiece<T>) // Merge two tiles
    
    var description: String {
        get {
            switch self {
            case let .Spawn(position, value):
                return "Spawn(position: \(position), value: \(value)"
            case let .Move(from, to):
                return "Move(from: \(from), to: \(to))"
            case let .Merge(from, to, toGamePiece):
                return "Merge(from: \(from), and: \(to), toGamePiece: \(toGamePiece))"
            }
        }
    }
}


