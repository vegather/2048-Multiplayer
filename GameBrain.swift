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
    
    typealias D: Evolvable
    
    func gameBrainDidProduceActions(actions: [MoveAction<D>])
    func gameBrainUserHasNewScore(newUserScore: Int)
    func gameBrainOpponentHasNewScore(newOpponentScore: Int)
    func gameBrainDidChangeTurnTo(currentTurn: Turn)

}

enum Turn {
    case User
    case Opponent
}

class GameBrain<E: GameBrainDelegate>: GameBoardDelegate {

    typealias F = E.D
    typealias A = F
    
    private var userScore = 0
    private var opponentScore = 0
    private var gameBoard: GameBoard<GameBrain> // Might have to turn this into GameBoard<GameBrain<E>>
    private weak var delegate: E?
    
    private(set) var currentPlayer: Turn = Turn.User {
        didSet {
            self.delegate?.gameBrainDidChangeTurnTo(self.currentPlayer)
        }
    }
    
    
    init(delegate: E?, dimension: Int) {
        self.delegate = delegate
        
        self.gameBoard = GameBoard<GameBrain>(dimension: dimension)
        self.gameBoard.delegate = self
    } 
    
    func startGame() {
        MWLog()
        self.gameBoard.spawnNewGamePieceAtRandomPosition()
        self.gameBoard.spawnNewGamePieceAtRandomPosition()
    }
    
    func moveInDirection(direction: MoveDirection) {
        self.gameBoard.moveInDirection(direction)
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Board Delegate Methods
    // -------------------------------
    
    func gameBoardDidProduceActionsFromMoveInDirection(actions: [MoveAction<F>]) {
        if actions.count > 0 {
            MWLog("Letting delegate know about \(actions.count) new actions")
            self.delegate?.gameBrainDidProduceActions(actions)
            self.gameBoard.spawnNewGamePieceAtRandomPosition()
        }
    }
    
    func gameBoardDidSpawnNodesWithActions(spawnActions: [MoveAction<A>]) {
        if spawnActions.count > 0 {
            self.delegate?.gameBrainDidProduceActions(spawnActions)
        }
    }
    
    func gameBoardDidCalculateScoreIncrease(scoreIncrease: Int) {
        switch self.currentPlayer {
        case .User:
            self.userScore += scoreIncrease
            self.delegate?.gameBrainUserHasNewScore(self.userScore)
        case .Opponent:
            self.opponentScore += scoreIncrease
            self.delegate?.gameBrainOpponentHasNewScore(self.opponentScore)
        }
    }

}