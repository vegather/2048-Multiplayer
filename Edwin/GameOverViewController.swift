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
    
    var gameResult: GameResult?
    
    // Need this becuase viewWillAppear gets called twice with current PushSegue
    var timesViewHasAppeared: Int = 0
    
    
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        timesViewHasAppeared++
        if timesViewHasAppeared == 1 {
            
            if let gameResult = gameResult {
                currentPlayerDisplayNameLabel.text = gameResult.currentUserDisplayName
                currentPlayerScoreLabel.text = "\(gameResult.currentUserScore)"
                
                if gameResult.players == Players.Single {
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

    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.PopToMainMenuFromGameOver {
            MWLog("Preparing for PopToMainMenuFromGameOver")
        }
    }
    
}
