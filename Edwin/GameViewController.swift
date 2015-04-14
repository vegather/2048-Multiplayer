//
//  ViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 28/02/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, GameBrainDelegate, BoardViewDelegate {

    typealias D = TileValue
    
    var gameBrain: GameBrain<GameViewController>!
    var gameView:  SKView?
    var gameSetup: GameSetup<D>?
    var gameBoardScene: BoardView?
    var actionsToPerformOnAppearance = [MoveAction<D>]()
    
    var viewHasAppeared = false
    
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MWLog()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewHasAppeared == false {
            viewHasAppeared = true
            MWLog("First time")
            
            // Geometry is set inside here
            
            let gameViewFrame = CGRectMake(0,
                self.view.frame.size.height - self.view.frame.size.width,
                self.view.frame.size.width,
                self.view.frame.size.width)
            
            if self.gameView == nil {
                self.gameView = SKView(frame: gameViewFrame)
                self.view.addSubview(self.gameView!)
            }
            
            if let gameView = self.gameView, gameSetup = self.gameSetup {
                self.gameBoardScene = BoardView(sizeOfBoard: gameView.frame.size, dimension: gameSetup.dimension)
                self.gameBoardScene?.gameViewDelegate = self

                self.gameView?.presentScene(self.gameBoardScene)
                
                self.setupSwipes()
            }
            
            if actionsToPerformOnAppearance.count > 0 {
                self.gameBoardScene?.performMoveActions(actionsToPerformOnAppearance)
            }
        } else {
            MWLog("Second time")
        }
    }

    
    
    
    // -------------------------------
    // MARK: Swipes
    // -------------------------------
    
    func setupSwipes() {
        if let gestureView = self.gameView {
            let leftSwipe = UISwipeGestureRecognizer(target: self, action: Selector("leftSwipe"))
            leftSwipe.numberOfTouchesRequired = 1
            leftSwipe.direction = UISwipeGestureRecognizerDirection.Left
            gestureView.addGestureRecognizer(leftSwipe)
        }
        
        if let gestureView = self.gameView {
            let rightSwipe = UISwipeGestureRecognizer(target: self, action: Selector("rightSwipe"))
            rightSwipe.numberOfTouchesRequired = 1
            rightSwipe.direction = UISwipeGestureRecognizerDirection.Right
            gestureView.addGestureRecognizer(rightSwipe)
        }
        
        if let gestureView = self.gameView {
            let upSwipe = UISwipeGestureRecognizer(target: self, action: Selector("upSwipe"))
            upSwipe.numberOfTouchesRequired = 1
            upSwipe.direction = UISwipeGestureRecognizerDirection.Up
            gestureView.addGestureRecognizer(upSwipe)
        }
        
        if let gestureView = self.gameView {
            let downSwipe = UISwipeGestureRecognizer(target: self, action: Selector("downSwipe"))
            downSwipe.numberOfTouchesRequired = 1
            downSwipe.direction = UISwipeGestureRecognizerDirection.Down
            gestureView.addGestureRecognizer(downSwipe)
        }
    }
    
    func leftSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MWLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Left)
            } else {
                MWLog("Not done animating yet")
            }
        }
    }
    
    func rightSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MWLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Right)
            } else {
                MWLog("Not done animating yet")
            }
        }
    }
    
    func upSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MWLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Up)
            } else {
                MWLog("Not done animating yet")
            }
        }
    }
    
    func downSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MWLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Down)
            } else {
                MWLog("Not done animating yet")
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Preparing
    // -------------------------------
    
    func prepareGameSetup(gameSetup: GameSetup<D>) {
        MWLog("\(gameSetup)")
        self.gameSetup = gameSetup
        self.gameBrain = GameBrain<GameViewController>(delegate: self)
        self.gameBrain.prepareForGameWithSetup(&self.gameSetup!)
    }
    
    
    
    
    // -------------------------------
    // MARK: Board View Delegate
    // -------------------------------
    
    func boardViewDidFinishAnimating() {
        MWLog()
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Brain Ongoing Game
    // -------------------------------

    func gameBrainDidProduceActions(actions: [MoveAction<D>]) {
        MWLog("actions: \(actions)")
        
        if viewHasAppeared {
            self.gameBoardScene?.performMoveActions(actions)
        } else {
            for action in actions {
                self.actionsToPerformOnAppearance.append(action)
            }
        }
    }
    
    func gameBrainUserHasNewScore(newUserScore: Int) {
        
    }
    
    func gameBrainOpponentHasNewScore(newOpponentScore: Int) {
        
    }
    
    func gameBrainDidChangeTurnTo(currentTurn: Turn) {
        
    }
    
    
    
    // -------------------------------
    // MARK: Game Brain Game Creation
    // -------------------------------
    
    func gameBrainWillCreateMultiplayerGame() {
        
    }
    
    func gameBrainDidCreateMultiplayerGameWithGamepin(gamePin: String) {
        
    }
    
    func gameBrainDidCreateSinglePlayerGame() {
        
    }
    
    
    // -------------------------------
    // MARK: Game Brain Getting Opponent
    // -------------------------------
    
    func gameBrainDidGetOpponentNamed(opponentName: String) {
        
    }
    
    
    
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    

    @IBAction func forfeitGameButtonTapped() {
        MWLog()
        self.performSegueWithIdentifier(SegueIdentifier.PushByPoppingToOverFromGame, sender: self)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        MWLog()
        if segue.identifier == SegueIdentifier.PushByPoppingToOverFromGame {
            if let destination = segue.destinationViewController as? GameOverViewController {
                destination.prepare(players: Players.Single,
                    won: nil,
                    currentUserScore: 10000,
                    opponentScore: nil,
                    currentUserDisplayName: "Steve",
                    opponentDisplayName: nil)
            }
        }
    }
}

