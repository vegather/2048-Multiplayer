//
//  GameBoard.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 01/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

protocol GameBoardDelegate: class {
    func spawnedGamePiece<T: Evolvable>(#position: Coordinate, value: T)
    func performedActions<T: Evolvable>(actions: [MoveAction<T>])
    func updateScoreBy(scoreIncrement: Int)
}

class GameBoard<T: Evolvable> {
    
    private var board: Array<Array<T?>>
    private let dimension: Int
    weak private var delegate: GameBoardDelegate?
    
    init(delegate: GameBoardDelegate, dimension: Int) {
        self.delegate = delegate
        self.dimension = dimension
        
        self.board = [[T?]](count: dimension, repeatedValue: [T?](count: dimension, repeatedValue: nil))
    }
    
    
    
    // -------------------------------
    // MARK: Moving pieces
    // -------------------------------
    
    func moveInDirection(direction: MoveDirection) {
        var resultFromMove:(Int, [MoveAction<T>])
        
        println("Board before moving")
        self.printBoard()
        
        switch direction {
        case .Left:
            resultFromMove = moveLeft()
        case .Right:
            resultFromMove = moveRight()
        case .Up:
            resultFromMove = moveUp()
        case .Down:
            resultFromMove = moveDown()
        }
        
        let (scoreIncrease, moves) = resultFromMove
        println()
//
//        for action: MoveAction<T> in moves {
//            println("GameBoard - Action: \(action)")
//        }
        
        println("Board after the move in direction \(direction)")
        self.printBoard()
        
        println("Score increase: \(scoreIncrease)\n\n")
        
//        self.delegate?.performedActions(moves)
//        self.delegate?.updateScoreBy(scoreIncrease)
    }
    
    private func moveLeft() -> (Int, [MoveAction<T>]) {
        var actions = [MoveAction<T>]()
        var score: Int = 0
        
        for row in 0..<self.dimension {
            var tempCol:  Int? //Used to temporary store a column index to check for potential merging
            for col in 0..<self.dimension {
                if let currentTile: T = self.board[row][col] {
                    if let temp = tempCol {
                        if currentTile == self.board[row][temp] {
                            // Merge
                            
                            // Find the leftmost available position
                            var leftmostCol = temp - 1
                            while leftmostCol >= 0 && self.board[row][leftmostCol] == nil {
                                leftmostCol--
                            }
                            leftmostCol++ // leftmostCol is now either on another tile, or -1 (just off the edge) so I need to increment it
                            
                            // Create a MoveAction.Merge that have sources [row][temp] and [row][col] and ends up in [row][leftmost]
                            if let newValue = currentTile.evolve() {
                                let newPiece = GamePiece<T>(value: newValue, position: Coordinate(x: leftmostCol, y: row))
                                actions.append(MoveAction.Merge(from: Coordinate(x: temp, y: row),
                                                             andFrom: Coordinate(x: col,   y: row),
                                                         toGamePiece: newPiece))
                                score += newValue.scoreValue
                            }
                            
                            // Update board
                            self.board[row][leftmostCol] = self.board[row][col]?.evolve()
                            self.board[row][col]  = nil
                            
                            // If we are on the leftmost edge, we don't want to set this to 
                            // nil because we just set it to the evolved value
                            if leftmostCol != temp {
                                self.board[row][temp] = nil
                            }
                            
                            tempCol = nil
                            
                        } else {
                            if let moveAction = self.movePieceAsFarLeftAsPossibleFrom(Coordinate(x: temp, y: row)) {
                                actions.append(moveAction)
                            }
                            
                            tempCol = col // Whatever was tempCol previously did not result in a merge. Trying again with the current col.
                        }
                    } else {
                        if col == self.dimension - 1 {
                            // Currently on the right edge. No need to store this to check for merging. Can just move it
                            if let moveAction = self.movePieceAsFarLeftAsPossibleFrom(Coordinate(x: col, y: row)) {
                                actions.append(moveAction)
                            }
                        } else {
                            tempCol = col
                        }
                    }
                } else if let temp = tempCol {
                    if col == self.dimension - 1 {
                        // Hit the edge while searching for a piece to merge with
                        
                        if let moveAction = self.movePieceAsFarLeftAsPossibleFrom(Coordinate(x: temp, y: row)) {
                            actions.append(moveAction)
                        }
                    }
                }
            }
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarLeftAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<T>? {
        
        var returnValue: MoveAction<T>? = nil
        
        var leftmostCol = fromCoordinate.x - 1
        while leftmostCol >= 0 && self.board[fromCoordinate.y][leftmostCol] == nil {
            leftmostCol--
        }
        leftmostCol++ // leftmostCol is now either on another tile, or -1 (just off the edge) so I need to increment it
        
        if leftmostCol != fromCoordinate.x { // If it could even move
            
            returnValue = MoveAction.Move(from: fromCoordinate,
                                            to: Coordinate(x: leftmostCol, y: fromCoordinate.y))
            
            // Update board
            self.board[fromCoordinate.y][leftmostCol] = self.board[fromCoordinate.y][fromCoordinate.x]
            self.board[fromCoordinate.y][fromCoordinate.x] = nil
        }
        
        return returnValue
    }
    
    private func moveRight() -> (Int, [MoveAction<T>]) {
        var actions = [MoveAction<T>]()
        
        for row in 0..<self.dimension {
            var tempCol:  Int? //Used to temporary store a column index to check for potential merging
            for col in self.dimension-1...0 {
                if let currentTile: T = self.board[row][col] {
                    
                    if let temp = tempCol {
                        if currentTile == self.board[row][temp] {
                            // Merge
                            
                            // Find the rightmost available position
                            var rightmostCol = temp + 1
                            while rightmostCol < self.dimension && self.board[row][rightmostCol] != nil {
                                rightmostCol++
                            }
                            rightmostCol-- // rightmostCol is now either on another tile, or self.dimension (just off the edge) so I need to decrement it
                            
                            // Create a MoveAction.Merge that have sources [row][temp] and [row][col] and ends up in [row][leftmost]
                            if let newValue = currentTile.evolve() {
                                let newPiece = GamePiece<T>(value: newValue, position: Coordinate(x: rightmostCol, y: row))
                                actions.append(MoveAction.Merge(from: Coordinate(x: temp, y: row),
                                                             andFrom: Coordinate(x: col,   y: row),
                                                         toGamePiece: newPiece))
                            }
                            
                            // Update board
                            self.board[row][rightmostCol] = self.board[row][col]?.evolve()
                            self.board[row][col]   = nil
                            self.board[row][temp] = nil
                            
                        } else {
                            
                            // Find the rightmost available position
                            var rightmostCol = temp + 1
                            while rightmostCol < self.dimension && self.board[row][rightmostCol] != nil {
                                rightmostCol++
                            }
                            rightmostCol-- // rightmostCol is now either on another tile, or self.dimension (just off the edge) so I need to decrement it
                            
                            if rightmostCol != temp { // If it could even move
                                actions.append(MoveAction.Move(from: Coordinate(x: temp,        y: row),
                                                                 to: Coordinate(x: rightmostCol, y: row)))
                            }
                            
                            // Update board
                            self.board[row][rightmostCol] = self.board[row][temp]
                            self.board[row][temp] = nil
                            
                            tempCol = col // Whatever was tempCol previously did not result in a merge. Trying again with the current col.
                        }
                    } else {
                        tempCol = col
                    }
                    
                }
            }
        }

        
        return (0, actions)
    }
    
    private func moveUp() -> (Int, [MoveAction<T>]) {
        var actions = [MoveAction<T>]()
        
        
        
        return (0, actions)
    }
    
    private func moveDown() -> (Int, [MoveAction<T>]) {
        var actions = [MoveAction<T>]()
        
        
        
        return (0, actions)
    }
    
    
    
    
    // -------------------------------
    // MARK: Spawning new pieces
    // -------------------------------
    
    // Will do nothing if there are no empty spots on the board
    func spawnNewGamePieceAtRandomPosition() {
        var emptySpots = [Coordinate]()
        
        for row in 0..<self.dimension {
            for col in 0..<self.dimension {
                if self.board[row][col] == nil {
                    emptySpots.append(Coordinate(x: col, y: row))
                }
            }
        }
        
        let indexOfSpot = Int(arc4random()) % emptySpots.count
        
        let spot = emptySpots[indexOfSpot]
        let value = T.getBaseValue()
        
//        println("GameBoard - Spawning piece of value: \(value) to spot \(spot)")
        
        self.board[spot.y][spot.x] = value
        
//        println("Board after spawn:")
//        self.printBoard()
        
        self.delegate?.spawnedGamePiece(position: spot, value: value)
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helper Methods
    // -------------------------------
    
    private func printBoard() {
        for row in 0..<self.dimension {
            for col in 0..<self.dimension {
                if let value = self.board[row][col] {
                    print("\(value) ")
                } else {
                    print("0 ")
                }
            }
            println()
        }
    }
    
}

