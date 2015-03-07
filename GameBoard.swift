//
//  GameBoard.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 01/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

protocol GameBoardProtocol {
    func performActions(actions: [TileAction])
    func updateScoreBy(scoreIncrement: Int)
}

class GameBoard {
    
    private
    
    init(dimension: Int) {
        
    }
    
    func moveInDirection(direction: MoveDirection) {
        
    }
    
    func spawnTile(tile: Tile) {
        
    }
    
}