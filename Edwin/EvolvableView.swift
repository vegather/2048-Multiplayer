//
//  EvolvableView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 11/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit

//class EvolvableViewType: UIView {
//    func evolve() {
//        println("evolve needs implementation")
//    }
//}


protocol EvolvableViewType {

    typealias C: Evolvable

//    init(value: C, size: CGSize)
    func evolve()
    var value: C {get set}
}

protocol GameBoardViewType {
    init(frame: CGRect, dimension: Int)
    func performMoveActions<E: Evolvable>(actions: [MoveAction<E>])
    
    typealias TileViewType
}


