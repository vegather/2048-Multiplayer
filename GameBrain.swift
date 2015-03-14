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
    func performActions<T: Evolvable>(actions: [MoveAction<T>])
    
    func userHasNewScore(newUserScore: Int)
    func opponentHasNewScore(newOpponentScore: Int)
    
    func usersTurn()
    func opponentsTurn()
}

private enum Turn {
    case User
    case Opponent
}

class GameBrain<T: Evolvable>: GameBoardDelegate {

    private var userScore = 0
    private var opponentScore = 0
    private var currentPlayer: Turn = Turn.User
    
    private var gameBoard: GameBoard<T>?
    private weak var delegate: GameBrainDelegate?
    
    init(delegate: GameBrainDelegate, dimension: Int) {
        self.delegate = delegate
        self.gameBoard = GameBoard<T>(delegate: self, dimension: dimension)
        
    } 
    
    func startGame() {
        self.gameBoard?.spawnNewGamePieceAtRandomPosition()
        self.gameBoard?.spawnNewGamePieceAtRandomPosition()
    }
    
    func moveInDirection(direction: MoveDirection) {
        self.gameBoard?.moveInDirection(direction)
        self.gameBoard?.spawnNewGamePieceAtRandomPosition()
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Board Delegate Methods
    // -------------------------------
    
    func gameBoard<T: Evolvable>(board: GameBoard<T>, didPerformActions actions: [MoveAction<T>]) {
        self.delegate?.performActions(actions)
    }
    
    func gameBoard<T: Evolvable>(board: GameBoard<T>, didCalculateScoreIncrease scoreIncrease: Int) {
        switch self.currentPlayer {
        case .User:
            self.userScore += scoreIncrease
            self.delegate?.userHasNewScore(self.userScore)
        case .Opponent:
            self.opponentScore += scoreIncrease
            self.delegate?.opponentHasNewScore(self.opponentScore)
        }
    }
    
//    func performedActions<T: Evolvable>(actions: [MoveAction<T>]) {
//        self.delegate?.performActions(actions)
//    }
//    
//    func updateScoreBy(scoreIncrement: Int) {
//        switch self.currentPlayer {
//        case .User:
//            self.userScore += scoreIncrement
//            self.delegate?.userHasNewScore(self.userScore)
//        case .Opponent:
//            self.opponentScore += scoreIncrement
//            self.delegate?.opponentHasNewScore(self.opponentScore)
//        }
//    }
}