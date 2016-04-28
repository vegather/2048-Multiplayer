//
//  GameBoard.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 01/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

protocol GameBoardDelegate: class {
    associatedtype A: Evolvable
    
    // Need to separate spawn actions from the rest of the actions here so that
    // I can call spawnNewGamePieceAtRandomPosition only if any actions were produced
//    func gameBoardDidProduceActionsFromMoveInDirection(actions: [MoveAction<A>])
//    func gameBoardDidSpawnNodesWithAction(spawnAction: MoveAction<A>)
//    func gameBoardDidCalculateScoreIncrease(scoreIncrease: Int)
}

// Need to set Generics and Protocols up this way due to current limitations 
// with the current Swift compiler. Here's to Swift 2.0!
class GameBoard<B: GameBoardDelegate> {

    typealias C = B.A
    
    private var board: Array<Array<C?>>
    private let dimension: Int
    
    init(dimension: Int) {
        self.dimension = dimension
        
        self.board = [[C?]](count: dimension, repeatedValue: [C?](count: dimension, repeatedValue: nil))
    }
    
    private func isFull() -> Bool {
        var full = true // Assuming that it's full. Try to prove otherwise
        for row in 0..<self.dimension {
            for col in 0..<self.dimension {
                if self.board[row][col] == nil {
                    full = false
                    break
                }
            }
            if full == false {
                break
            }
        }
        
        return full
    }
    
    func canStillDoMove() -> Bool {
        if self.isFull() {
            var canMove = false // Assuming a move can't be done. Try to disprove this.
            
            // Check for merges horisontally
            for row in 0..<self.dimension {
                var lastValue: C?
                for col in 0..<self.dimension {
                    if let last = lastValue {
                        if let currentValue = self.board[row][col] {
                            if currentValue == last {
                                MOONLog("Horisontal merge between (\(col),\(row)) and (\(col - 1),\(row))")
                                canMove = true
                                break
                            } else {
                                lastValue = currentValue
                            }
                        }
                    } else {
                        lastValue = self.board[row][col]
                    }
                }
                
                if canMove {
                    break
                } else {
                    lastValue = nil
                }
            }
            
            // Check for merges vertically
            
            if canMove == false
            {
                for col in 0..<self.dimension {
                    var lastValue: C?
                    for row in 0..<self.dimension {
                        if let last = lastValue {
                            if let currentValue = self.board[row][col] {
                                if currentValue == last {
                                    MOONLog("Vertical merge between (\(col),\(row)) and (\(col),\(row - 1))")
                                    canMove = true
                                    break
                                } else {
                                    lastValue = currentValue
                                }
                            }
                        } else {
                            lastValue = self.board[row][col]
                        }
                    }
                    
                    if canMove {
                        break
                    } else {
                        lastValue = nil
                    }
                }
            }
            
            if canMove {
                MOONLog("The board is full, but there are still merges that can be done")
            } else {
                MOONLog("GAME OVER - The board is full, and there are no more valid moves. ")
            }
            
            return canMove
        } else {
            MOONLog("The board is not full. There are still possible moves")
            return true
        }
    }
    
    
    
    // -------------------------------
    // MARK: Moving pieces
    // -------------------------------
    
    func moveInDirection(direction: MoveDirection) -> (scoreIncrease: Int, moves: [MoveAction<C>]) {
        var resultFromMove:(Int, [MoveAction<C>])
        
        MOONLog("Board before moving")
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
        MOONLog()
        
        MOONLog("Board after the move in direction \(direction)")
        self.printBoard()
        
        MOONLog("Score increase: \(scoreIncrease)")
        
        MOONLog("Will return scoreIncrease: \(scoreIncrease), numMoves: \(moves.count)")
        
        return (scoreIncrease, moves)
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
                            // No merge. Move the piece from tempCol left instead
                            if let moveAction = self.movePieceAsFarLeftAsPossibleFrom(Coordinate(x: temp, y: row)) {
                                actions.append(moveAction)
                            }
                            
                            if col < self.dimension - 1 {
                                tempCol = col // Whatever was tempCol previously did not result in a merge. Trying again with the current col.
                            } else {
                                // No more pieces to try to merge with. Just move the last piece left
                                if let moveAction = self.movePieceAsFarLeftAsPossibleFrom(Coordinate(x: col, y: row)) {
                                    actions.append(moveAction)
                                }
                            }
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
            tempCol = nil
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarLeftAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let leftmostCol = self.findLeftmostColToTheRightOf(fromCoordinate)
        
        if leftmostCol != fromCoordinate.x { // If it could even move
            if let _ = self.board[fromCoordinate.y][fromCoordinate.x] {
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
            leftmostCol -= 1
        }
        leftmostCol += 1 // leftmostCol is now either on another tile, or -1 (just off the edge) so I need to increment it
        
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
            for var col = self.dimension - 1; col >= 0; col -= 1 {
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
                            // No merge. Move the piece from tempCol right instead
                            if let moveAction = self.movePieceAsFarRightAsPossibleFrom(Coordinate(x: temp, y: row)) {
                                actions.append(moveAction)
                            }
                            
                            if col > 0 {
                                tempCol = col // Whatever was tempCol previously did not result in a merge. Trying again with the current col.
                            } else {
                                // No more pieces to try to merge with. Just move the last piece right
                                if let moveAction = self.movePieceAsFarRightAsPossibleFrom(Coordinate(x: col, y: row)) {
                                    actions.append(moveAction)
                                }
                            }
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
            tempCol = nil
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarRightAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let rightmostCol = self.findRightmostColToTheRightOf(fromCoordinate)
        
        if rightmostCol != fromCoordinate.x { // If it could even move
            if let _ = self.board[fromCoordinate.y][fromCoordinate.x] {
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
            rightmostCol += 1
        }
        rightmostCol -= 1 // rightmostCol is now either on another tile, or self.dimension (just off the edge) so I need to decrement it
        
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
                            // No merge. Move the piece from tempRow up instead
                            if let moveAction = self.movePieceAsFarUpAsPossibleFrom(Coordinate(x: col, y: temp)) {
                                actions.append(moveAction)
                            }
                            
                            if row < self.dimension - 1 {
                                tempRow = row
                            } else {
                                // No more pieces to try to merge with. Just move the last piece up
                                if let moveAction = self.movePieceAsFarUpAsPossibleFrom(Coordinate(x: col, y: row)) {
                                    actions.append(moveAction)
                                }
                            }
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
            tempRow = nil
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarUpAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let upmostRow = self.findUpmostRowUpwardsFrom(fromCoordinate)
        
        if upmostRow != fromCoordinate.y { // If it could even move
            if let _ = self.board[fromCoordinate.y][fromCoordinate.x] {
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
            upmostRow -= 1
        }
        upmostRow += 1
        
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
            for var row = self.dimension - 1; row >= 0; row -= 1 {
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
                            // No merge. Move the piece from tempRow down instead
                            if let moveAction = self.movePieceAsFarDownAsPossibleFrom(Coordinate(x: col, y: temp)) {
                                actions.append(moveAction)
                            }
                            
                            if row > 0 {
                                tempRow = row // Whatever was tempRow previously did not result in a merge. Trying again with the current row.
                            } else {
                                // No more pieces to try to merge with. Just move the last piece down
                                if let moveAction = self.movePieceAsFarDownAsPossibleFrom(Coordinate(x: col, y: row)) {
                                    actions.append(moveAction)
                                }
                            }
                        }
                    } else {
                        if row == 0 {
                            // Currently on the top edge. No need to store this to check for merging. Can just move it
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
            
            
            
            tempRow = nil
        }
        
        return (score, actions)
    }
    
    private func movePieceAsFarDownAsPossibleFrom(fromCoordinate: Coordinate) -> MoveAction<C>? {
        var returnValue: MoveAction<C>? = nil
        let downmostRow = self.findDownmostRowDownwardsFrom(fromCoordinate)
        
        if downmostRow != fromCoordinate.y {
            if let _ = self.board[fromCoordinate.y][fromCoordinate.x] {
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
            downmostRow += 1
        }
        downmostRow -= 1
        
        return downmostRow
    }

    
    
    
    // -------------------------------
    // MARK: Spawning new pieces
    // -------------------------------
    
    // Will do nothing if there are no empty spots on the board
    func spawnNewGamePieceAtRandomPosition() -> (actions: MoveAction<C>?, gameOver: Bool) {
        
        if self.isFull() == false {
            var emptySpots = [Coordinate]()
            
            for row in 0..<self.dimension {
                for col in 0..<self.dimension {
                    if self.board[row][col] == nil {
                        let coordinateToAppend = Coordinate(x: col, y: row)
                        emptySpots.append(coordinateToAppend)
                    }
                }
            }
            
            let indexOfSpot = UInt32(arc4random()) % UInt32(emptySpots.count)
            
            let spot = emptySpots[Int(indexOfSpot)]
            let value = C.getBaseValue()
            
            self.board[spot.y][spot.x] = value
            
            MOONLog("Gameboard after spawn")
            printBoard()
            
            let spawnAction = MoveAction.Spawn(gamePiece: GamePiece(value: value, position: spot))
            
            var gameOver = false
            if canStillDoMove() == false {
                gameOver = true
            }
            
            return (spawnAction, gameOver)
        } else {
            MOONLog("The board is full")
            return (nil, false)
        }
    }
    
    func spawnNodeWithValue(value: C, atCoordinate coordinate: Coordinate) -> (actions: MoveAction<C>?, gameOver: Bool) {
        if self.board[coordinate.y][coordinate.x] == nil {
            MOONLog("Spawning \(value) at \(coordinate)")
            self.board[coordinate.y][coordinate.x] = value
            
            let spawnAction = MoveAction.Spawn(gamePiece: GamePiece(value: value, position: coordinate))
            
            var gameOver = false
            if canStillDoMove() == false {
                gameOver = true
            }
            
            return (spawnAction, gameOver)
        } else {
            MOONLog("The coordinate: \(coordinate) is already occupied by \(value)")
            return (nil, false)
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helper Methods
    // -------------------------------
    
    private func printBoard() {
        for row in 0..<self.dimension {
            var rowString = ""
            for col in 0..<self.dimension {
                if let value = self.board[row][col] {
                    rowString += "\(value.scoreValue) "
                } else {
                    rowString += "- "
                }
            }
            MOONLog(rowString)
        }
    }
    
}

