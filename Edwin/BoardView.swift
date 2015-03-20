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
    
    // Having problems to use the .name of .childNodeWithName functionality to
    // refer to nodes as they are a generic, and not simply a subclass of
    // SKSpriteNode. Will have to keep this board up to date instead...
    
    private var board: Array<Array<TwosPowerView?>>
    
//    typealias F = G.C
    
//    override init(size: CGSize) {
////        self.dimension = dimension
//        
//        super.init(size: size)
//        
////        self.dimension = dimension
//        
////        self.backgroundColor = UIColor.lightGrayColor()
//    }
    
    init(sizeOfBoard: CGSize, dimension: Int) {
        self.board = [[TwosPowerView?]](count: 4, repeatedValue: [TwosPowerView?](count: 4, repeatedValue: nil))
        self.dimension = dimension
        
//        for var x = 0; x < 4; x++ {
//            for var y = 0; y < 4; y++ {
//                if let node = self.board[y][x] {
//                    print("x")
//                } else {
//                    print("-")
//                }
//            }
//            println()
//        }
//        println()
        
        super.init(size: sizeOfBoard)
        
//        self.board = [[G?]](count: 4, repeatedValue: [G?](count: 4, repeatedValue: nil))
//        
//        for var x = 0; x < 4; x++ {
//            for var y = 0; y < 4; y++ {
//                if let node = self.board[y][x] {
//                    print("x")
//                } else {
//                    print("-")
//                }
//            }
//            println()
//        }
//        println()
//        
//        self.board[1][1] = G()
////        self.setNode(G(), forCoordinate: Coordinate(x: 0, y: 0))
//        
//        for var x = 0; x < 4; x++ {
//            for var y = 0; y < 4; y++ {
//                if let node = self.board[y][x] {
//                    print("x")
//                } else {
//                    print("-")
//                }
//            }
//            println()
//        }
//        println()
        
        self.backgroundColor = UIColor.lightGrayColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
//    func setup() {
//        self.board = [[G?]](count: 4, repeatedValue: [G?](count: 4, repeatedValue: nil))
//    }
    
//    - (void)cleanUpChildrenAndRemove {
//    for (SKNode *child in self.children) {
//    [child removeFromParent];
//    }
//    [self removeFromParent];
//    }

    
//    func cleanUpChildrenAndRemove() {
//        for child in self.children as [SKNode] {
//            child.removeFromParent()
//        }
//        
//        self.removeFromParent()
//    }
    
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
//                let nodeName = self.stringForCoordinate(from)
//                if let myNode = self.childNodeWithName(nodeName) as? SKSpriteNode {
//                    toMove.append((myNode, from, to))
//                }
//                if let node = self.childNodeWithName(nodeName) {
//                    toMove.append((node as G, from, to))
//                }
                if let nodeToMove = self.getNodeForCoordinate(from) {
                    toMove.append((nodeToMove, to, from))
                }
                
                println()
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
        
        self.moveNodes(toMove, completionHandler: { () -> () in
            self.spawnNodes(toSpawn)
            self.evolveNodes(toEvolve)
            self.removeNodes(toRemove)
        })
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Animation Helpers
    // -------------------------------
    
    private func moveNodes(nodesToMove: [(TwosPowerView, Coordinate, Coordinate)], completionHandler: () -> ()) {
        if nodesToMove.count > 0 {
            for var i = 0; i < nodesToMove.count; i++ {
                
                let (node, from, to) = nodesToMove[i]
                
                let destinationPoint = self.positionForCoordinate(to)
                let moveAction = SKAction.moveTo(destinationPoint, duration: 0.2)
                node.runAction(moveAction, completion: { () -> Void in
                    if i == nodesToMove.count - 1 {
                        // Just finished animating the last node
                        completionHandler()
                    }
                })
                
                // If there is NOT a new node in the position we came from. Set that to nil
                if self.getNodeForCoordinate(from) == node {
                    self.setNode(nil, forCoordinate: from)
                }
                
                self.setNode(node, forCoordinate: to)
            }
        } else {
            completionHandler()
        }
    }
    
    private func spawnNodes(coordinatesForNodesToSpawn: [Coordinate]) {
        for coordinate in coordinatesForNodesToSpawn {
            // Might add some animations to this later
            
            let nodeToAdd = TwosPowerView()
            nodeToAdd.size = self.sizeForTile()
            nodeToAdd.position = self.positionForCoordinate(coordinate)
//            nodeToAdd.name = self.stringForCoordinate(coordinate)
            self.setNode(nodeToAdd, forCoordinate: coordinate)
            
            self.addChild(nodeToAdd)
        }
    }
    
    private func evolveNodes(nodesToEvolve: [TwosPowerView]) {
        
        println("BoardView viewsToEvolve: \(nodesToEvolve)")
        
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
        println("self.size: \(self.size)")
        println("Dimension: \(4)")
        
        let reversedY = CGFloat((4 - 1) - coordinate.y)
        
        return CGPoint(x: CGFloat(coordinate.x) * tileSize.width  + (tileSize.width  / 2.0),
                       y: reversedY             * tileSize.height + (tileSize.height / 2.0))
    }
    
    private func sizeForTile() -> CGSize {
        return CGSize(width: self.size.width  / CGFloat(4),
                     height: self.size.height / CGFloat(4))
    }
    
//    private func stringForCoordinate(coordinate: Coordinate) -> String {
//        return "\(coordinate.x),\(coordinate.y)"
//    }
//    
//    private func coordinateForString(string: String) -> Coordinate? {
//        let elements = string.componentsSeparatedByString(",")
//        if elements.count == 2 {
//            if let xValue = elements[0].toInt() {
//                if let yValue = elements[1].toInt() {
//                    return Coordinate(x: xValue, y: yValue)
//                }
//            }
//        }
//        
//        return nil
//    }
    
}


























//
//// This class should really be a generic, but as Swift is not completely done yet,
//// the compiler crashes when adding a variable to this class. So until Apple updates
//// Swift, a typealias will have to do
//
//protocol BoardViewDataSource {
//    func getTileView() -> EvolvableViewType
//}
//
////class BoardView<T: EvolvableView>: UIView {
//class BoardView: UIView {//, GameBoardViewType {
//    // Need this solely to be able to reference the views
//    
//    private var ANIMATION_DURATION: NSTimeInterval = 0.15
//    private var dimension: Int
//    
//    var dataSource: BoardViewDataSource?
//    
//    required init(frame: CGRect, dimension: Int) {
//        self.dimension = dimension
//
//        super.init(frame: frame)
//
//        self.layer.borderColor = UIColor.darkGrayColor().CGColor
//        self.layer.borderWidth = 1.0
//    }
//    
//    required init(coder aDecoder: NSCoder) {
//        fatalError("This class does not support NSCoding")
//    }
//    
////    typealias TileViewType = EvolvableViewType
////    
////    let testType: TileViewType = TileViewType()
//    
//    // -------------------------------
//    // MARK: Public API
//    // -------------------------------
//    
//    func performMoveActions<E: Evolvable>(actions: [MoveAction<E>]) {
//        var toMove   = [(EvolvableViewType, Coordinate, Coordinate)]() // View, from, to
//        var toSpawn  = [EvolvableViewType]()
//        var toEvolve = [EvolvableViewType]()
//        var toRemove = [EvolvableViewType]()
//
//        for action in actions {
//            switch action {
//            case let .Spawn(gamePiece):
//                println("BoardView received a .Spawn action)")
//                
//                if let viewToSpawn = self.dataSource?.getTileView() {
//                    viewToSpawn.frame = self.tileFrameForCoordinate(gamePiece.gamePiece.position)
//                    
//                    toSpawn.append(viewToSpawn)
//                }
//            case let .Move(from, to):
////                if let pieceToMove = self.board[from.y][from.x] {
//                if let pieceToMove = self.tileViewForCoordinate(from) {
//                    toMove.append((pieceToMove, from, to))
//                }
//            case let .Merge(from, andFrom, newPiece):
////                if let firstPiece = self.board[from.y][from.x] {
////                    if let secondPiece = self.board[andFrom.y][andFrom.x] {
//                if let firstPiece = self.tileViewForCoordinate(from) {
//                    if let secondPiece = self.tileViewForCoordinate(andFrom) {
//                        
//                        println("Found pieces to merge")
//                        
//                        toMove.append((firstPiece, from, newPiece.position))
//                        toMove.append((secondPiece, andFrom, newPiece.position))
//                        
//                        toEvolve.append(firstPiece)
//                        toRemove.append(secondPiece)
//                    } else {
//                        println("COULD NOT GET SECOND PIECE")
//                    }
//                } else {
//                    println("COULD NOT GET FIRST PIECE")
//                }
//            }
//        }
//        
//        self.moveViews(toMove) {
//            println("COMPLETION HANDLER")
//            self.spawnViews(toSpawn)
//            self.evolveViews(toEvolve)
//            self.removeViews(toRemove)
//        }
//    }
//    
//    
//    
//    
//    // -------------------------------
//    // MARK: Private Move Methods
//    // -------------------------------
//    
//    private func moveViews(viewsToMove: [(EvolvableViewType, Coordinate, Coordinate)], completionHandler: () -> ()) {
//        println("MOVE VIEWS")
//        for var index = 0; index < viewsToMove.count; index++ {
//            
//            var (viewToMove, source, destination) = viewsToMove[index]
//            
//            UIView.animateWithDuration(ANIMATION_DURATION,
//                animations: { () -> Void in
//                    viewToMove.frame = self.tileFrameForCoordinate(destination)
//                }, completion: { (successful: Bool) -> Void in
//                    if successful == true {
//                        if index == viewsToMove.count - 1 {
//                            // Just finished the last move
//                            completionHandler()
//                        }
//                    }
//            })
//        }
//        
//        if viewsToMove.count == 0 {
//            completionHandler()
//        }
//    }
//    
//    private func spawnViews(viewsToSpawn: [EvolvableViewType]) {
//        for view in viewsToSpawn {
//            // Might add some animations to this later
//            self.addSubview(view)
//        }
//    }
//    
//    private func evolveViews(viewsToEvolve: [EvolvableViewType]) {
//        
//        println("BoardView viewsToEvolve: \(viewsToEvolve)")
//        
//        for view in viewsToEvolve {
//            view.evolve()
//        }
//    }
//    
//    private func removeViews(viewsToRemove: [EvolvableViewType]) {
//        for view in viewsToRemove {
//            view.removeFromSuperview()
//        }
//    }
//
//    
//    
//    // -------------------------------
//    // MARK: Private Helpers
//    // -------------------------------
//    
//    private func tileViewForCoordinate(coordinate: Coordinate) -> EvolvableViewType? {
//        var testPoint = self.pointForCoordinate(coordinate)
//        testPoint.x += self.edgeLengthOfTile() / 2.0
//        testPoint.y += self.edgeLengthOfTile() / 2.0
//        
//        if let hitView = self.hitTest(testPoint, withEvent: nil) as? EvolvableViewType {
//            if hitView != self {
//                return hitView
//            }
//        }
//        
//        return nil
//    }
//    
//    private func tileFrameForCoordinate(coordinate: Coordinate) -> CGRect {
//        let tileSize = CGSize(width: self.edgeLengthOfTile(), height: self.edgeLengthOfTile())
//        return CGRect(origin: self.pointForCoordinate(coordinate), size: tileSize)
//    }
//    
//    private func edgeLengthOfTile() -> CGFloat {
////        return self.frame.size.width / CGFloat(self.board.count)
//        return self.frame.size.width / CGFloat(self.dimension)
//    }
//    
//    private func pointForCoordinate(coordinate: Coordinate) -> CGPoint {
////        let xValue: CGFloat = (self.frame.size.width  / CGFloat(self.board.count)) * CGFloat(coordinate.x)
////        let yValue: CGFloat = (self.frame.size.height / CGFloat(self.board.count)) * CGFloat(coordinate.y)
//        let xValue: CGFloat = (self.frame.size.width  / CGFloat(self.dimension)) * CGFloat(coordinate.x)
//        let yValue: CGFloat = (self.frame.size.height / CGFloat(self.dimension)) * CGFloat(coordinate.y)
//        return CGPoint(x: xValue, y: yValue)
//    }
//    
//}
