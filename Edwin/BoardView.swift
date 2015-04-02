//
//  BoardView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 10/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit



// Generic board that takes any type that is a subclass of SKNode as
// well as implements the EvolvableViewType protocol
class BoardView: SKScene {
    
    let dimension: Int
    
    var toMove   = [TwosPowerView, Coordinate, Coordinate]() // View, from, to
    var toSpawn  = [Coordinate]()
    var toEvolve = [TwosPowerView, Coordinate]()
    var toRemove = [TwosPowerView]()
    
    let ANIMATION_DURATION = 1.5
    
    // Will be increased every time a batch of moveActions start, and decremented when batches are done
    var numberOfNodesInTheProcessOfMoving = 0
    

    
    // Having problems to use the .name of .childNodeWithName functionality to
    // refer to nodes as they are a generic, and not simply a subclass of
    // SKSpriteNode. Will have to keep this board up to date instead...
    private var board: Array<Array<TwosPowerView?>> {
        didSet {
            printBoardView()
        }
    }
    
    init(sizeOfBoard: CGSize, dimension: Int) {
        self.board = [[TwosPowerView?]](count: 4, repeatedValue: [TwosPowerView?](count: 4, repeatedValue: nil))
        self.dimension = dimension
        
        super.init(size: sizeOfBoard)

        self.backgroundColor = UIColor.lightGrayColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    // -------------------------------
    // MARK: Public API
    // -------------------------------
    
    func performMoveActions(actions: [MoveAction<TileValue>]) {
//        self.queuedActions += actions
//        self.performRemainingActions()
        
        for action in actions {
            
            switch action {
            case let .Spawn(gamePiece):
                MWLog("Adding spawn action")
                self.toSpawn.append(gamePiece.gamePiece.position)
            case let .Move(from, to):
                if let nodeToMove = self.getNodeForCoordinate(from) {
                    MWLog("Adding move action")
                    self.toMove.append((nodeToMove, from, to))
                }
            case let .Merge(from, andFrom, newPiece):
                if let firstNode = self.getNodeForCoordinate(from) {
                    if let secondNode = self.getNodeForCoordinate(andFrom) {
                        MWLog("Adding move actions for merge")
                        self.toMove.append((firstNode,  from,    newPiece.position))
                        self.toMove.append((secondNode, andFrom, newPiece.position))
                        
                        MWLog("Adding evolve action")
                        self.toEvolve.append(firstNode, newPiece.position)
                        MWLog("Adding remove action")
                        self.toRemove.append(secondNode)
                    }
                }
            }
        }
        
        if toMove.count > 0 {
            MWLog("Will do moves: \(toMove)")
            moveNodes(toMove)
            MWLog("Will clear toMove buffer")
            self.toMove.removeAll(keepCapacity: false)
        } else if numberOfNodesInTheProcessOfMoving == 0 {
            MWLog("Will spawn nodes: \(toSpawn)")
            spawnNodes(toSpawn)
            MWLog("Will clear toSpawn buffer")
            self.toSpawn.removeAll(keepCapacity: false)
            
            MWLog("Will evolve nodes: \(toEvolve)")
            evolveNodes(toEvolve)
            MWLog("Will clear toEvolve buffer")
            self.toEvolve.removeAll(keepCapacity: false)
            
            MWLog("Will remove nodes: \(toRemove)")
            removeNodes(toRemove)
            MWLog("Will clear toRemove buffer")
            self.toRemove.removeAll(keepCapacity: false)
        }
    }

    
//    private func performRemainingActions() {
//        if self.queuedActions.count > 0 {
//            for action in self.queuedActions {
//                
//                switch action {
//                case let .Spawn(gamePiece):
//                    MWLog("performRemainingActions - Adding spawn action")
//                    toSpawn.append(gamePiece.gamePiece.position)
//                case let .Move(from, to):
//                    if let nodeToMove = self.getNodeForCoordinate(from) {
//                        MWLog("performRemainingActions - Adding move action")
//                        toMove.append((nodeToMove, from, to))
//                    }
//                case let .Merge(from, andFrom, newPiece):
//                    if let firstNode = self.getNodeForCoordinate(from) {
//                        if let secondNode = self.getNodeForCoordinate(andFrom) {
//                            MWLog("performRemainingActions - Adding move actions for merge")
//                            toMove.append((firstNode,  from,    newPiece.position))
//                            toMove.append((secondNode, andFrom, newPiece.position))
//                            
//                            MWLog("performRemainingActions - Adding evolve action")
//                            toEvolve.append(firstNode)
//                            MWLog("performRemainingActions - Adding remove action")
//                            toRemove.append(secondNode, newPiece.position)
//                        }
//                    }
//                }
//            }
//            
//            MWLog("Number of nodes to process: move: \(toMove.count), spawn: \(toSpawn.count), evolve: \(toEvolve.count), remove: \(toRemove.count)")
//            
//            self.queuedActions.removeAll(keepCapacity: true)
//            
//            if toMove.count > 0 {
//                MWLog("Will move...")
//                
//                // Since we're moving, we should add back the rest of the actions
//    //            self.queuedActions += 
//                
//                moveNodes(toMove, completionHandler: { (done) -> Void in
//                    MWLog("Done moving node views")
//                    self.performRemainingActions()
//                })
//            } else {
//                if self.numberOfNodesInTheProcessOfMoving == 0 {
//                    MWLog("Will do other actions...")
//                    
//                    spawnNodes(toSpawn)
//                    evolveNodes(toEvolve)
//                    removeNodes(toRemove)
//                }
//            }
//        }
//    }
    
    
    
    
    // -------------------------------
    // MARK: Private Animation Helpers
    // -------------------------------
    
    private func moveNodes(nodesToMove: [(TwosPowerView, Coordinate, Coordinate)]) { //, completionHandler: (done: String) -> Void) {
        
        if nodesToMove.count > 0 {
            for var i = 0; i < nodesToMove.count; i++ {
                
                let (node, from, to) = nodesToMove[i]
                
                self.numberOfNodesInTheProcessOfMoving += 1
                
                let destinationPoint = self.positionForCoordinate(to)
                let moveAction = SKAction.moveTo(destinationPoint, duration: ANIMATION_DURATION)
                node.runAction(moveAction, completion: { () -> Void in
                    
                    self.numberOfNodesInTheProcessOfMoving -= 1
                    
                    MWLog("In completion handler for runAction - i: \(i), nodesToMove.count: \(nodesToMove.count) counter: \(self.numberOfNodesInTheProcessOfMoving)")

                    if self.numberOfNodesInTheProcessOfMoving == 0 {
                        MWLog("Will spawn nodes: \(self.toSpawn)")
                        self.spawnNodes(self.toSpawn)
                        MWLog("Will clear toSpawn buffer")
                        self.toSpawn.removeAll(keepCapacity: false)
                        
                        MWLog("Will evolve nodes: \(self.toEvolve)")
                        self.evolveNodes(self.toEvolve)
                        MWLog("Will clear toEvolve buffer")
                        self.toEvolve.removeAll(keepCapacity: false)
                        
                        MWLog("Will remove nodes: \(self.toRemove)")
                        self.removeNodes(self.toRemove)
                        MWLog("Will clear toRemove buffer")
                        self.toRemove.removeAll(keepCapacity: false)
                    }
                    
//                    // i will be equal to the nodesToMove.count
//                    if i == nodesToMove.count - 1 {
//                        // Just finished animating the last node
//                        completionHandler(done: "Did finish moving")
//                    }
                })
                
                // If there is NOT a new node in the position we came from. Set that to nil
                if let tileFromSorce = self.getNodeForCoordinate(from) {
                    if tileFromSorce == node && from != to {
                        MWLog("Will set source \(from) to nil")
                        self.setNode(nil, forCoordinate: from)
                    } else {
                        MWLog("\(tileFromSorce) and \(node) are NOT equal or from \(from) and to \(to) ARE equal ")
                    }
                } else {
                    MWLog("The node at the source \(from) is nil")
                }
                
                self.setNode(node, forCoordinate: to)
            }
        } else {
            MWLog("No nodes to move")
//            completionHandler(done: "Nothing to move")
        }
    }
    
    private func spawnNodes(coordinatesForNodesToSpawn: [Coordinate]) {
        MWLog("coordinatesForNodesToSpawn: \(coordinatesForNodesToSpawn)")
        for coordinate in coordinatesForNodesToSpawn {
            // Might add some animations to this later
            
            let nodeToAdd = TwosPowerView()
            nodeToAdd.size = self.sizeForTile()
            nodeToAdd.position = self.positionForCoordinate(coordinate)
            self.setNode(nodeToAdd, forCoordinate: coordinate)
            
            self.addChild(nodeToAdd)
        }
    }
    
    private func evolveNodes(nodesToEvolve: [(TwosPowerView, Coordinate)]) {
        MWLog("nodesToEvolve: \(nodesToEvolve)")
        for (node, coordinate) in nodesToEvolve {
            node.evolve()
            self.setNode(node, forCoordinate: coordinate)
        }
    }
    
    private func removeNodes(nodesToRemove: [TwosPowerView]) {
        MWLog("nodesToRemove: \(nodesToRemove)")
        for (node) in nodesToRemove {
            node.removeFromParent()
        }
    }

    
    
    
    
    // -------------------------------
    // MARK: Private Helper Methods
    // -------------------------------
    
    private func setNode(node: TwosPowerView?, forCoordinate coordinate: Coordinate) {
//        if let node = node {
            self.board[coordinate.y][coordinate.x] = node
//        }
    }
    
    private func getNodeForCoordinate(coordinate: Coordinate) -> TwosPowerView? {
        return self.board[coordinate.y][coordinate.x]
    }
    
    private func positionForCoordinate(coordinate: Coordinate) -> CGPoint {
        let tileSize = self.sizeForTile()
        let reversedY = CGFloat((4 - 1) - coordinate.y)
        
        return CGPoint(x: CGFloat(coordinate.x) * tileSize.width  + (tileSize.width  / 2.0),
                       y: reversedY             * tileSize.height + (tileSize.height / 2.0))
    }
    
    private func sizeForTile() -> CGSize {
        return CGSize(width: self.size.width  / CGFloat(4),
                     height: self.size.height / CGFloat(4))
    }
    
    private func printBoardView() {
        for row in self.board {
            var rowString = ""
            for tile in row {
                if let tile = tile {
                    rowString += "\(tile.value.scoreValue) "
                } else {
                    rowString += "- "
                }
            }
            MWLog(rowString)
        }
        MWLog()
    }
}











//    var queuedActions: [MoveAction<TileValue>] = [MoveAction<TileValue>]() {
//        didSet {
//            MWLog("BoardView - Queueing action: \(queuedActions.last)")
////            self.performRemainingActions()
//        }
//    }

//    private var isCurrentlyInProcessOfMovingNodes = false
//    private var actionsToPerform: [MoveAction<TileValue>] = [MoveAction<TileValue>]() {
//        didSet {
//            self.performRemainingMoveActions()
//        }
//    }













//        var toMove   = [(TwosPowerView, Coordinate, Coordinate)]() // View, from, to
//        var toSpawn  = [Coordinate]()
//        var toEvolve = [TwosPowerView]()
//        var toRemove = [TwosPowerView, Coordinate]() // Need the coordinate to remove it from self.board


// Want to do all the move actions first, and then all the rest of them.

//        var moveActions  = [MoveAction<TileValue>]()
//        var otherActions = [MoveAction<TileValue>]()

//        var additionsToActionQueue = [MoveAction<TileValue>]()

//        for action in actions {
//
//            MWLog("BoardView received action: \(action)")
//
//            self.queuedActions.append(action)
//
//        }
//            switch action {
//            case let .Spawn(_):
//                toSpawn.append(gamePiece.gamePiece.position)
//            case let .Move(_, _):
//                if let nodeToMove = self.getNodeForCoordinate(from) {
//                    toMove.append((nodeToMove, from, to))
//                }
//            case let .Merge(_, _, _):
//                if let firstNode = self.getNodeForCoordinate(from) {
//                    if let secondNode = self.getNodeForCoordinate(andFrom) {
//                        toMove.append((firstNode,  from,    newPiece.position))
//                        toMove.append((secondNode, andFrom, newPiece.position))
//
//                        toEvolve.append(firstNode)
//                        toRemove.append(secondNode, newPiece.position)
//                    }
//                }
//            }

//            switch action {
//            case let .Move(_, _):
////                // Not sure if Swift will let me insert an item to an array when there are zero items
////                // Doing append if there are zero items.
////                if additionsToActionQueue.count == 0 {
////                    additionsToActionQueue.append(action)
////                } else {
////                    additionsToActionQueue.insert(action, atIndex: 0)
////                }
//                moveActions.append(action)
//            default:
//                otherActions.append(action)
//            }
//        }

//        self.performRemainingActions()

//        self.moveNodes(toMove) { (done: String) in
//            self.spawnNodes(toSpawn)
//            self.evolveNodes(toEvolve)
//            self.removeNodes(toRemove)
//        }
//    }