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
    func gameBrainDidJoinGame()
    
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
    
    private(set) var userScore = 0      // Public getter, private setter
    private(set) var opponentScore = 0  // Public getter, private setter
    private weak var delegate: E?
    private var gameBoard: GameBoard<GameBrain>!
    
    private var gameServer = GameServerManager()
    private var gameSetup: GameSetup<F>!
    
    private(set) var currentPlayer: Turn = Turn.User { // Public getter, private setter
        didSet {
            self.delegate?.gameBrainDidChangeTurnTo(self.currentPlayer)
        }
    }
    
    private(set) var gamePin: String? = nil { // Public getter, private setter
        didSet {
            if let gamePin = gamePin {
                self.delegate?.gameBrainDidCreateMultiplayerGameWithGamepin(gamePin)
            }
        }
    }
    
    private(set) var opponentDisplayName: String? = nil {
        didSet {
            if let opponentDisplayName = opponentDisplayName {
                self.delegate?.gameBrainDidGetOpponentNamed(opponentDisplayName)
            }
        }
    }
    
    let userDisplayName: String = UserServerManager.lastKnownCurrentUserDisplayName
    
    init(delegate: E?) {
        
        self.delegate = delegate
        self.gameServer.gameDelegate = self
        self.gameServer.creatorDelegate = self
    } 
    
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
    
    func deleteCurrentGame() {
        if let gamePin = self.gamePin {
            self.gameServer.deleteEventWithGamepin(gamePin)
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
                            MWLog("Got error from createGame: \(error)")
                        } else {
                            MWLog("Got gamePin: \(gamePin)")
                            self.gamePin = gamePin
                        }
                    }
            } else {
                self.delegate?.gameBrainDidCreateSinglePlayerGame()
            }
            
            let spawnActions = [firstSpawnAction, secondSpawnAction]
            self.delegate?.gameBrainDidProduceActions(spawnActions)
        } else {
            MWLog("Setting up for joining")
            // Setup for joining, implied that it's a Players.Multi game
            
            self.opponentDisplayName = gameSetup.opponentDisplayName
            
            // MIGHT NEED TO DO SOMETHING WITH THE TURN DURATION IN HERE
            
            let firstSpawn =  self.gameBoard.spawnNodeWithValue(gameSetup.firstTile, atCoordinate: gameSetup.firstCoordinate)
            let secondSpawn = self.gameBoard.spawnNodeWithValue(gameSetup.secondTile, atCoordinate: gameSetup.secondCoordinate)
            let spawns = [firstSpawn, secondSpawn]
            self.delegate?.gameBrainDidProduceActions(spawns)
            self.delegate?.gameBrainDidJoinGame()
        }
    }
    
    func addInitialState(tileOne: MoveAction<F>, tileTwo: MoveAction<F>) {
        
        // This is currently the only way to get associated values out of enums in Swift
        var valueOne: F! = nil
        var coordinateOne: Coordinate! = nil
        switch tileOne {
        case let .Spawn(gamePiece):
            valueOne = gamePiece.value
            coordinateOne = gamePiece.position
        default: break
        }
        
        var valueTwo: F! = nil
        var coordinateTwo: Coordinate! = nil
        switch tileTwo {
        case let .Spawn(gamePiece):
            valueTwo = gamePiece.value
            coordinateTwo = gamePiece.position
        default: break
        }
        
        gameServer.addInitialStateToCurrentGame(
            firstTile: valueOne,
            hasCoordinate: coordinateOne,
            secondTile: valueTwo,
            hasCoordinate: coordinateTwo)
            { (errorMessage: String?) -> () in
                MWLog("Got error while adding initial state to Firebase. Error Message: \(errorMessage)")
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
        self.opponentDisplayName = displayName
    }

}
