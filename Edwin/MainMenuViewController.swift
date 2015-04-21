//
//  MainMenuViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 04/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController {
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.PopToLoginFromMainMenu {
            // Prepare logout
            UserServerManager.logout()
            MWLog("Will exit main menu")
        } else if segue.identifier == SegueIdentifier.PushCreateGame {
            // Prepare create game
            MWLog("Will present create game")
        } else if segue.identifier == SegueIdentifier.PushJoinGame {
            // Prepare join game
            MWLog("Will present join game")
        } else if segue.identifier == SegueIdentifier.PushAccount {
            // Prepare Account
            MWLog("Will present Account")
        }
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        
        if let id = identifier {
            
            if id == SegueIdentifier.PopToMainMenuFromCreateGame ||
               id == SegueIdentifier.PopToMainMenuFromJoinGame   ||
               id == SegueIdentifier.PopToMainMenuFromGameOver   ||
               id == SegueIdentifier.PopToMainMenuFromAccount    ||
               id == SegueIdentifier.PopToMainMenuFromGame
            {
                MWLog("Providing unwind segue for popping back to the main menu")
                let unwindSegue = PopSegue(identifier: id,
                    source: fromViewController,
                    destination: toViewController,
                    performHandler: { () -> Void in
                })
                return unwindSegue
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    @IBAction func returnToMainMenuFromSegueAction(sender: UIStoryboardSegue){
        if sender.identifier == SegueIdentifier.PopToMainMenuFromCreateGame {
            // Came back from create user
            MWLog("Came back from Create Game")
        } else if sender.identifier == SegueIdentifier.PopToMainMenuFromJoinGame {
            // Came back from main menu
            MWLog("Came back from Join Game")
        } else if sender.identifier == SegueIdentifier.PopToMainMenuFromGameOver {
            // Came back from Game Over
            MWLog("Came back from Game Over")
        } else if sender.identifier == SegueIdentifier.PopToMainMenuFromAccount {
            // Came back from Account
            MWLog("Came back from Account")
        } else if sender.identifier == SegueIdentifier.PopToMainMenuFromGame {
            // Cancelled a game before it started
            MWLog("Came back from Game before it even started")
        }
    }

}
