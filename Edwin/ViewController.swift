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
        
        self.setupSwipes()
    }
    
    func setupSwipes() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: Selector("leftSwipe"))
        leftSwipe.numberOfTouchesRequired = 1
        leftSwipe.direction = UISwipeGestureRecognizerDirection.Left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: Selector("rightSwipe"))
        rightSwipe.numberOfTouchesRequired = 1
        rightSwipe.direction = UISwipeGestureRecognizerDirection.Right
        view.addGestureRecognizer(rightSwipe)
        
        let upSwipe = UISwipeGestureRecognizer(target: self, action: Selector("upSwipe"))
        upSwipe.numberOfTouchesRequired = 1
        upSwipe.direction = UISwipeGestureRecognizerDirection.Up
        view.addGestureRecognizer(upSwipe)
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: Selector("downSwipe"))
        downSwipe.numberOfTouchesRequired = 1
        downSwipe.direction = UISwipeGestureRecognizerDirection.Down
        view.addGestureRecognizer(downSwipe)
    }
    
    
    
    
    // -------------------------------
    // MARK: Swipes
    // -------------------------------
    
    func leftSwipe() {
        println("Left")
    }
    
    func rightSwipe() {
        println("Right")
    }
    
    func upSwipe() {
        println("Up")
    }
    
    func downSwipe() {
        println("Down")
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

