//
//  EvolvableView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 11/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit

protocol EvolvableViewType {

    associatedtype C: Evolvable

    func evolve()
    var value: C { get set }
}
