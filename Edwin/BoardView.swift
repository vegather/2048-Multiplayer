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
    
    private var actionsToPerform = [MoveAction<TileValue>]() {
        didSet {
            self.performRemainingMoveActions()
        }
    }
    
    // Having problems to use the .name of .childNodeWithName functionality to
    // refer to nodes as they are a generic, and not simply a subclass of
    // SKSpriteNode. Will have to keep this board up to date instead...
    private var board: Array<Array<TwosPowerView?>>
    
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
        var toMove   = [(TwosPowerView, Coordinate, Coordinate)]() // View, from, to
        var toSpawn  = [Coordinate]()
        var toEvolve = [TwosPowerView]()
        var toRemove = [TwosPowerView, Coordinate]() // Need the coordinate to remove it from self.board

        
        for action in actions {
            switch action {
            case let .Spawn(gamePiece):
                toSpawn.append(gamePiece.gamePiece.position)
            case let .Move(from, to):
                if let nodeToMove = self.getNodeForCoordinate(from) {
                    toMove.append((nodeToMove, from, to))
                }
            case let .Merge(from, andFrom, newPiece):
                if let firstNode = self.getNodeForCoordinate(from) {
                    if let secondNode = self.getNodeForCoordinate(andFrom) {
                        toMove.append((firstNode,  from,    newPiece.position))
                        toMove.append((secondNode, andFrom, newPiece.position))
                        
                        toEvolve.append(firstNode)
                        toRemove.append(secondNode, newPiece.position)
                    }
                }
            }
        }
        
        self.moveNodes(toMove) { (done: String) in
            println("DONE MOVING, WILL START REST OF ANIMATIONS MESSAGE: \(done)")
            self.spawnNodes(toSpawn)
            self.evolveNodes(toEvolve)
            self.removeNodes(toRemove)
        }
    }
    
    private func performRemainingMoveActions() {
        
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Animation Helpers
    // -------------------------------
    
    private func moveNodes(nodesToMove: [(TwosPowerView, Coordinate, Coordinate)], completionHandler: (done: String) -> Void) {
        println("Number of nodes to move: \(nodesToMove.count)")
        if nodesToMove.count > 0 {
            println("Will move nodes")
            for var i = 0; i < nodesToMove.count; i++ {
                
                let (node, from, to) = nodesToMove[i]
                
                println("WILL MOVE NODE")
                
                let destinationPoint = self.positionForCoordinate(to)
                let moveAction = SKAction.moveTo(destinationPoint, duration: 1.0)
                node.runAction(moveAction, completion: { () -> Void in
                    println("DONE MOVING")
                    if i == nodesToMove.count - 1 {
                        // Just finished animating the last node
                        completionHandler(done: "Did finish moving")
                    }
                })
                
                // If there is NOT a new node in the position we came from. Set that to nil
                if self.getNodeForCoordinate(from) == node {
                    self.setNode(nil, forCoordinate: from)
                }
                
                self.setNode(node, forCoordinate: to)
            }
        } else {
            println("Will NOT move nodes")
            completionHandler(done: "Nothing to move")
        }
    }
    
    private func spawnNodes(coordinatesForNodesToSpawn: [Coordinate]) {
        for coordinate in coordinatesForNodesToSpawn {
            // Might add some animations to this later
            
            let nodeToAdd = TwosPowerView()
            nodeToAdd.size = self.sizeForTile()
            nodeToAdd.position = self.positionForCoordinate(coordinate)
            self.setNode(nodeToAdd, forCoordinate: coordinate)
            
            self.addChild(nodeToAdd)
        }
    }
    
    private func evolveNodes(nodesToEvolve: [TwosPowerView]) {
        for node in nodesToEvolve {
            node.evolve()
        }
    }
    
    private func removeNodes(nodesToRemove: [(TwosPowerView, Coordinate)]) {
        for (node, coordinate) in nodesToRemove {
            node.removeFromParent()
            self.setNode(nil, forCoordinate: coordinate)
        }
    }

    
    
    
    
    // -------------------------------
    // MARK: Private Helper Methods
    // -------------------------------
    
    private func setNode(node: TwosPowerView?, forCoordinate coordinate: Coordinate) {
        if let node = node {
            self.board[coordinate.y][coordinate.x] = node
        }
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
}
