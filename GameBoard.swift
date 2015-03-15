//
//  GameBoard.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 01/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

protocol GameBoardDelegate: class {
    typealias A: Evolvable
    
    func gameBoardDidPerformActions(actions: [MoveAction<A>])
    func gameBoardDidCalculateScoreIncrease(scoreIncrease: Int)
}

class GameBoard<B: GameBoardDelegate> {

    typealias C = B.A
    
    private var board: Array<Array<C?>>
    private let dimension: Int
    weak var delegate: B?
    
    init(dimension: Int) {
        self.dimension = dimension
        
        self.board = [[C?]](count: dimension, repeatedValue: [C?](count: dimension, repeatedValue: nil))
    }
    
    
    
    // -------------------------------
    // MARK: Moving pieces
    // -------------------------------
    
    func moveInDirection(direction: MoveDirection) {
        var resultFromMove:(Int, [MoveAction<C>])
        
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
        
        println("Board after the move in direction \(direction)")
        self.printBoard()
        
        println("Score increase: \(scoreIncrease)\n\n\n\n")
        
        self.delegate?.gameBoardDidPerformActions(moves)
        self.delegate?.gameBoardDidCalculateScoreIncrease(scoreIncrease)
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Move Left
    // -------------------------------
    
    private func moveLeft() -> (Int, [MoveAction<C>]) {
        var actions = [MoveAction<C>]()
        var score: Int = 0
        
        for row in 0..<self.dimension {
            var tempCol: Int? //Used to temporary store a column index to check for potential merging
            for col in 0..<self.dimension {
                if let currentPiece: C = self.board[row][col] { // If there is a piece at this position
                    if let temp = tempCol { // If we have a temporary index stored
                        if currentPiece == self.board[row][temp] {
                            // Merge
                            
                            let leftmostCol = self.findLeftmostColToTheRightOf(Coordinate(x: temp, y: row))
                            
                            // Create a MoveAction.Merge that have sources [row][temp] and [row][col] and ends up in [row][leftmost]
                            if let newValue = currentPiece.evolve() {
                                let newPiece = GamePiece<C>(value: newValue, position: Coordinate(x: leftmostCol, y: row))
                                actions.append(MoveAction.Merge(from: Coordinate(x: temp, y: row),
                                                             andFrom: Coordinate(x: col,   y: row),
                                                         toGamePiece: newPiece))
                                score += newValue.scoreValue
                            }
                            
                            // Update board
                            self.board[row][leftmostCol] = self.board[row][col]?.evolve()
                            self.board[row][col] = nil
                            
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
                        // Hit the right edge while searching for a piece to merge with
                        
                        if let moveAction = self.movePieceAsFarLeftAsPossibleFrom(Coordinate(x: temp, y: row)) {
                            actions.append(moveAction)
                        }
                    }
                }
            }
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarLeftAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let leftmostCol = self.findLeftmostColToTheRightOf(fromCoordinate)
        
        if leftmostCol != fromCoordinate.x { // If it could even move
            if let pieceToMove = self.board[fromCoordinate.y][fromCoordinate.x] {
                returnValue = MoveAction.Move(from: fromCoordinate, to: Coordinate(x: leftmostCol, y: fromCoordinate.y))
                
                // Update board
                self.board[fromCoordinate.y][leftmostCol] = self.board[fromCoordinate.y][fromCoordinate.x]
                self.board[fromCoordinate.y][fromCoordinate.x] = nil
            }
        }
        
        return returnValue
    }
    
    private func findLeftmostColToTheRightOf(start: Coordinate) -> Int {
        var leftmostCol = start.x - 1
        while leftmostCol >= 0 && self.board[start.y][leftmostCol] == nil {
            leftmostCol--
        }
        leftmostCol++ // leftmostCol is now either on another tile, or -1 (just off the edge) so I need to increment it
        
        return leftmostCol
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Move Right
    // -------------------------------
    
    private func moveRight() -> (Int, [MoveAction<C>]) {
        var actions = [MoveAction<C>]()
        var score: Int = 0
        
        for row in 0..<self.dimension {
            var tempCol:  Int? //Used to temporary store a column index to check for potential merging
            for var col = self.dimension - 1; col >= 0; col-- {
                if let currentPiece: C = self.board[row][col] { // If there is a piece at this position
                    if let temp = tempCol { // If we have a temporary index stored
                        if currentPiece == self.board[row][temp] {
                            // Merge
                            
                            let rightmostCol = self.findRightmostColToTheRightOf(Coordinate(x: temp, y: row))
                            
                            // Create a MoveAction.Merge that have sources [row][temp] and [row][col] and ends up in [row][leftmost]
                            if let newValue = currentPiece.evolve() {
                                let newPiece = GamePiece<C>(value: newValue, position: Coordinate(x: rightmostCol, y: row))
                                let merge = MoveAction.Merge(from: Coordinate(x: temp, y: row),
                                                          andFrom: Coordinate(x: col,   y: row),
                                                      toGamePiece: newPiece)
                                actions.append(merge)
                                
                                score += newValue.scoreValue
                            }
                            
                            // Update board
                            self.board[row][rightmostCol] = self.board[row][col]?.evolve()
                            self.board[row][col] = nil
                            
                            // If we are on the leftmost edge, we don't want to set this to
                            // nil because we just set it to the evolved value
                            if rightmostCol != temp {
                                self.board[row][temp] = nil
                            }
                            
                            tempCol = nil
                            
                        } else {
                            if let moveAction = self.movePieceAsFarRightAsPossibleFrom(Coordinate(x: temp, y: row)) {
                                actions.append(moveAction)
                            }
                            
                            tempCol = col // Whatever was tempCol previously did not result in a merge. Trying again with the current col.
                        }
                    } else {
                        if col == 0 {
                            // Currently on the left edge. No need to store this to check for merging. Can just move it
                            if let moveAction = self.movePieceAsFarRightAsPossibleFrom(Coordinate(x: col, y: row)) {
                                actions.append(moveAction)
                            }
                        } else {
                            tempCol = col
                        }
                    }
                } else if let temp = tempCol {
                    if col == 0 {
                        // Hit the left edge while searching for a piece to merge with
                        
                        if let moveAction = self.movePieceAsFarRightAsPossibleFrom(Coordinate(x: temp, y: row)) {
                            actions.append(moveAction)
                        }
                    }
                }
            }
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarRightAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let rightmostCol = self.findRightmostColToTheRightOf(fromCoordinate)
        
        if rightmostCol != fromCoordinate.x { // If it could even move
            if let pieceToMove = self.board[fromCoordinate.y][fromCoordinate.x] {
                returnValue = MoveAction.Move(from: fromCoordinate,
                    to: Coordinate(x: rightmostCol, y: fromCoordinate.y))
                
                // Update board
                self.board[fromCoordinate.y][rightmostCol] = self.board[fromCoordinate.y][fromCoordinate.x]
                self.board[fromCoordinate.y][fromCoordinate.x] = nil
            }
        }
        
        return returnValue
    }
    
    private func findRightmostColToTheRightOf(start: Coordinate) -> Int {
        var rightmostCol = start.x + 1
        while rightmostCol < self.dimension && self.board[start.y][rightmostCol] == nil {
            rightmostCol++
        }
        rightmostCol-- // rightmostCol is now either on another tile, or self.dimension (just off the edge) so I need to decrement it
        
        return rightmostCol
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Move Up
    // -------------------------------
    
    private func moveUp() -> (Int, [MoveAction<C>]) {
        var actions = [MoveAction<C>]()
        var score: Int = 0
        
        for col in 0..<self.dimension {
            var tempRow: Int? //Used to temporary store a row index to check for potential merging
            for row in 0..<self.dimension {
                if let currentPiece: C = self.board[row][col] { // If there is a piece at this position
                    if let temp = tempRow { // If we have a temporary index stored
                        if currentPiece == self.board[temp][col] {
                            // Merge
                            
                            let upmostRow = self.findUpmostRowUpwardsFrom(Coordinate(x: col, y: temp))
                            
                            if let newValue = currentPiece.evolve() {
                                let newPiece = GamePiece<C>(value: newValue, position: Coordinate(x: col, y: upmostRow))
                                actions.append(MoveAction.Merge(from: Coordinate(x: col, y: temp),
                                                             andFrom: Coordinate(x: col, y: row),
                                                         toGamePiece: newPiece))
                                score += newValue.scoreValue
                            }
                            
                            // Update board
                            self.board[upmostRow][col] = self.board[row][col]?.evolve()
                            self.board[row][col] = nil
                            
                            if upmostRow != temp {
                                self.board[temp][col] = nil
                            }
                            
                            tempRow = nil
                            
                        } else {
                            if let moveAction = self.movePieceAsFarUpAsPossibleFrom(Coordinate(x: col, y: temp)) {
                                actions.append(moveAction)
                            }
                            
                            tempRow = row
                        }
                    } else {
                        if row == self.dimension - 1 {
                            // Currently on the bottom edge. No need to store this to check for merging. Can just move it
                            if let moveAction = self.movePieceAsFarUpAsPossibleFrom(Coordinate(x: col, y: row)) {
                                actions.append(moveAction)
                            }
                        } else {
                            tempRow = row
                        }
                    }
                } else if let temp = tempRow {
                    if row == self.dimension - 1 {
                        // Hit the bottom edge while searching for a piece to merge with
                        if let moveAction = self.movePieceAsFarUpAsPossibleFrom(Coordinate(x: col, y: temp)) {
                            actions.append(moveAction)
                        }
                    }
                }
            }
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarUpAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let upmostRow = self.findUpmostRowUpwardsFrom(fromCoordinate)
        
        if upmostRow != fromCoordinate.y { // If it could even move
            if let pieceToMove = self.board[fromCoordinate.y][fromCoordinate.x] {
                returnValue = MoveAction.Move(from: fromCoordinate, to: Coordinate(x: fromCoordinate.x, y: upmostRow))
                
                // Update board
                self.board[upmostRow][fromCoordinate.x] = self.board[fromCoordinate.y][fromCoordinate.x]
                self.board[fromCoordinate.y][fromCoordinate.x] = nil
            }
        }
        
        return returnValue
    }
    
    private func findUpmostRowUpwardsFrom(start: Coordinate) -> Int {
        var upmostRow = start.y - 1
        while upmostRow >= 0 && self.board[upmostRow][start.x] == nil {
            upmostRow--
        }
        upmostRow++
        
        return upmostRow
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Move Down
    // -------------------------------
    
    private func moveDown() -> (Int, [MoveAction<C>]) {
        var actions = [MoveAction<C>]()
        var score: Int = 0
        
        for col in 0..<self.dimension {
            var tempRow: Int? //Used to temporary store a row index to check for potential merging
            for var row = self.dimension - 1; row >= 0; row-- {
                if let currentPiece: C = self.board[row][col] { // If there is a piece at this position
                    if let temp = tempRow { // If we have a temporary index stored
                        if currentPiece == self.board[temp][col] {
                            // Merge
                            
                            let downmostRow = self.findDownmostRowDownwardsFrom(Coordinate(x: col, y: temp))
                            
                            if let newValue = currentPiece.evolve() {
                                let newPiece = GamePiece<C>(value: newValue, position: Coordinate(x: col, y: downmostRow))
                                let merge = MoveAction.Merge(from: Coordinate(x: col, y: temp),
                                                          andFrom: Coordinate(x: col, y: row),
                                                      toGamePiece: newPiece)
                                actions.append(merge)
                                
                                score += newValue.scoreValue
                            }
                            
                            // Update board
                            self.board[downmostRow][col] = self.board[row][col]?.evolve()
                            self.board[row][col] = nil
                            
                            if downmostRow != temp {
                                self.board[temp][col] = nil
                            }
                            
                            tempRow = nil
                            
                        } else {
                            if let moveAction = self.movePieceAsFarDownAsPossibleFrom(Coordinate(x: col, y: temp)) {
                                actions.append(moveAction)
                            }
                            
                            tempRow = row // Whatever was tempRow previously did not result in a merge. Trying again with the current row.
                        }
                    } else {
                        if row == 0 {
                            // Currently on the bottom edge. No need to store this to check for merging. Can just move it
                            if let moveAction = self.movePieceAsFarDownAsPossibleFrom(Coordinate(x: col, y: row)) {
                                actions.append(moveAction)
                            }
                        } else {
                            tempRow = row
                        }
                    }
                } else if let temp = tempRow {
                    if row == 0 {
                        // Hit the top edge while searching for a piece to merge with
                        
                        if let moveAction = self.movePieceAsFarDownAsPossibleFrom(Coordinate(x: col, y: temp)) {
                            actions.append(moveAction)
                        }
                    }
                }
            }
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarDownAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let downmostRow = self.findDownmostRowDownwardsFrom(fromCoordinate)
        
        if downmostRow != fromCoordinate.y {
            if let pieceToMove = self.board[fromCoordinate.y][fromCoordinate.x] {
                returnValue = MoveAction.Move(from: fromCoordinate, to: Coordinate(x: fromCoordinate.x, y: downmostRow))
                
                // Update board
                self.board[downmostRow][fromCoordinate.x] = self.board[fromCoordinate.y][fromCoordinate.x]
                self.board[fromCoordinate.y][fromCoordinate.x] = nil
            }
        }
        
        return returnValue
    }
    
    private func findDownmostRowDownwardsFrom(start: Coordinate) -> Int {
        var downmostRow = start.y + 1
        while downmostRow < self.dimension && self.board[downmostRow][start.x] == nil {
            downmostRow++
        }
        downmostRow--
        
        return downmostRow
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
                    // Crashes when the board is full
                    emptySpots.append(Coordinate(x: col, y: row))
                }
            }
        }
        
        let indexOfSpot = Int(arc4random()) % emptySpots.count
        
        let spot = emptySpots[indexOfSpot]
        let value = C.getBaseValue()
        
        self.board[spot.y][spot.x] = value
        
        let spawnAction = [MoveAction.Spawn(gamePiece: GamePiece(value: value, position: spot))]
        self.delegate?.gameBoardDidPerformActions(spawnAction)
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
                    print("- ")
                }
            }
            println()
        }
    }
    
}

