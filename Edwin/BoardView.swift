//
//  BoardView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 10/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

// Generic board view
class BoardView<T: EvolvableView>: UIView {

    // Need this solely to be able to reference the views
    private var board: Array<Array<T?>>
    
    init(frame: CGRect, dimension: Int) {
        self.board = [[T?]](count: dimension, repeatedValue: [T?](count: dimension, repeatedValue: nil))
        
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    
    
    
    // -------------------------------
    // MARK: Public API
    // -------------------------------
    
    func performMoveActions<E: Evolvable>(actions: [MoveAction<E>]) {
        
        var toMove   = [EvolvableView: Coordinate]() // Coordinate is the destination
        var toSpawn  = [EvolvableView]()
        var toEvolve = [EvolvableView]()
        var toRemove = [EvolvableView]()
        
        for action in actions {
            switch action {
            case let .Spawn(gamePiece):
                toSpawn.append(T(frame: CGRect(origin: self.pointForCoordinate(gamePiece.gamePiece.position),
                                                 size: self.sizeOfTile())))
            case let .Move(from, to):
                if let pieceToMove = self.board[from.y][from.x] {
                    toMove[pieceToMove] = to
                }
            case let .Merge(from, andFrom, newPiece):
                if let firstPiece = self.board[from.y][from.x] {
                    if let secondPiece = self.board[andFrom.y][andFrom.x] {
                        toMove[firstPiece] = from
                        toMove[secondPiece] = andFrom
                        
                        toEvolve.append(firstPiece)
                        toRemove.append(secondPiece)
                    }
                }
            }
        }
        
        self.moveViews(toMove) {
            self.spawnViews(toSpawn)
            self.evolveViews(toEvolve)
            self.removeViews(toRemove)
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Move Methods
    // -------------------------------
    
    private func moveViews(viewsToMove: [EvolvableView: Coordinate], completionHandler: () -> ()) {
        
    }
    
    private func spawnViews(viewsToSpawn: [EvolvableView]) {
        
    }
    
    private func evolveViews(viewsToEvolve: [EvolvableView]) {
        
    }
    
    private func removeViews(viewsToRemove: [EvolvableView]) {
        
    }
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func sizeOfTile() -> CGSize {
        let edgeLength = self.frame.size.width / CGFloat(self.board.count)
        return CGSize(width: edgeLength, height: edgeLength)
    }
    
    private func pointForCoordinate(coordinate: Coordinate) -> CGPoint {
        let xValue: CGFloat = (self.frame.size.width  / CGFloat(self.board.count)) * CGFloat(coordinate.x)
        let yValue: CGFloat = (self.frame.size.height / CGFloat(self.board.count)) * CGFloat(coordinate.y)
        return CGPoint(x: xValue, y: yValue)
    }
    
}
