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
    
//    func gameBrain<T: Evolvable>(gameBrain: GameBrain<T>, didPerformActions actions: [MoveAction<T>])
//    func performActions<T: Evolvable>(actions: [MoveAction<T>])
    func gameBrainDidPerformActions(actions: [MoveAction<D>])

//    func gameBrain<T: Evolvable>(gameBrain: GameBrain<T>, userHasNewScore newScore: Int)
//    func gameBrain<T: Evolvable>(gameBrain: GameBrain<T>, oppenentHasNewScore newScore: Int)
//    func userHasNewScore(newUserScore: Int)
//    func opponentHasNewScore(newOpponentScore: Int)
    func gameBrainUserHasNewScore(newUserScore: Int)
    func gameBrainOpponentHasNewScore(newOpponentScore: Int)
    
//    func gameBrain<T: Evolvable>(gameBrain: GameBrain<T>, didChangeTurnTo currentTurn: Turn)
//    func usersTurn()
//    func opponentsTurn()
    func gameBrainDidChangeTurnTo(currentTurn: Turn)

}

enum Turn {
    case User
    case Opponent
}



//class GameBrain<EvolvableType: Evolvable>: GameBoardDelegate {
class GameBrain<E: GameBrainDelegate>: GameBoardDelegate {

//    typealias GameBoardDelegateEvolvableType = GameBrainDelegateType.GameBrainDelegateEvolvableType
//    typealias E = GameBrainDelegateType.GameBrainDelegateEvolvableType

    typealias F = E.D
    typealias A = F
    
    private var userScore = 0
    private var opponentScore = 0
    private var gameBoard: GameBoard<GameBrain> // Might have to turn this into GameBoard<GameBrain<E>>
    private weak var delegate: E?
    
    private(set) var currentPlayer: Turn = Turn.User {
        didSet {
            
//            self.delegate?.gameBrain(self, didChangeTurnTo: currentPlayer)
            self.delegate?.gameBrainDidChangeTurnTo(self.currentPlayer)
        }
    }
    
    
    init(delegate: E?, dimension: Int) {
        self.delegate = delegate
        
        self.gameBoard = GameBoard<GameBrain>(dimension: dimension)
        self.gameBoard.delegate = self
    } 
    
    func startGame() {
        self.gameBoard.spawnNewGamePieceAtRandomPosition()
        self.gameBoard.spawnNewGamePieceAtRandomPosition()
    }
    
    func moveInDirection(direction: MoveDirection) {
        self.gameBoard.moveInDirection(direction)
        self.gameBoard.spawnNewGamePieceAtRandomPosition()
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Board Delegate Methods
    // -------------------------------
    
//    func gameBoard(board: GameBoard<T>, didPerformActions actions: [MoveAction<T>]) {
    func gameBoardDidPerformActions(actions: [MoveAction<F>]) {
//        self.delegate?.performActions(actions)
//        self.delegate?.gameBrain(self, didPerformActions: actions)
        self.delegate?.gameBrainDidPerformActions(actions)
    }
    
//    func gameBoardl(board: GameBoard<T>, didCalculateScoreIncrease scoreIncrease: Int) {
    func gameBoardDidCalculateScoreIncrease(scoreIncrease: Int) {
        switch self.currentPlayer {
        case .User:
            self.userScore += scoreIncrease
//            self.delegate?.userHasNewScore(self.userScore)
//            self.delegate?.gameBrain(self, userHasNewScore: self.userScore)
            self.delegate?.gameBrainUserHasNewScore(self.userScore)
        case .Opponent:
            self.opponentScore += scoreIncrease
//            self.delegate?.opponentHasNewScore(self.opponentScore)
//            self.delegate?.gameBrain(self, oppenentHasNewScore: self.opponentScore)
            self.delegate?.gameBrainOpponentHasNewScore(self.opponentScore)
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