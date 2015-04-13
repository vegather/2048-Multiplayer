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
    
    func gameBrainWillCreateMultiplayerGame()
    func gameBrainDidCreateMultiplayerGameWithGamepin(gamePin: String)
    
    func gameBrainDidCreateSinglePlayerGame()
    
    func gameBrainDidGetOpponentNamed(opponentName: String)

}

enum Turn {
    case User
    case Opponent
}

class GameBrain<E: GameBrainDelegate>: GameDelegate, GameCreatorDelegate, GameBoardDelegate {

    typealias F = E.D
    typealias A = F
    
    private var userScore = 0
    private var opponentScore = 0
    private weak var delegate: E?
    private var gameBoard: GameBoard<GameBrain>!// { // Might have to turn this into GameBoard<GameBrain<E>>
//        didSet {
//            gameBoard.delegate = self
//        }
    // }
    
    private var gameServer = GameServerManager()
    private var gameSetup: GameSetup<F>!
    
    private(set) var currentPlayer: Turn = Turn.User {
        didSet {
            self.delegate?.gameBrainDidChangeTurnTo(self.currentPlayer)
        }
    }
    
    
    init(delegate: E?) {
        self.delegate = delegate
        self.gameServer.gameDelegate = self
    } 
    
//    func startGame() {
//        MWLog()
//        self.gameBoard.spawnNewGamePieceAtRandomPosition()
//        self.gameBoard.spawnNewGamePieceAtRandomPosition()
//    }
    
    func moveInDirection(direction: MoveDirection) {
        let (scoreIncrease: Int, actions: [MoveAction<F>]) = self.gameBoard.moveInDirection(direction)
        let spawn   = self.gameBoard.spawnNewGamePieceAtRandomPosition()
        
        self.delegate?.gameBrainDidProduceActions(actions)
        self.delegate?.gameBrainDidProduceActions([spawn])
        
        if currentPlayer == Turn.User {
            userScore += scoreIncrease
            self.delegate?.gameBrainUserHasNewScore(userScore)
        } else {
            opponentScore += scoreIncrease
            self.delegate?.gameBrainOpponentHasNewScore(opponentScore)
        }
        
        
        if gameSetup.players == Players.Multi {
            
            // Change currentPlayer
            if currentPlayer == Turn.User {
                currentPlayer = Turn.Opponent
            } else {
                currentPlayer = Turn.User
            }
            
            // Have to do switch case to unwrap associated value
            switch spawn {
            case let .Spawn(gamePiece):
                gameServer.performedMoveInDirection(direction,
                    whichSpawnedTile: gamePiece.value,
                    atCoordinate: gamePiece.position)
            default: break
            }
        }
 
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Board Delegate Methods
    // -------------------------------
//    func gameBoardDidSpawnNodesWithAction(spawnAction: MoveAction<A>) {
//        switch spawnAction {
//        case let .Spawn(gamePiece):
//            if self.gameSetup.firstTile == nil {
//                MWLog("Setting the gameSetups firstTile to \(gamePiece)")
//                self.gameSetup.firstTile = gamePiece.value as! TileValue
//                self.gameSetup.firstCoordinate = gamePiece.position
//            } else if self.gameSetup.secondTile == nil {
//                MWLog("Setting the gameSetups secondTile to \(gamePiece)")
//                self.gameSetup.secondTile = gamePiece.value as! TileValue
//                self.gameSetup.secondCoordinate = gamePiece.position
//                self.finis⌘hSetup()
//            } else {
//                self.delegate?.gameBrainDidProduceActions([spawnAction])
//            }
//        default:
//            MWLog("Not a Spawn action")
//        }
//    }
//    
//    func gameBoardDidCalculateScoreIncrease(scoreIncrease: Int) {
//        switch self.currentPlayer {
//        case .User:
//            self.userScore += scoreIncrease
//            self.delegate?.gameBrainUserHasNewScore(self.userScore)
//        case .Opponent:
//            self.opponentScore += scoreIncrease
//            self.delegate?.gameBrainOpponentHasNewScore(self.opponentScore)
//        }
//    }
    
    
    
    // -------------------------------
    // MARK: Prepare for game
    // -------------------------------
    
    func prepareForGameWithSetup(inout gameSetup: GameSetup<F>) {
        self.gameSetup = gameSetup
        self.gameBoard = GameBoard<GameBrain>(dimension: gameSetup.dimension)
        
        if gameSetup.setupForCreating {
            MWLog("Setting up for creating")
            let firstSpawnAction  = self.gameBoard.spawnNewGamePieceAtRandomPosition()
            let secondSpawnAction = self.gameBoard.spawnNewGamePieceAtRandomPosition()
            
            // Need to do this through switch case for the moment
            switch firstSpawnAction {
            case let .Spawn(gamePiece):
                self.gameSetup.firstTile = gamePiece.value
                self.gameSetup.firstCoordinate = gamePiece.position
            default: break
            }
            
            switch secondSpawnAction {
            case let .Spawn(gamePiece):
                self.gameSetup.secondTile = gamePiece.value
                self.gameSetup.secondCoordinate = gamePiece.position
            default: break
            }
            
            if gameSetup.players == Players.Multi {
                self.delegate?.gameBrainWillCreateMultiplayerGame()
                
                self.gameServer.createGameWithDimension(gameSetup.dimension, turnDuration: gameSetup.turnDuration)
                    { (gamePin: String!, errorMessage: String?) -> () in
                        if let error = errorMessage {
                            MWLog("\(error)")
                        } else {
                            self.delegate?.gameBrainDidCreateMultiplayerGameWithGamepin(gamePin)
                        }
                    }
            } else {
                self.delegate?.gameBrainDidCreateSinglePlayerGame()
            }
            
            let spawnActions = [firstSpawnAction, secondSpawnAction]
            self.delegate?.gameBrainDidProduceActions(spawnActions)
        } else {
            MWLog("Setting up for joining")
        }
    }
    
    private func finishSetup() {
        
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Delegate
    // -------------------------------
    
    func opponentDidPerformMoveInDirection(
        direction: MoveDirection,
        whichSpawnedTile newTile: TileValue,
        atCoordinate coordinate: Coordinate)
    {
        
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Creator Delegate
    // -------------------------------
    
    func gotOpponentWithDisplayName(displayName: String) {
        
    }

}