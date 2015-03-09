//
//  GameBrain.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 28/02/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

// After a call to moveInDirection(...), moveTileFromCoordinate will be called
// repeatedly until all the tiles that require moving have been moved.
// After that, any tiles that should merge will be on top of each other.
// For these tiles, mergeTilesAtCoordinate will be called.
protocol GameBrainDelegate: class {
//    func spawnTile(tile: Tile)
//    func moveTileFromCoordinate(from: Coordinate, toCoordinate to: Coordinate)
//    func mergeTilesAtCoordinate(coordinate: Coordinate)
    
    func performActions<T: Evolvable>(actions: [MoveAction<T>])
    
    func userHasNewScore(newUserScore: Int)
    func opponentHasNewScore(newOpponentScore: Int)
    
    func usersTurn()
    func opponentsTurn()
}

class GameBrain: GameBoardDelegate {
 
    private enum Turn {
        case User
        case Opponent
    }
    
    private var userScore = 0
    private var opponentScore = 0
    private var currentPlayer = Turn.User
    
    private var gameBoard: GameBoard<TileValue>?
    private weak var delegate: GameBrainDelegate?
    
    init(delegate: GameBrainDelegate, dimension: Int) {
        self.delegate = delegate
        self.gameBoard = GameBoard<TileValue>(delegate: self, dimension: dimension)
    } 
    
    func moveInDirection(direction: MoveDirection) {
        
    }
    
    
    // -------------------------------
    // MARK: Game Board Delegate Methods
    // -------------------------------
    
    func spawnedGamePiece<T: Evolvable>(#position: Coordinate, value: T) {
        
    }
    
    func performedActions<T: Evolvable>(actions: [MoveAction<T>]) {
        
    }
    
    func updateScoreBy(scoreIncrement: Int) {
        
    }
}