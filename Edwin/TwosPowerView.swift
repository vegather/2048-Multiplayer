//
//  TwosPowerView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 12/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit

class TwosPowerView: SKLabelNode, EvolvableViewType {
    
    var value: TileValue
    
    init(value: TileValue) {
        self.value = value
        
        super.init(fontNamed: "HelveticeNeue")
        
        self.text = "\(self.value)"  // TileValue conforms to Printable
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func evolve() {
        
    }
}
