//
//  GameOverViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 06/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class GameOverViewController: UIViewController {

    // Hooks to modify for singleplayer games
    @IBOutlet weak var gameWonLostLabel:                UILabel!
    @IBOutlet weak var currentPlayerResultBox:          UIView!
    @IBOutlet weak var opponentResultBox:               UIView!
    @IBOutlet weak var statisticsBox:                   UIView!
    @IBOutlet weak var currentUserTrailingConstraint:   NSLayoutConstraint!
    @IBOutlet weak var currentUserTopConstraint:        NSLayoutConstraint!
    @IBOutlet weak var currentUserWidthConstraint:      NSLayoutConstraint!
    
    // Game Result
    @IBOutlet weak var currentPlayerDisplayNameLabel:   UILabel!
    @IBOutlet weak var currentPlayerScoreLabel:         UILabel!
    @IBOutlet weak var opponentDisplayNameLabel:        UILabel!
    @IBOutlet weak var opponentScoreLabel:              UILabel!
    
    // Statistics
    @IBOutlet weak var numberOfWinsLabel:               UILabel!
    @IBOutlet weak var numberOfLossesLabel:             UILabel!
    @IBOutlet weak var numberOfDrawsLabel:              UILabel!
    
    @IBOutlet weak var numberOfWinsSpinner:             UIActivityIndicatorView!
    @IBOutlet weak var numberOfLossesSpinner:           UIActivityIndicatorView!
    @IBOutlet weak var numberOfDrawsSpinner:            UIActivityIndicatorView!
    
    // Misc
    let POP_ANIMATION_DURATION = 0.2
    var gameResult: GameResult?
    
    // Need this becuase viewWillAppear gets called twice with current PushSegue
    var viewHasAppeared: Bool = false
    
    
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewHasAppeared == false {
            viewHasAppeared = true
            
            if let gameResult = gameResult {
                currentPlayerDisplayNameLabel.text = gameResult.currentUserDisplayName
                currentPlayerScoreLabel.text = "\(gameResult.currentUserScore)"
                
                if gameResult.players == Players.Single {
                    gameWonLostLabel.text = "Game Over"
                    
                    // Only need to show result for a single player, so removing opponent result box and statistics
                    
                    statisticsBox.removeFromSuperview()
                    opponentResultBox.removeFromSuperview()
                    currentPlayerResultBox.removeConstraint(currentUserTrailingConstraint)
                    currentPlayerResultBox.removeConstraint(currentUserTopConstraint)
                    currentPlayerResultBox.removeConstraint(currentUserWidthConstraint)
                    
                    let trailingConstraint = NSLayoutConstraint(
                        item:       currentPlayerResultBox,
                        attribute:  NSLayoutAttribute.Trailing,
                        relatedBy:  NSLayoutRelation.Equal,
                        toItem:     self.view,
                        attribute:  NSLayoutAttribute.Trailing,
                        multiplier: 1.0,
                        constant:   -16)
                    
                    let topConstraint = NSLayoutConstraint(
                        item:       currentPlayerResultBox,
                        attribute:  NSLayoutAttribute.Top,
                        relatedBy:  NSLayoutRelation.Equal,
                        toItem:     gameWonLostLabel,
                        attribute:  NSLayoutAttribute.Bottom,
                        multiplier: 1.0,
                        constant:   0)
                    
                    self.view.addConstraint(trailingConstraint)
                    self.view.addConstraint(topConstraint)
                    
                    self.view.setNeedsUpdateConstraints()
                    
                } else {
                    
                    // Multiplayer
                    
                    doStatistics()
                    
                    opponentDisplayNameLabel.text = gameResult.opponentDisplayName
                    opponentScoreLabel.text = "\(gameResult.opponentScore)"
                    
                    if let won = gameResult.won {
                        if won {
                            gameWonLostLabel.text = "You Won"
                        } else {
                            gameWonLostLabel.text = "You Lost"
                        }
                    } else {
                        gameWonLostLabel.text = "Draw"
                    }
                }
            }
        }
    }
    
    private func doStatistics() {
        if let gameResult = gameResult {
            if gameResult.players == Players.Multi {
                if viewHasAppeared {
                    numberOfWinsLabel.hidden   = true
                    numberOfLossesLabel.hidden = true
                    numberOfDrawsLabel.hidden  = true
                    
                    numberOfWinsSpinner.hidden   = false
                    numberOfLossesSpinner.hidden = false
                    numberOfDrawsSpinner.hidden  = false
                    
                    numberOfWinsSpinner.startAnimating()
                    numberOfLossesSpinner.startAnimating()
                    numberOfDrawsSpinner.startAnimating()
                    
                    
                    var shouldIncrementWins   = false
                    var shouldIncrementLosses = false
                    var shouldIncrementDraws  = false
                    
                    if let won = gameResult.won {
                        if won {
                            MWLog("Incrementing wins")
                            shouldIncrementWins = true
                        } else {
                            MWLog("Incrementing losses")
                            shouldIncrementLosses = true
                        }
                    } else {
                        MWLog("Incrementing draw")
                        shouldIncrementDraws = true
                    }
                    
                    // Go fetch statistics data
                    
                    UserServerManager.getNumberOfWinsStatisticsByIncrementing(shouldIncrementWins) { (newNumberOfWins: Int) -> () in
                        self.numberOfWinsLabel.hidden = false
                        self.numberOfWinsSpinner.stopAnimating()
                        self.numberOfWinsSpinner.hidden = true
                        
                        if shouldIncrementWins {
                            // Pop
                            
                            UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                                animations: { () -> Void in
                                    self.numberOfWinsLabel.transform = CGAffineTransformScale(self.opponentScoreLabel.transform, 1.3, 1.3)
                                },
                                completion: { (finishedSuccessfully: Bool) -> Void in
                                    self.numberOfWinsLabel.text = "\(newNumberOfWins)"
                                    
                                    UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                                        animations: { () -> Void in
                                            self.numberOfWinsLabel.transform = CGAffineTransformIdentity
                                        },
                                        completion: nil)
                            })
                        } else {
                            self.numberOfWinsLabel.text = "\(newNumberOfWins)"
                        }
                    }
                    
                    UserServerManager.getNumberOfLossesStatisticsByIncrementing(shouldIncrementLosses) { (newNumberOfLosses: Int) -> () in
                        self.numberOfLossesLabel.hidden = false
                        self.numberOfLossesSpinner.stopAnimating()
                        self.numberOfLossesSpinner.hidden = true
                        
                        if shouldIncrementLosses {
                            // Pop
                            
                            UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                                animations: { () -> Void in
                                    self.numberOfLossesLabel.transform = CGAffineTransformScale(self.opponentScoreLabel.transform, 1.3, 1.3)
                                },
                                completion: { (finishedSuccessfully: Bool) -> Void in
                                    self.numberOfLossesLabel.text = "\(newNumberOfLosses)"
                                    
                                    UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                                        animations: { () -> Void in
                                            self.numberOfLossesLabel.transform = CGAffineTransformIdentity
                                        },
                                        completion: nil)
                            })
                        } else {
                            self.numberOfLossesLabel.text = "\(newNumberOfLosses)"
                        }
                    }
                    
                    UserServerManager.getNumberOfDrawsStatisticsByIncrementing(shouldIncrementDraws) { (newNumberOfDraws: Int) -> () in
                        self.numberOfDrawsLabel.hidden = false
                        self.numberOfDrawsSpinner.stopAnimating()
                        self.numberOfDrawsSpinner.hidden = true
                        
                        if shouldIncrementDraws {
                            // Pop
                            
                            UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                                animations: { () -> Void in
                                    self.numberOfDrawsLabel.transform = CGAffineTransformScale(self.opponentScoreLabel.transform, 1.3, 1.3)
                                },
                                completion: { (finishedSuccessfully: Bool) -> Void in
                                    self.numberOfDrawsLabel.text = "\(newNumberOfDraws)"
                                    
                                    UIView.animateWithDuration(self.POP_ANIMATION_DURATION / 2.0,
                                        animations: { () -> Void in
                                            self.numberOfDrawsLabel.transform = CGAffineTransformIdentity
                                        },
                                        completion: nil)
                            })
                        } else {
                            self.numberOfDrawsLabel.text = "\(newNumberOfDraws)"
                        }
                    }
                } else {
                    MWLog("ERROR: View has NOT appeared")
                }
            } else {
                MWLog("ERROR: Singleplayer")
            }
        } else {
            MWLog("ERROR: No gameResult")
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Actions
    // -------------------------------
    
    @IBAction func shareButtonTapped() {
        
        if let gameResult = gameResult {
            var shareText = ""
            if gameResult.players == Players.Single {
                // Singleplayer
                shareText = "I just scored \(gameResult.currentUserScore) points in Edwin. So addictive!"
            } else {
                // Multiplayer
                if let won = gameResult.won {
                    if won {
                        // Current player won
                        shareText = "I just won against \(gameResult.opponentDisplayName), \(gameResult.opponentScore) to \(gameResult.currentUserScore) in Edwin."
                    } else {
                        // Current player lost
                        shareText = "I just lost against \(gameResult.opponentDisplayName), \(gameResult.opponentScore) to \(gameResult.currentUserScore) in Edwin."
                    }
                } else {
                    // Draw
                    shareText = "I just played a draw against \(gameResult.opponentDisplayName) in Edwin. We both scored \(gameResult.currentUserScore) points."
                }
            }
            
            let activitySheet = UIActivityViewController(activityItems: [shareText, gameResult.gameEndScreenshot], applicationActivities: nil)
            self.presentViewController(activitySheet, animated: true, completion: nil)
        }
    }

    
    
    

    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.PopToMainMenuFromGameOver {
            MWLog("Preparing for PopToMainMenuFromGameOver")
        }
    }
    
}
