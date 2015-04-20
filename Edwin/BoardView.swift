//
//  BoardView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 10/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit


protocol BoardViewDelegate {
    func boardViewDidFinishAnimating()
}


// Generic board that takes any type that is a subclass of SKNode as
// well as implements the EvolvableViewType protocol
class BoardView: SKScene {
    
    var gameViewDelegate: BoardViewDelegate?
    
    let dimension: Int
    
    var toMove   = [TwosPowerView, Coordinate, Coordinate]() // View, from, to
    var toSpawn  = [Coordinate]()
    var toEvolve = [TwosPowerView, Coordinate]() // Need this to add it back to self.board
    var toRemove = [TwosPowerView]()
    
    let ANIMATION_DURATION = 0.15
    let WAIT_AFTER_ANIMATION_DURATION = 0.1
    
    // Will be increased every time a batch of moveActions start, and decremented when batches are done
    var ongoingAnimations = 0
    var hasNotifiedDelegateAboutBeingDoneAnimating = false
    
    
    // Having problems to use the .name of .childNodeWithName functionality to
    // refer to nodes as they are a generic, and not simply a subclass of
    // SKSpriteNode. Will have to keep this board up to date instead...
    private var board: Array<Array<TwosPowerView?>> {
        didSet {
            printBoardView()
        }
    }
    
    init(sizeOfBoard: CGSize, dimension: Int) {
        self.board = [[TwosPowerView?]](count: dimension, repeatedValue: [TwosPowerView?](count: dimension, repeatedValue: nil))
        self.dimension = dimension
        
        super.init(size: sizeOfBoard)

        self.backgroundColor = UIColor(red: 236.0 / 255.0,  green: 240.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0) // Cloud
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    // -------------------------------
    // MARK: Public API
    // -------------------------------
    
    func performMoveActions(actions: [MoveAction<TileValue>]) {
        self.hasNotifiedDelegateAboutBeingDoneAnimating = false
        
        for action in actions {
            
            switch action {
            case let .Spawn(gamePiece):
                MWLog("Adding spawn action")
                self.toSpawn.append(gamePiece.position)
            case let .Move(from, to):
                if let nodeToMove = self.getNodeForCoordinate(from) {
                    MWLog("Adding move action")
                    self.toMove.append((nodeToMove, from, to))
                } else {
                    MWLog("Could not find piece at coordinate \(from)")
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
                    } else {
                        MWLog("Could not find piece at coordinate \(andFrom)")
                    }
                } else {
                    MWLog("Could not find piece at coordinate \(from)")
                }
            }
        }
        
        if toMove.count > 0 {
            MWLog("Will do moves: \(toMove)")
            moveNodes(toMove)
            MWLog("Will clear toMove buffer")
            self.toMove.removeAll(keepCapacity: false)
        } else if ongoingAnimations == 0 {
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
            
            if self.isDoneAnimating() && self.hasNotifiedDelegateAboutBeingDoneAnimating == false {
                MWLog("Is done animating, and will let the delegate know about it")
                self.hasNotifiedDelegateAboutBeingDoneAnimating = true
                self.gameViewDelegate?.boardViewDidFinishAnimating()
            } else {
                MWLog("Gone through all the action buffers, but either the animations are not done or we have already notified delegate")
            }
        }
    }
    
    func isDoneAnimating() -> Bool {
        return self.toMove.count   == 0 &&
            self.toEvolve.count == 0 &&
            self.toSpawn.count  == 0 &&
            self.toRemove.count == 0 &&
            self.ongoingAnimations == 0
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Animation Helpers
    // -------------------------------
    
    private func moveNodes(nodesToMove: [(TwosPowerView, Coordinate, Coordinate)]) {
        
        if nodesToMove.count > 0 {
            for var i = 0; i < nodesToMove.count; i++ {
                
                let (node, from, to) = nodesToMove[i]
                
                self.ongoingAnimations += 1
                
                let destination = self.positionForCoordinate(to)
                
                let moveAction = SKAction.moveTo(destination, duration: ANIMATION_DURATION)
                node.runAction(moveAction, completion: { () -> Void in
                    
                    self.ongoingAnimations -= 1
                    
                    MWLog("In completion handler for runAction - i: \(i), nodesToMove.count: \(nodesToMove.count) counter: \(self.ongoingAnimations)")

                    if self.ongoingAnimations == 0 {
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
                        
                        if self.isDoneAnimating() && self.hasNotifiedDelegateAboutBeingDoneAnimating == false {
                            if self.ongoingAnimations == 0 && self.hasNotifiedDelegateAboutBeingDoneAnimating == false {
                                MWLog("Is done animating, and will let the delegate know about it")
                                self.hasNotifiedDelegateAboutBeingDoneAnimating = true
                                self.gameViewDelegate?.boardViewDidFinishAnimating()
                            }
                        } else {
                            MWLog("Gone through all the action buffers, but either the animations are not done or we have already notified delegate")
                        }
                    }
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
        }
    }
    
    private func spawnNodes(coordinatesForNodesToSpawn: [Coordinate]) {
        MWLog("coordinatesForNodesToSpawn: \(coordinatesForNodesToSpawn)")
        for coordinate in coordinatesForNodesToSpawn {
            let nodeToAdd = TwosPowerView(size: self.sizeForTile())
            nodeToAdd.size = self.sizeForTile()
            nodeToAdd.position = self.positionForCoordinate(coordinate)
            self.setNode(nodeToAdd, forCoordinate: coordinate)
            
            self.addChild(nodeToAdd)
            
            nodeToAdd.setScale(0.2)
            
            ongoingAnimations++
            let firstPopAction  = SKAction.scaleTo(1.2, duration: 0.1)
            let secondPopAction = SKAction.scaleTo(1.0, duration: 0.05)
            let waitAction      = SKAction.waitForDuration(NSTimeInterval(WAIT_AFTER_ANIMATION_DURATION))
            let cleanupAction   = SKAction.runBlock() {
                self.ongoingAnimations--
                if self.ongoingAnimations == 0 && self.hasNotifiedDelegateAboutBeingDoneAnimating == false {
                    MWLog("Is done animating, and will let the delegate know about it")
                    self.hasNotifiedDelegateAboutBeingDoneAnimating = true
                    self.gameViewDelegate?.boardViewDidFinishAnimating()
                }
            }
            let popAction = SKAction.sequence([firstPopAction, secondPopAction, waitAction, cleanupAction])
            
            nodeToAdd.runAction(popAction)
        }
    }
    
    private func evolveNodes(nodesToEvolve: [(TwosPowerView, Coordinate)]) {
        MWLog("nodesToEvolve: \(nodesToEvolve)")
        for (node, coordinate) in nodesToEvolve {
            node.evolve()
            self.setNode(node, forCoordinate: coordinate)
            
            ongoingAnimations++
            let firstPopAction  = SKAction.scaleTo(1.5, duration: 0.06)
            let secondPopAction = SKAction.scaleTo(0.9, duration: 0.07)
            let thirdPopAction  = SKAction.scaleTo(1.0, duration: 0.05)
            let waitAction      = SKAction.waitForDuration(NSTimeInterval(WAIT_AFTER_ANIMATION_DURATION))
            let cleanupAction   = SKAction.runBlock() {
                self.ongoingAnimations--
                if self.ongoingAnimations == 0 && self.hasNotifiedDelegateAboutBeingDoneAnimating == false {
                    MWLog("Is done animating, and will let the delegate know about it")
                    self.hasNotifiedDelegateAboutBeingDoneAnimating = true
                    self.gameViewDelegate?.boardViewDidFinishAnimating()
                }
            }
            let popAction = SKAction.sequence([firstPopAction, secondPopAction, thirdPopAction, waitAction, cleanupAction])
            node.runAction(popAction)
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
        MWLog("Setting \(coordinate) to \(node)")
        self.board[coordinate.y][coordinate.x] = node
    }
    
    private func getNodeForCoordinate(coordinate: Coordinate) -> TwosPowerView? {
        MWLog("Getting node at \(coordinate)")
        return self.board[coordinate.y][coordinate.x]
    }
    
    private func positionForCoordinate(coordinate: Coordinate) -> CGPoint {
        let tileSize = self.sizeForTile()
        let reversedY = CGFloat((dimension - 1) - coordinate.y)
        
        return CGPoint(x: CGFloat(coordinate.x) * tileSize.width  + (tileSize.width  / 2.0),
                       y: reversedY             * tileSize.height + (tileSize.height / 2.0))
    }
    
    private func sizeForTile() -> CGSize {
        return CGSize(width: self.size.width  / CGFloat(dimension),
                     height: self.size.height / CGFloat(dimension))
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
