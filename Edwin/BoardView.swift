//
//  BoardView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 10/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

// Generic board view
class BoardView<T: UIView>: UIView {

    // Need this solely to be able to reference the views
    private var board: Array<Array<T?>>
    
    init(frame: CGRect, dimension: Int) {
        self.board = [[T?]](count: dimension, repeatedValue: [T?](count: dimension, repeatedValue: nil))
        
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func performMoveAction<E: Evolvable>(action: MoveAction<E>) {
        switch action {
        case let .Spawn(gamePiece):
            println()
        case let .Move(from, to):
            println()
        case let .Merge(from, andFrom, newPiece):
            println()
        }
    }
    
}
