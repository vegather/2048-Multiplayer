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
    
    var initialGameStateActions = [MoveAction<D>]()
    var gameResult: GameResult? // This needs to be set before calling performSegue
    
    var viewHasAppeared = false
    
    
    // TIMER VARIABLES
    
    @IBOutlet weak var timeLeftLabel: UILabel! {
        didSet {
            timeLeftLabel.text = "\(timeLeft)"
        }
    }
    var timeLeft: Int = 0 { // In seconds
        didSet {
            timeLeftLabel?.text = "\(timeLeft)"
        }
    }
    var timeLeftTimer: NSTimer?
    var opponentTimeoutTimer: NSTimer?
    
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
                if let gameSetup = self.gameSetup {
                    if gameSetup.setupForCreating {
                        self.turnUserInteractionOn()
                    } else {
                        self.turnUserInteractionOffWithMessage("Waiting for opponent to move...")
                    }
                } else {
                    self.turnUserInteractionOffWithMessage("Unknown state. Quit the game and try again.")
                }
                
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
                    timeLeftLabel.hidden = true
                    
                    self.turnUserInteractionOn()
                    
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
                } else {
                    timeLeftLabel.hidden = false
                    timeLeft = gameSetup.turnDuration
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
            if self.blurryMessageView.superview == nil {
                self.view.addSubview(self.blurryMessageView)
            }
        }
    }
    
    private func turnUserInteractionOn() {
        MWLog()
        
        if self.blurryMessageView != nil && self.blurryMessageView.superview != nil {
            self.blurryMessageView.removeFromSuperview()
            self.gameView?.userInteractionEnabled = true
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Current User Timer
    // -------------------------------
    
    private func startCurrentUserTimer() {
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                if gameBrain.opponentDisplayName != nil {
                    MWLog("Starting timer")
                    
                    self.timeLeftTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(1),
                        target:   self,
                        selector: Selector("decrementCurrentUserTimeLeft:"),
                        userInfo: nil,
                        repeats:  true)
                    
                    timeLeft = gameSetup.turnDuration
                } else {
                    MWLog("ERROR: There is not an opponent yet.")
                }
            } else {
                MWLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
        } else {
            MWLog("ERROR: No gameSetup")
        }
    }
    
    private func stopCurrentUserTimer() {
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                MWLog("Stopping timer")
                
                timeLeftTimer?.invalidate()
                timeLeftTimer = nil
                timeLeft = gameSetup.turnDuration
            } else {
                MWLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
        } else {
            MWLog("ERROR: No gameSetup")
        }
    }
    
    @objc private func decrementCurrentUserTimeLeft(timer: NSTimer!) {
        timeLeft--
        if timeLeft == 0 {
            currentUserTimerTimedOut()
        }
    }
    
    private func currentUserTimerTimedOut() {
        timeLeftTimer?.invalidate()
        timeLeftTimer = nil
        stopOpponentTimeoutTimer()
        
        if let gameSetup = gameSetup {
            let opponentName: String
            if let opponentDisplayName = gameBrain.opponentDisplayName {
                opponentName = opponentDisplayName
            } else {
                opponentName = "Opponent"
            }
            
            gameResult = GameResult(
                players:                Players.Multi,
                boardSize:              gameSetup.dimension,
                turnDuration:           gameSetup.turnDuration,
                won:                    false,
                currentUserScore:       gameBrain.userScore,
                opponentScore:          gameBrain.opponentScore,
                currentUserDisplayName: gameBrain.userDisplayName,
                opponentDisplayName:    opponentName)
            
            let timeoutMessage = UIAlertController(
                title: "You lost",
                message: "You spent too long thinking, and used up your \(gameSetup.turnDuration) seconds.",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let okAction = UIAlertAction(
                title: "Got it",
                style: UIAlertActionStyle.Default,
                handler: { (action: UIAlertAction!) -> Void in
                    self.performSegueWithIdentifier(SegueIdentifier.PushByPoppingToOverFromGame, sender: self)
            })
            
            timeoutMessage.addAction(okAction)
            presentViewController(timeoutMessage, animated: true, completion: nil)
            
        } else {
            MWLog("ERROR: No gameSetup")
        }
    }
    
    
    
    // -------------------------------
    // MARK: Opponent Timer
    // -------------------------------
    
    private func startOpponentTimeoutTimer() {
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                MWLog("Setting timer to turnDuration * 2")
                
                opponentTimeoutTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(gameSetup.turnDuration * 2),
                    target:   self,
                    selector: Selector("opponentTimerTimedOut:"),
                    userInfo: nil,
                    repeats:  false)
            } else {
                MWLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
            
        } else {
            MWLog("ERROR: No gameSetup")
        }
    }
    
    private func stopOpponentTimeoutTimer() {
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                MWLog("Invalidating timer")
                opponentTimeoutTimer?.invalidate()
                opponentTimeoutTimer = nil
            } else {
                MWLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
        } else {
            MWLog("ERROR: No gameSetup")
        }
    }
    
    @objc private func opponentTimerTimedOut(timer: NSTimer!) {
        
        if let gameSetup = gameSetup {
            MWLog("Will present alert")
            
            let opponentName: String
            if let opponentDisplayName = gameBrain.opponentDisplayName {
                opponentName = opponentDisplayName
            } else {
                opponentName = "Opponent"
            }
            
            gameResult = GameResult(
                players:                Players.Multi,
                boardSize:              gameSetup.dimension,
                turnDuration:           gameSetup.turnDuration,
                won:                    true,
                currentUserScore:       gameBrain.userScore,
                opponentScore:          gameBrain.opponentScore,
                currentUserDisplayName: gameBrain.userDisplayName,
                opponentDisplayName:    opponentName)
            
            let timeoutMessage = UIAlertController(
                title: "You won",
                message: "Your opponent spent too long thinking, and used up his/her \(gameSetup.turnDuration) seconds.",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let okAction = UIAlertAction(
                title: "Got it",
                style: UIAlertActionStyle.Default,
                handler: { (action: UIAlertAction!) -> Void in
                    self.performSegueWithIdentifier(SegueIdentifier.PushByPoppingToOverFromGame, sender: self)
            })
            
            timeoutMessage.addAction(okAction)
            presentViewController(timeoutMessage, animated: true, completion: nil)
        } else {
            MWLog("ERROR: No gameSetup")
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Board View Delegate
    // -------------------------------
    
    func boardViewDidFinishAnimating() {
        if gameSetup?.players == Players.Multi {
            if gameBrain.currentPlayer == Turn.Opponent {
                MWLog("Opponents turn")
                
                turnUserInteractionOffWithMessage("Waiting for opponent to move...")
                
                stopCurrentUserTimer()
                startOpponentTimeoutTimer()
            } else if gameBrain.currentPlayer == Turn.User {
                MWLog("Current users turn")
                
                turnUserInteractionOn()
                
                stopOpponentTimeoutTimer()
                startCurrentUserTimer()
            }
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
        
        if gameSetup?.setupForCreating == true {
            if initialGameStateActions.count < 2 {
                for action in actions {
                    initialGameStateActions.append(action)
                }
                
                if initialGameStateActions.count == 2 {
                    gameBrain.addInitialState(initialGameStateActions[0], tileTwo: initialGameStateActions[1])
                }
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
            MWLog("Changed to opponents turn")
            self.gameView?.userInteractionEnabled = false
        } else {
            MWLog("Changed to current users turn")
            turnUserInteractionOn()
        }
    }
    
    func gameBrainGameIsOverFromFillingUpBoard() {
        // Find out who won
        MWLog()
        
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Single {
                
                // Singleplayer
                gameResult = GameResult(
                    players:                Players.Single,
                    boardSize:              gameSetup.dimension,
                    turnDuration:           gameSetup.turnDuration,
                    currentUserScore:       gameBrain.userScore,
                    currentUserDisplayName: gameBrain.userDisplayName)
            } else {
                
                // Multiplayer
                
                var didWin: Bool? = nil
                if gameBrain.userScore > gameBrain.opponentScore {
                    didWin = true
                } else if gameBrain.userScore < gameBrain.opponentScore {
                    didWin = false
                } // Otherwise draw
                
                let opponentName: String
                if let opponentDisplayName = gameBrain.opponentDisplayName {
                    opponentName = opponentDisplayName
                } else {
                    opponentName = "Opponent"
                }
                
                gameResult = GameResult(
                    players:                Players.Multi,
                    boardSize:              gameSetup.dimension,
                    turnDuration:           gameSetup.turnDuration,
                    won:                    didWin,
                    currentUserScore:       gameBrain.userScore,
                    opponentScore:          gameBrain.opponentScore,
                    currentUserDisplayName: gameBrain.userDisplayName,
                    opponentDisplayName:    opponentName)
            }
            
            // Just want the user to see what happened before moving to gameOver screen
            turnUserInteractionOn() // Clear any messages
            self.view.userInteractionEnabled = false
            delay(1.0) {
                self.performSegueWithIdentifier(SegueIdentifier.PushByPoppingToOverFromGame, sender: self)
            }
            
        } else {
            MWLog("ERROR: There was no gameSetup")
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
    
    func gameBrainDidJoinGame() {
        if viewHasAppeared {
            MWLog("View has appeared")
            opponentDisplayNameLabel.text = self.gameBrain.opponentDisplayName
            opponentScoreLabel.text = "0"
            turnUserInteractionOffWithMessage("Waiting for opponent to move...")
        } else {
            MWLog("View has not appeared yet")
        }
    }
    
    func gameBrainDidCreateSinglePlayerGame() {
        MWLog()
        turnUserInteractionOn()
    }
    
    
    // -------------------------------
    // MARK: Game Brain Getting Opponent
    // -------------------------------
    
    func gameBrainDidGetOpponentNamed(opponentName: String) {
        if viewHasAppeared {
            MWLog("opponentName: \(opponentName), and the view has appeared")
            opponentDisplayNameLabel.text = opponentName
            opponentScoreLabel.text = "0"
            
            turnUserInteractionOn()
            
            startCurrentUserTimer()
        } else {
            MWLog("opponentName: \(opponentName), but the view has not appeared yet")
        }
    }
    
    
    
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    

    @IBAction func forfeitGameButtonTapped() {
        MWLog()
        
        var alertMessage = "Quitting the game will terminate the current game."
        
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                let opponentName: String
                if let opponentDisplayName = gameBrain.opponentDisplayName {
                    opponentName = opponentDisplayName
                } else {
                    opponentName = "Opponent"
                }
                
                alertMessage += " Also your opponent will win."
                
                gameResult = GameResult(
                    players:                Players.Multi,
                    boardSize:              gameSetup.dimension,
                    turnDuration:           gameSetup.turnDuration,
                    won:                    false,
                    currentUserScore:       gameBrain.userScore,
                    opponentScore:          gameBrain.opponentScore,
                    currentUserDisplayName: gameBrain.userDisplayName,
                    opponentDisplayName:    opponentName)
            } else {
                gameResult = GameResult(
                    players:                Players.Single,
                    boardSize:              gameSetup.dimension,
                    turnDuration:           gameSetup.turnDuration,
                    currentUserScore:       gameBrain.userScore,
                    currentUserDisplayName: gameBrain.userDisplayName)
            }
        } else {
            MWLog("ERROR: No gameSetup")
        }
        
        let alert = UIAlertController(
            title: "Are you sure",
            message: alertMessage,
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
                
                destination.gameResult = gameResult
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}

