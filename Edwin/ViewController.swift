//
//  ViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 28/02/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class ViewController: UIViewController, GameBrainDelegate {

    var gameBrain: GameBrain!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gameBrain = GameBrain(delegate: self, dimension: 4)
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Brain Delegate Methods
    // -------------------------------

    func performActions<T: Evolvable>(actions: [MoveAction<T>]) {
        
    }
    
    func userHasNewScore(newUserScore: Int) {
        
    }
    
    func opponentHasNewScore(newOpponentScore: Int) {
        
    }
    
    func usersTurn() {
        
    }
    
    func opponentsTurn() {
        
    }


}

