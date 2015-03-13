//
//  EvolvableView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 11/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

//class EvolvableViewType: UIView {
//    func evolve() {
//        println("evolve needs implementation")
//    }
//}


protocol EvolvableViewType {
    func evolve()
}

protocol GameBoardViewType {
    init(frame: CGRect, dimension: Int)
    func performMoveActions<E: Evolvable>(actions: [MoveAction<E>])
    
    typealias TileViewType
}
