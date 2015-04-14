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
    
    var userDisplayName: String? = UserServerManager.lastKnownCurrentUserDisplayName {
        didSet {
            MWLog("Setting userDisplayName to \(userDisplayName)")
            if userDisplayNameLabel != nil, let userDisplayName = userDisplayName {
                userDisplayNameLabel.text = userDisplayName
            }
        }
    }
    
    var opponentDisplayName: String? {
        didSet {
            MWLog("Setting opponentDisplayName to \(opponentDisplayName)")
            if opponentDisplayNameLabel != nil, let opponentDisplayName = opponentDisplayName {
                opponentDisplayNameLabel.text = opponentDisplayName
            }
        }
    }
    
    var viewHasAppeared = false
    
    // For single/multi alignment
    @IBOutlet weak var scoreBoardHeightConstrant: NSLayoutConstraint!
    @IBOutlet weak var currentUserResultWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentPlayerResultBox: UIView!
    
    // General outlets
    @IBOutlet weak var opponentDisplayNameLabel: UILabel! {
        didSet {
            if let opponentDisplayName = opponentDisplayName {
                MWLog("Setting opponentDisplayNameLabel.text to \(opponentDisplayName)")
                opponentDisplayNameLabel.text = opponentDisplayName
            }
        }
    }
    @IBOutlet weak var opponentScoreLabel: UILabel!
    
    @IBOutlet weak var userDisplayNameLabel: UILabel! {
        didSet {
            if let userDisplayName = userDisplayName {
                MWLog("Setting userDisplayNameLabel.text to \(userDisplayName)")
                userDisplayNameLabel.text = userDisplayName
            }
        }
    }
    @IBOutlet weak var userScoreLabel: UILabel!
    
    
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
                if gameSetup.players == Players.Single {
                    self.currentPlayerResultBox.removeConstraint(currentUserResultWidthConstraint)
                    let newConstraint = NSLayoutConstraint(
                        item: currentPlayerResultBox,
                        attribute: NSLayoutAttribute.Trailing,
                        relatedBy: NSLayoutRelation.Equal,
                        toItem: self.view,
                        attribute: NSLayoutAttribute.Trailing,
                        multiplier: 1.0,
                        constant: -16)
                    self.view.addConstraint(newConstraint)
                    // setNeedsUpdateConstraints() will get called further down
                    
                    opponentDisplayNameLabel.hidden = true
                    opponentScoreLabel.hidden = true
                }
                
                self.gameBoardScene = BoardView(sizeOfBoard: gameView.frame.size, dimension: gameSetup.dimension)
                self.gameBoardScene?.gameViewDelegate = self

                self.gameView?.presentScene(self.gameBoardScene)
                
                self.setupSwipes()
            }
            
            userScoreLabel.text = "\(gameBrain.userScore)"
            opponentScoreLabel.text = "\(gameBrain.opponentScore)"
            
            scoreBoardHeightConstrant.constant = self.view.frame.size.height -
                                                 self.view.frame.size.width -
                                                 UIApplication.sharedApplication().statusBarFrame.height
            view.setNeedsUpdateConstraints()
            
            
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
        if userScoreLabel != nil {
            userScoreLabel.text = "\(newUserScore)"
        }
    }
    
    func gameBrainOpponentHasNewScore(newOpponentScore: Int) {
        if opponentScoreLabel != nil {
            opponentScoreLabel.text = "\(newOpponentScore)"
        }
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
        opponentDisplayName = opponentName
    }
    
    
    
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    

    @IBAction func forfeitGameButtonTapped() {
        MWLog()
        
        let alert = UIAlertController(
            title: "Are you sure",
            message: "Quitting the game will terminate the current game",
            preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction     = UIAlertAction(title: "Quit",   style: UIAlertActionStyle.Destructive) { (action: UIAlertAction!) -> Void in
            self.performSegueWithIdentifier(SegueIdentifier.PushByPoppingToOverFromGame, sender: self)
        }
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        MWLog()
        if segue.identifier == SegueIdentifier.PushByPoppingToOverFromGame {
            if let destination = segue.destinationViewController as? GameOverViewController {
                
                var didWin: Bool? = nil
                if gameBrain.userScore > gameBrain.opponentScore {
                    didWin = true
                } else if gameBrain.userScore < gameBrain.opponentScore {
                    didWin = false
                } // Otherwise draw
                
                let userName: String
                if let userDisplayName = userDisplayName {
                    userName = userDisplayName
                } else {
                    userName = "You"
                }
                
                let opponentName: String
                if let opponentDisplayName = opponentDisplayName {
                    opponentName = opponentDisplayName
                } else {
                    opponentName = "Opponent"
                }
                
                // nil on a multiplayer is draw
                destination.prepare(
                    players: gameSetup!.players,
                    won: didWin,
                    currentUserScore: gameBrain.userScore,
                    opponentScore: gameBrain.opponentScore,
                    currentUserDisplayName: userName,
                    opponentDisplayName: opponentName)
            }
        }
    }
}

