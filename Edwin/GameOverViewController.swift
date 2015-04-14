//
//  GameOverViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 06/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class GameOverViewController: UIViewController {

    @IBOutlet weak var gameWonLostLabel: UILabel!
    @IBOutlet weak var currentUserResultWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentPlayerResultBox: UIView!
    @IBOutlet weak var opponentResultBox: UIView!
    
    @IBOutlet weak var currentPlayerDisplayNameLabel: UILabel!
    @IBOutlet weak var currentPlayerScoreLabel: UILabel!
    @IBOutlet weak var opponentDisplayNameLabel: UILabel!
    @IBOutlet weak var opponentScoreLabel: UILabel!
    
    var preparedPlayers: Players?
    var preparedWon: Bool?
    var preparedCurrentUserScore: Int?
    var preparedOpponentScore: Int?
    var preparedCurrentUserDisplayName: String?
    var preparedOpponentDisplayName: String?
    
    // Need this becuase viewWillAppear gets called twice with current PushSegue
    var timesViewHasAppeared: Int = 0
    
    
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        timesViewHasAppeared++
        if timesViewHasAppeared == 1 {
            
            if let players = self.preparedPlayers {
                if let currentUserScore = self.preparedCurrentUserScore {
                    if let currentUserDisplayName = self.preparedCurrentUserDisplayName {
                        currentPlayerDisplayNameLabel.text = currentUserDisplayName
                        currentPlayerScoreLabel.text = "\(currentUserScore)"
                        
                        if players == Players.Single {
                            gameWonLostLabel.text = "Game Over"
                            
                            // Only need to show result for a single player, so removing opponent result box
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
                            self.view.setNeedsUpdateConstraints()
                            
                            self.opponentResultBox.hidden = true
                        } else {
                            // Multiplayer
                            if let opponentScore = self.preparedOpponentScore {
                                if let opponentDisplayName = self.preparedOpponentDisplayName {
                                    opponentDisplayNameLabel.text = opponentDisplayName
                                    opponentScoreLabel.text = "\(opponentScore)"
                                    
                                    if let won = self.preparedWon {
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
                }
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private API
    // -------------------------------
    
    // Set won, opponentScore and opponentDisplayName to nil for single player
    func prepare(#players:      Players,
        won:                    Bool?,
        currentUserScore:       Int,
        opponentScore:          Int?,
        currentUserDisplayName: String,
        opponentDisplayName:    String?)
    {
        MWLog()
        
        self.preparedPlayers = players
        self.preparedWon = won
        self.preparedCurrentUserScore = currentUserScore
        self.preparedOpponentScore = opponentScore
        self.preparedCurrentUserDisplayName = currentUserDisplayName
        self.preparedOpponentDisplayName = opponentDisplayName
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
