//
//  GameBoard.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 01/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

protocol GameBoardProtocol: class {
    func spawnedTile<T: Evolvable>(position: Coordinate, value: T)
    func performedActions<T: Evolvable>(actions: [MoveAction<T>])
    func updateScoreBy(scoreIncrement: Int)
}

class GameBoard<T: Evolvable> {
    
    private var board: Array<Array<T?>>
    private let dimension: Int
    weak private var delegate: GameBoardProtocol?
    
    init(delegate: GameBoardProtocol?, dimension: Int) {
        self.delegate = delegate
        self.dimension = dimension
        
        self.board = [[T?]](count: dimension, repeatedValue: [T?](count: dimension, repeatedValue: nil))
    }
    
    
    
    // -------------------------------
    // MARK: Moving pieces
    // -------------------------------
    
    func moveInDirection(direction: MoveDirection) {
        var resultFromMove:(Int, [MoveAction<T>])
        
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
        
        let (score, moves) = resultFromMove
        println("Move to \(direction) results in \(score)")
        
        for action: MoveAction<T> in moves {
            println("Move: \(action)")
        }
    }
    
    private func moveLeft() -> (Int, [MoveAction<T>]) {
        var actions = [MoveAction<T>]()
        
        for row in 0..<self.dimension {
            var firstCol:  Int? //Used to temporary store a column index to check for potential merging
            for col in 0..<self.dimension {
                if let currentTile: T = self.board[row][col] {
                    
                    if let first = firstCol {
                        if currentTile == self.board[row][first] {
                            // Merge
                            
                            // Find the leftmost available position
                            var leftmostCol = first - 1
                            while leftmostCol >= 0 && self.board[row][leftmostCol] != nil {
                                leftmostCol--
                            }
                            leftmostCol++ // leftmostCol is now either on another tile, or -1 (just off the edge) so I need to increment it
                            
                            // Create a MoveAction.Merge that have sources [row][first] and [row][col] and ends up in [row][leftmost]
                            if let newValue = currentTile.evolve() {
                                let newPiece = GamePiece<T>(value: newValue, position: Coordinate(x: leftmostCol, y: row))
                                actions.append(MoveAction.Merge(from: Coordinate(x: first, y: row),
                                                             andFrom: Coordinate(x: col,   y: row),
                                                         toGamePiece: newPiece))
                            }
                            
                            // Update board
                            self.board[row][leftmostCol] = self.board[row][col]?.evolve()
                            self.board[row][col]   = nil
                            self.board[row][first] = nil
                            
                        } else {
                            // tempCol should now move as far left as possible
                            var leftmostCol = first - 1
                            while leftmostCol >= 0 && self.board[row][leftmostCol] != nil {
                                leftmostCol--
                            }
                            leftmostCol++ // leftmostCol is now either on another tile, or -1 (just off the edge) so I need to increment it
                            
                            if leftmostCol != first { // If it could even move
                                actions.append(MoveAction.Move(from: Coordinate(x: first,       y: row),
                                                                 to: Coordinate(x: leftmostCol, y: row)))
                            }
                            
                            // Update board
                            self.board[row][leftmostCol] = self.board[row][first]
                            self.board[row][first] = nil
                            
                            firstCol = col // Whatever was tempCol previously did not result in a merge. Trying again with the current col.
                        }
                    } else {
                        firstCol = col
                    }
                }
            }
        }
        
        return (0, actions)
    }
    
    private func moveRight() -> (Int, [MoveAction<T>]) {
        var actions = [MoveAction<T>]()
        
        for row in 0..<self.dimension {
            var firstCol:  Int? //Used to temporary store a column index to check for potential merging
            for col in self.dimension-1...0 {
                if let currentTile: T = self.board[row][col] {
                    
                    if let first = firstCol {
                        if currentTile == self.board[row][first] {
                            // Merge
                            
                            // Find the rightmost available position
                            var rightmostCol = first + 1
                            while rightmostCol < self.dimension && self.board[row][rightmostCol] != nil {
                                rightmostCol++
                            }
                            rightmostCol-- // rightmostCol is now either on another tile, or self.dimension (just off the edge) so I need to decrement it
                            
                            // Create a MoveAction.Merge that have sources [row][first] and [row][col] and ends up in [row][leftmost]
                            if let newValue = currentTile.evolve() {
                                let newPiece = GamePiece<T>(value: newValue, position: Coordinate(x: rightmostCol, y: row))
                                actions.append(MoveAction.Merge(from: Coordinate(x: first, y: row),
                                                             andFrom: Coordinate(x: col,   y: row),
                                                         toGamePiece: newPiece))
                            }
                            
                            // Update board
                            self.board[row][rightmostCol] = self.board[row][col]?.evolve()
                            self.board[row][col]   = nil
                            self.board[row][first] = nil
                            
                        } else {
                            // Find the rightmost available position
                            var rightmostCol = first + 1
                            while rightmostCol < self.dimension && self.board[row][rightmostCol] != nil {
                                rightmostCol++
                            }
                            rightmostCol-- // rightmostCol is now either on another tile, or self.dimension (just off the edge) so I need to decrement it
                            
                            if rightmostCol != first { // If it could even move
                                actions.append(MoveAction.Move(from: Coordinate(x: first,        y: row),
                                                                 to: Coordinate(x: rightmostCol, y: row)))
                            }
                            
                            // Update board
                            self.board[row][rightmostCol] = self.board[row][first]
                            self.board[row][first] = nil
                            
                            firstCol = col // Whatever was tempCol previously did not result in a merge. Trying again with the current col.
                        }
                    } else {
                        firstCol = col
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
    
    func spawnRandomGamePiece() {
        
    }
    
}