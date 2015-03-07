//
//  DataStructures.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 28/02/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

enum MoveDirection {
    case Up
    case Down
    case Left
    case Right
}

struct Tile {
    let value: Int;
    let position: Coordinate;
}

struct Coordinate {
    let x: Int;
    let y: Int;
}

enum TileValue: Int {
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
    case ThirtyTwoThousandSevenHundredAndSixtyEight     = 32536
    case SixtyFiveThousandFiveHundredAndThirtySix       = 65536
    case OneHundredAndThirtyOneThousandAndSeventyTwo    = 131072 // Seriously doubt anyone will get higher than this
}

enum TileAction {
    case Spawn(tile: Tile) // Spawns a new tile
    case Move(from: Coordinate, to: Coordinate) // Moves a tile
    case MoveAndEvolve(from: Coordinate, to: Coordinate) // Moves a tile and bumps it up to 
    case MoveAndDisappear(from: Coordinate, to: Coordinate)
}