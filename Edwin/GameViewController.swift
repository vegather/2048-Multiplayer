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
    var blurryMessageView: BlurryMessageView!
    
    // This is to make sure the blurryMessage does not show up until AFTER the view is done animating
    var opponentsTurnWhenDoneAnimating: Bool = false
    
    var viewHasAppeared = false
    
    // For single/multi alignment
    @IBOutlet weak var scoreBoardHeightConstrant: NSLayoutConstraint!
    @IBOutlet weak var currentUserResultWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentPlayerResultBox: UIView!
    
    // General outlets
    @IBOutlet weak var opponentScoreLabel: UILabel!
    @IBOutlet weak var opponentDisplayNameLabel: UILabel!
    
    @IBOutlet weak var userScoreLabel: UILabel!
    @IBOutlet weak var userDisplayNameLabel: UILabel! {
        didSet {
            MWLog("Setting userDisplayNameLabel.text to \(gameBrain.userDisplayName)")
            userDisplayNameLabel.text = gameBrain.userDisplayName
        }
    }
    
    
    
    
    
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
                
                self.blurryMessageView = BlurryMessageView(frame: self.gameView!.frame)
            }
            
            if let opponentName = gameBrain.opponentDisplayName {
                MWLog("Has opponent: \(opponentName)")
                opponentDisplayNameLabel.text = opponentName
                opponentScoreLabel.text = "0"
                self.turnUserInteractionOn()
            } else {
                if let gamePin = gameBrain.gamePin {
                    MWLog("Not yet an opponent, but the game has a gamePin")
                    opponentDisplayNameLabel.text = "Gamepin"
                    opponentScoreLabel.text = gamePin
                    self.turnUserInteractionOffWithMessage("Waiting for opponent...")
                } else {
                    MWLog("No opponent, and no gamePin")
                    opponentDisplayNameLabel.text = ""
                    opponentScoreLabel.text = ""
                    self.turnUserInteractionOffWithMessage("Creating game...")
                }
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
    // MARK: Changing Game State
    // -------------------------------
    
    private func turnUserInteractionOffWithMessage(message: String) {
        // Make sure we actually are on screen
        // If we're not, make sure the message gets on screen in viewWillAppear (or similar)
        MWLog("message: \(message)")
        self.gameView?.userInteractionEnabled = false
        
        if self.blurryMessageView != nil {
            self.blurryMessageView.message = message
            self.view.addSubview(self.blurryMessageView)
        }
    }
    
    private func turnUserInteractionOn() {
        MWLog()
        
        if self.blurryMessageView != nil {
            self.blurryMessageView.removeFromSuperview()
            self.gameView?.userInteractionEnabled = true
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Board View Delegate
    // -------------------------------
    
    func boardViewDidFinishAnimating() {
        MWLog()
        
        if opponentsTurnWhenDoneAnimating == true {
            opponentsTurnWhenDoneAnimating = false
            turnUserInteractionOffWithMessage("Waiting for opponent to move...")
        }
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
        if currentTurn == Turn.Opponent {
            self.gameView?.userInteractionEnabled = false
            opponentsTurnWhenDoneAnimating = true
        } else {
            turnUserInteractionOn()
        }
    }
    
    
    
    // -------------------------------
    // MARK: Game Brain Game Creation
    // -------------------------------
    
    func gameBrainWillCreateMultiplayerGame() {
        MWLog()
        turnUserInteractionOffWithMessage("Creating game...")
    }
    
    func gameBrainDidCreateMultiplayerGameWithGamepin(gamePin: String) {
        MWLog("gamePin: \(gamePin)")
        if opponentDisplayNameLabel != nil && opponentScoreLabel != nil {
            opponentDisplayNameLabel.text = ""
            opponentScoreLabel.text = ""
        }
        turnUserInteractionOffWithMessage("Waiting for an opponent to join...\n The GamePin is \(gamePin)")
    }
    
    func gameBrainDidCreateSinglePlayerGame() {
        MWLog()
        turnUserInteractionOn()
    }
    
    
    // -------------------------------
    // MARK: Game Brain Getting Opponent
    // -------------------------------
    
    func gameBrainDidGetOpponentNamed(opponentName: String) {
        MWLog("opponentName: \(opponentName)")
        
        opponentDisplayNameLabel.text = opponentName
        opponentScoreLabel.text = "0"
        
        turnUserInteractionOn()
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
            self.gameBrain.deleteCurrentGame()
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
                
                let userName: String = gameBrain.userDisplayName
                
                let opponentName: String
                if let opponentDisplayName = gameBrain.opponentDisplayName {
                    opponentName = opponentDisplayName
                } else {
                    opponentName = "Opponent"
                }
                
                // won == nil on a multiplayer is draw
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

