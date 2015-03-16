//
//  BoardView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 10/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit


// This class always keeps the name of its child nodes up to date based on the 
// location of the tile the nodes represents. It doesn't need an internal
// structure to do this. It just updates the names.

// Generic board that takes any type that is a subclass of SKNode as
// well as implements the EvolvableViewType protocol
class BoardView<T where T:EvolvableViewType, T:SKNode>: SKScene {
    
    let dimension: Int
    
    init(size: CGSize, dimension: Int) {
        self.dimension = dimension
        
        super.init(size: size)
        
        self.backgroundColor = UIColor.greenColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // -------------------------------
    // MARK: Public API
    // -------------------------------
    
    func performMoveActions<E: Evolvable>(actions: [MoveAction<E>]) {
        for action in actions {
            switch action {
            case let .Spawn(gamePiece):
                println()
                // Create new node of type T
                // Add node to board
            case let .Move(from, to):
                println()
            case let .Merge(from, andFrom, newPiece):
                println()
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helper Methods
    // -------------------------------
    
    func stringForCoordinate(coordinate: Coordinate) -> String {
        return "\(coordinate.x),\(coordinate.y)"
    }
    
    func coordinateForString(string: String) -> Coordinate? {
        let elements = string.componentsSeparatedByString(",")
        if elements.count == 2 {
            if let xValue = elements[0].toInt() {
                if let yValue = elements[1].toInt() {
                    return Coordinate(x: xValue, y: yValue)
                }
            }
        }
        
        return nil
    }
    
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
