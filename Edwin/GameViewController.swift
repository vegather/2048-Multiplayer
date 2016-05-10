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
    let POP_ANIMATION_DURATION = 0.2
    
    
    // For single/multi alignment
    @IBOutlet weak var scoreBoardHeightConstrant:             NSLayoutConstraint!
    @IBOutlet weak var opponentScoreBox:                      UIView!
    @IBOutlet weak var currentUserScoreBox:                   UIView!
    @IBOutlet weak var currentUserScoreBoxTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scoreBox:                              UIView!
    
    
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
    
    @IBOutlet weak var timeLeftDescriptionLabel: UILabel!
    @IBOutlet weak var timeLeftLabel: UILabel! {
        didSet {
            if timeLeftLabel != nil {
                timeLeftLabel.text = "\(timeLeft)"
            }
        }
    }
    var timeLeft: Int = 0 { // In seconds
        didSet {
            if timeLeftLabel != nil {
                var newScale: CGFloat = 0.0
                if      timeLeft == 5 { newScale = 1.15 }
                else if timeLeft == 4 { newScale = 1.3  }
                else if timeLeft == 3 { newScale = 1.45 }
                else if timeLeft == 2 { newScale = 1.6  }
                else if timeLeft == 1 { newScale = 1.75 }
                
                if newScale > 0 {
                    UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                        animations: { () -> Void in
                            self.timeLeftLabel.transform = CGAffineTransformScale(self.timeLeftLabel.transform, newScale, newScale)
                        },
                        completion: { (finishedSuccessfully: Bool) -> Void in
                            self.timeLeftLabel.text = "\(self.timeLeft)"
                            
                            UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                                animations: { () -> Void in
                                    self.timeLeftLabel.transform = CGAffineTransformIdentity
                                },
                                completion: nil)
                    })
                } else {
                    timeLeftLabel.text = "\(timeLeft)"
                }
            }
        }
    }
    var timeLeftTimer: NSTimer?
    var opponentTimeoutTimer: NSTimer? {
        didSet {
            MOONLog("OPPONENTTIMEOUTTIMER GOT SET TO: \(opponentTimeoutTimer)")
        }
    }
    
    // General outlets
    var opponentScore: Int = 0 {
        didSet {
            if opponentScoreLabel != nil && opponentScore != oldValue {
                UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                    animations: { () -> Void in
                        self.opponentScoreLabel.transform = CGAffineTransformScale(self.opponentScoreLabel.transform, 1.3, 1.3)
                    },
                    completion: { (finishedSuccessfully: Bool) -> Void in
                        self.opponentScoreLabel.text = "\(self.opponentScore)"
                        
                        UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                            animations: { () -> Void in
                                self.opponentScoreLabel.transform = CGAffineTransformIdentity
                            },
                            completion: nil)
                })
            }
        }
    }
    @IBOutlet weak var opponentScoreLabel: UILabel! {
        didSet {
            if opponentScoreLabel != nil {
                opponentScoreLabel.text = "\(opponentScore)"
            }
        }
    }
    @IBOutlet weak var opponentDisplayNameLabel: UILabel!
    
    var userScore: Int = 0 {
        didSet {
            if userScoreLabel != nil && userScore != oldValue {
                UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                    animations: { () -> Void in
                        self.userScoreLabel.transform = CGAffineTransformScale(self.userScoreLabel.transform, 1.3, 1.3)
                    },
                    completion: { (finishedSuccessfully: Bool) -> Void in
                        self.userScoreLabel.text = "\(self.userScore)"
                        
                        UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                            animations: { () -> Void in
                                self.userScoreLabel.transform = CGAffineTransformIdentity
                            },
                            completion: nil)
                })
            }
        }
    }
    @IBOutlet weak var userScoreLabel: UILabel! {
        didSet {
            if userScoreLabel != nil {
                userScoreLabel.text = "\(userScore)"
            }
        }
    }
    
    
    @IBOutlet weak var userDisplayNameLabel: UILabel! {
        didSet {
            MOONLog("Setting userDisplayNameLabel.text to \(gameBrain.userDisplayName)")
            userDisplayNameLabel.text = gameBrain.userDisplayName
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MOONLog()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewHasAppeared == false {
            viewHasAppeared = true
            MOONLog("First time")
            
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
            
            
            
            if let gameView = self.gameView, gameSetup = self.gameSetup {
                if gameSetup.players == Players.Single {
                    timeLeftLabel.hidden = true
                    timeLeftDescriptionLabel.hidden = true
                    
                    self.turnUserInteractionOn()
                    
                    self.currentUserScoreBox.removeConstraint(currentUserScoreBoxTrailingConstraint)
                    self.opponentScoreBox.removeFromSuperview()
                    
                    let newConstraint = NSLayoutConstraint(
                        item: currentUserScoreBox,
                        attribute: NSLayoutAttribute.Trailing,
                        relatedBy: NSLayoutRelation.Equal,
                        toItem: self.scoreBox,
                        attribute: NSLayoutAttribute.Trailing,
                        multiplier: 1.0,
                        constant: -8)
                    self.view.addConstraint(newConstraint)
                    // setNeedsUpdateConstraints() will get called further down
                    
                    opponentDisplayNameLabel.hidden = true
                    opponentScoreLabel.hidden = true
                } else {
                    // Multiplayer
                    
                    if let opponentName = gameBrain.opponentDisplayName { // Probably won't happen
                        MOONLog("Has opponent: \(opponentName)")
                        opponentDisplayNameLabel.text = opponentName
                        opponentScoreLabel.text = "0"
                        
                        if gameSetup.setupForCreating {
                            timeLeftLabel.hidden = false
                            timeLeftDescriptionLabel.hidden = false
                            timeLeft = gameSetup.turnDuration
                            turnUserInteractionOn()
                        } else {
                            self.turnUserInteractionOffWithMessage("Waiting for opponent to move...")
                        }
                        
                    } else {
                        timeLeftLabel.hidden = true
                        timeLeftDescriptionLabel.hidden = true
                        opponentDisplayNameLabel.text = ""
                        opponentScoreLabel.text = ""
                        
                        if let _ = gameBrain.gamePin {
                            MOONLog("Not yet an opponent, but the game has a gamePin")
                            self.turnUserInteractionOffWithMessage("Waiting for opponent...")
                        } else {
                            MOONLog("No opponent, and no gamePin")
                            self.turnUserInteractionOffWithMessage("Creating game...")
                        }
                    }
                }
                
                var shouldDelayBeforeDoneAnimating = false
                if gameSetup.players == Players.Multi {
                    shouldDelayBeforeDoneAnimating = true
                }
                
                self.gameBoardScene = BoardView(
                    sizeOfBoard: gameView.frame.size,
                    dimension: gameSetup.dimension,
                    shouldDelayBeforeDoneAnimating: shouldDelayBeforeDoneAnimating)
                self.gameBoardScene?.gameViewDelegate = self

                self.gameView?.presentScene(self.gameBoardScene)
                
                self.setupSwipes()
            }
            
            userScoreLabel.text = "\(gameBrain.userScore)"
            opponentScoreLabel.text = "\(gameBrain.opponentScore)"
            
            scoreBoardHeightConstrant.constant = self.view.frame.size.height -
                                                 self.view.frame.size.width - 20
                //UIApplication.sharedApplication().statusBarFrame.height
            view.setNeedsUpdateConstraints()
            
            
            if actionsToPerformOnAppearance.count > 0 {
                self.gameBoardScene?.performMoveActions(actionsToPerformOnAppearance)
            }
        } else {
            MOONLog("Second time")
        }
    }

    
    
    
    
    // -------------------------------
    // MARK: Swipes
    // -------------------------------
    
    func setupSwipes() {
        if let gestureView = self.gameView {
            let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.leftSwipe))
            leftSwipe.numberOfTouchesRequired = 1
            leftSwipe.direction = UISwipeGestureRecognizerDirection.Left
            gestureView.addGestureRecognizer(leftSwipe)
        }
        
        if let gestureView = self.gameView {
            let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.rightSwipe))
            rightSwipe.numberOfTouchesRequired = 1
            rightSwipe.direction = UISwipeGestureRecognizerDirection.Right
            gestureView.addGestureRecognizer(rightSwipe)
        }
        
        if let gestureView = self.gameView {
            let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.upSwipe))
            upSwipe.numberOfTouchesRequired = 1
            upSwipe.direction = UISwipeGestureRecognizerDirection.Up
            gestureView.addGestureRecognizer(upSwipe)
        }
        
        if let gestureView = self.gameView {
            let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.downSwipe))
            downSwipe.numberOfTouchesRequired = 1
            downSwipe.direction = UISwipeGestureRecognizerDirection.Down
            gestureView.addGestureRecognizer(downSwipe)
        }
    }
    
    func leftSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MOONLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Left)
            } else {
                MOONLog("Not done animating yet")
            }
        }
    }
    
    func rightSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MOONLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Right)
            } else {
                MOONLog("Not done animating yet")
            }
        }
    }
    
    func upSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MOONLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Up)
            } else {
                MOONLog("Not done animating yet")
            }
        }
    }
    
    func downSwipe() {
        if let gameBoardScene = self.gameBoardScene {
            if (gameBoardScene.isDoneAnimating()) {
                MOONLog("Done animating so ready to accept new swipe")
                self.gameBrain.moveInDirection(MoveDirection.Down)
            } else {
                MOONLog("Not done animating yet")
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Preparing
    // -------------------------------
    
    func prepareGameSetup(gameSetup: GameSetup<D>) {
        MOONLog("\(gameSetup)")
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
        MOONLog("message: \(message)")
        self.gameView?.userInteractionEnabled = false
        
        if self.blurryMessageView != nil {
            timeLeftLabel.hidden = true
            timeLeftDescriptionLabel.hidden = true
            
            self.blurryMessageView.message = message
            if self.blurryMessageView.superview == nil {
                self.view.addSubview(self.blurryMessageView)
            }
        }
    }
    
    private func turnUserInteractionOn() {
        MOONLog()
        
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
                    MOONLog("Starting timer")
                    
                    self.timeLeftTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(1),
                        target:   self,
                        selector: #selector(GameViewController.decrementCurrentUserTimeLeft(_:)),
                        userInfo: nil,
                        repeats:  true)
                    
                    timeLeft = gameSetup.turnDuration
                } else {
                    MOONLog("ERROR: There is not an opponent yet.")
                }
            } else {
                MOONLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    private func stopCurrentUserTimer() {
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                MOONLog("Stopping timer")
                
                timeLeftTimer?.invalidate()
                timeLeft = gameSetup.turnDuration
            } else {
                MOONLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    @objc private func decrementCurrentUserTimeLeft(timer: NSTimer!) {
        timeLeft -= 1
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
                opponentDisplayName:    opponentName,
                gameEndScreenshot:      self.grabScreenshot())
            
            let timeoutMessage = UIAlertController(
                title: "You Lost",
                message: "You spent too long thinking, and used up your \(gameSetup.turnDuration) seconds.",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let okAction = UIAlertAction(
                title: "Got it",
                style: UIAlertActionStyle.Default,
                handler: { (action: UIAlertAction!) -> Void in
                    self.performSegueWithIdentifier(SegueIdentifier.PushGameOverFromGame, sender: self)
            })
            
            timeoutMessage.addAction(okAction)
            presentViewController(timeoutMessage, animated: true, completion: nil)
            
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Opponent Timer
    // -------------------------------
    
    private func startOpponentTimeoutTimer() {
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                let timerDuration = NSTimeInterval(gameSetup.turnDuration + 5)
                MOONLog("Setting timer to \(timerDuration) seconds")
                
                if self.opponentTimeoutTimer != nil {
                    self.opponentTimeoutTimer!.invalidate()
                    self.opponentTimeoutTimer = nil
                }
                self.opponentTimeoutTimer = NSTimer.scheduledTimerWithTimeInterval(timerDuration,
                    target:   self,
                    selector: #selector(GameViewController.opponentTimerTimedOut(_:)),
                    userInfo: nil,
                    repeats:  false)
                
                MOONLog("JUST SET OPPONENT TIMER TO: \(self.opponentTimeoutTimer)")
                
            } else {
                MOONLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
            
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    private func stopOpponentTimeoutTimer() {
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                MOONLog("Invalidating timer: \(opponentTimeoutTimer)")
                self.opponentTimeoutTimer?.invalidate()
                opponentTimeoutTimer = nil
            } else {
                MOONLog("ERROR: The game is a single player game. Should not use any timers in this case")
            }
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    @objc private func opponentTimerTimedOut(timer: NSTimer!) {
        
        MOONLog("TIMED OUT: \(timer)")
        
        if let gameSetup = gameSetup {
            MOONLog("Will present alert")
            stopCurrentUserTimer()
            
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
                opponentDisplayName:    opponentName,
                gameEndScreenshot:      self.grabScreenshot())
            
            let timeoutMessage = UIAlertController(
                title: "You Won",
                message: "Your opponent spent too long thinking, and used up their \(gameSetup.turnDuration) seconds.",
                preferredStyle: .Alert)
            
            let okAction = UIAlertAction(
                title: "Got it",
                style: .Default,
                handler: { (action: UIAlertAction!) -> Void in
                    self.performSegueWithIdentifier(SegueIdentifier.PushGameOverFromGame, sender: self)
            })
            
            timeoutMessage.addAction(okAction)
            presentViewController(timeoutMessage, animated: true, completion: nil)
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Board View Delegate
    // -------------------------------
    
    func boardViewDidFinishAnimating() {
        if let gameSetup = gameSetup {
            if gameBrain.gameIsOver == false {
                if gameSetup.players == Players.Multi {
                    
                    if gameBrain.currentPlayer == Turn.Opponent {
                        MOONLog("Opponents turn")
                        turnUserInteractionOffWithMessage("Waiting for opponent to move...")
                    } else if gameBrain.currentPlayer == Turn.User {
                        MOONLog("Current users turn")
                        if gameBrain.opponentDisplayName != nil {
                            MOONLog("It's the current users turn, and there is an opponent. Starting current user timer")
                            turnUserInteractionOn()
                            startCurrentUserTimer()
                            timeLeftLabel.hidden = false
                            timeLeftDescriptionLabel.hidden = false
                        } else {
                            MOONLog("No opponent yet")
                        }
                    }
                } else {
                    MOONLog("Finished animating for singleplayer game. The game goes on.")
                }
            } else {
                // The game is now over
                
                if gameSetup.players == Players.Single {
                    // Singleplayer
                    
                    MOONLog("A singleplayer game is over")
                    
                    gameResult = GameResult(
                        players:                Players.Single,
                        boardSize:              gameSetup.dimension,
                        turnDuration:           gameSetup.turnDuration,
                        currentUserScore:       gameBrain.userScore,
                        currentUserDisplayName: gameBrain.userDisplayName,
                        gameEndScreenshot:      self.grabScreenshot())
                } else {
                    // Multiplayer
                    
                    MOONLog("A multiplayer game is over")
                    
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
                        opponentDisplayName:    opponentName,
                        gameEndScreenshot:      self.grabScreenshot())
                }
                
                //Just want the user to see what happened before moving to gameOver screen
                turnUserInteractionOn() // Clear any messages
                self.view.userInteractionEnabled = false

                delay(0.5) {
                    self.performSegueWithIdentifier(SegueIdentifier.PushGameOverFromGame, sender: self)
                }
            }
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Game Brain Ongoing Game
    // -------------------------------

    func gameBrainDidProduceActions(actions: [MoveAction<D>], forSetup: Bool) {
        MOONLog("actionsCount: \(actions.count), forSetup: \(forSetup), currentPlayer: \(gameBrain.currentPlayer)")
        
        if viewHasAppeared {
            if forSetup == false { // The actions are NOT spawns for the setup
                if gameBrain.currentPlayer == Turn.User {
                    MOONLog("The current user just did a moved that produced some actions. Will stop currentUserTimer and start opponent timer")
                    stopCurrentUserTimer()
                    timeLeftLabel.hidden = true
                    timeLeftDescriptionLabel.hidden = true
                    startOpponentTimeoutTimer()
                } else {
                    MOONLog("Opponent did a move. Will stop opponentTimer")
                    stopOpponentTimeoutTimer()
                }
            }
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
                if gameSetup?.players == Players.Multi {
                    if initialGameStateActions.count == 2 {
                        gameBrain.addInitialState(initialGameStateActions[0], tileTwo: initialGameStateActions[1])
                    }
                }
            }
        }
    }
    
    func gameBrainUserHasNewScore(newUserScore: Int) {
        userScore = newUserScore
    }
    
    func gameBrainOpponentHasNewScore(newOpponentScore: Int) {
        opponentScore = newOpponentScore
    }
    
    func gameBrainDidChangeTurnTo(currentTurn: Turn) {
        if currentTurn == Turn.Opponent {
            MOONLog("Changed to opponents turn")
            self.gameView?.userInteractionEnabled = false
        } else {
            MOONLog("Changed to current users turn")
            turnUserInteractionOn()
        }
    }
    
    func gameBrainGameIsOverFromFillingUpBoard() {
        // Find out who won
        MOONLog()
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Brain Game Creation
    // -------------------------------
    
    func gameBrainWillCreateMultiplayerGame() {
        MOONLog()
        turnUserInteractionOffWithMessage("Creating game...")
    }
    
    func gameBrainDidCreateMultiplayerGameWithGamepin(gamePin: String) {
        MOONLog("gamePin: \(gamePin)")
        if opponentDisplayNameLabel != nil && opponentScoreLabel != nil {
            opponentDisplayNameLabel.text = ""
            opponentScoreLabel.text = ""
        }
        turnUserInteractionOffWithMessage("Waiting for an opponent to join...\n\n The GamePin is \(gamePin)")
    }
    
    func gameBrainDidJoinGame() {
        if viewHasAppeared {
            MOONLog("View has appeared")
            opponentDisplayNameLabel.text = self.gameBrain.opponentDisplayName
            opponentScoreLabel.text = "0"
            turnUserInteractionOffWithMessage("Waiting for opponent to move...")
        } else {
            MOONLog("View has not appeared yet")
        }
    }
    
    func gameBrainDidCreateSinglePlayerGame() {
        MOONLog()
        turnUserInteractionOn()
    }
    
    
    
    
    // -------------------------------
    // MARK: Game Brain Getting Opponent
    // -------------------------------
    
    func gameBrainDidGetOpponentNamed(opponentName: String) {
        if viewHasAppeared {
            MOONLog("opponentName: \(opponentName), and the view has appeared")
            opponentDisplayNameLabel.text = opponentName
            opponentScoreLabel.text = "0"
            
            turnUserInteractionOn()
        } else {
            MOONLog("opponentName: \(opponentName), but the view has not appeared yet")
        }
    }
    
    
    
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    

    @IBAction func forfeitGameButtonTapped() {
        MOONLog()
        
        var alertMessage = "Quitting the game will terminate the current game."
        
        if let gameSetup = gameSetup {
            if gameSetup.players == Players.Multi {
                
                let opponentName: String
                if let opponentDisplayName = gameBrain.opponentDisplayName {
                    alertMessage += " This will also let \(opponentDisplayName) win"
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
                    opponentDisplayName:    opponentName,
                    gameEndScreenshot:      self.grabScreenshot())
            } else {
                gameResult = GameResult(
                    players:                Players.Single,
                    boardSize:              gameSetup.dimension,
                    turnDuration:           gameSetup.turnDuration,
                    currentUserScore:       gameBrain.userScore,
                    currentUserDisplayName: gameBrain.userDisplayName,
                    gameEndScreenshot:      self.grabScreenshot())
            }
            
            let alert = UIAlertController(
                title: "Are you sure",
                message: alertMessage,
                preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            let okAction     = UIAlertAction(title: "Quit",   style: UIAlertActionStyle.Destructive) { (action: UIAlertAction!) -> Void in
                self.stopCurrentUserTimer()
                self.stopOpponentTimeoutTimer()
                self.gameBrain.deleteCurrentGame()
                
                if gameSetup.players == Players.Multi && self.gameBrain.opponentDisplayName == nil {
                    MOONLog("There was no game. The user just wants to quit. Will return to main menu")
                    self.performSegueWithIdentifier(SegueIdentifier.PopToMainMenuFromGame, sender: self)
                } else {
                    MOONLog("There was an actual game, so show the result of it")
                    self.performSegueWithIdentifier(SegueIdentifier.PushGameOverFromGame, sender: self)
                }
            }
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            
            presentViewController(alert, animated: true, completion: nil)
            
        } else {
            MOONLog("ERROR: No gameSetup")
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        MOONLog()
        if segue.identifier == SegueIdentifier.PushGameOverFromGame {
            if let destination = segue.destinationViewController as? GameOverViewController {
                MOONLog("Preparing to show gameResult: \(gameResult)")
                destination.gameResult = gameResult
            }
        } else if segue.identifier == SegueIdentifier.PopToMainMenuFromGame {
            MOONLog("Preparing to return to main menu.")
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    private func grabScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.gameView!.bounds.size, true, 0);
        self.gameView!.drawViewHierarchyInRect(self.gameView!.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return image
    }
}

