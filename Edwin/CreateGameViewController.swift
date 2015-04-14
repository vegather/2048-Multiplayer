//
//  CreateGameViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 06/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class CreateGameViewController: UIViewController {
    
    private var numberOfPlayers: Players!
    private var dimension: Int!
    private var turnDuration: Int!
    
    @IBOutlet weak var dimensionPreviewLabel: UILabel!
    @IBOutlet weak var dimensionStepper: UIStepper!
    
    @IBOutlet weak var turnDurationLabel: UILabel!
    @IBOutlet weak var turnDurationStepper: UIStepper!
    @IBOutlet weak var turnDurationPreviewLabel: UILabel!
    
    @IBOutlet weak var numberOfPlayersSegmentedControl: UISegmentedControl!
    
    
    
    typealias D = TileValue
    
    
    // -------------------------------
    // MARK: View Controller Life Cycle
    // -------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dimension = Int(dimensionStepper.value)
        dimensionPreviewLabel.text = "\(dimension) x \(dimension)"
        
        turnDuration = Int(turnDurationStepper.value)
        turnDurationPreviewLabel.text = "\(turnDuration) sec"
        
        numberOfPlayersSegmentedControl.selectedSegmentIndex = 1
        let playersSegmentedIndex = numberOfPlayersSegmentedControl.selectedSegmentIndex
        if numberOfPlayersSegmentedControl.selectedSegmentIndex == 0 {
            numberOfPlayers = Players.Single
        } else {
            numberOfPlayers = Players.Multi
        }
        
        let font = UIFont(name: "AvenirNext-Regular", size: 14)!
        let attributes = [NSFontAttributeName as NSObject : font as AnyObject]
        numberOfPlayersSegmentedControl.setTitleTextAttributes(attributes, forState: UIControlState.Normal)
    }
    
    
    
    // -------------------------------
    // MARK: Actions
    // -------------------------------

    @IBAction func dimensionsStepperDidChange(sender: UIStepper) {
        dimension = Int(sender.value)
        dimensionPreviewLabel.text = "\(dimension) x \(dimension)"
    }
    
    @IBAction func durationStepperDidChange(sender: UIStepper) {
        turnDuration = Int(sender.value)
        turnDurationPreviewLabel.text = "\(turnDuration) sec"
    }
    
    @IBAction func numberOfPlayersDidChange(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            numberOfPlayers = Players.Single
            
            turnDurationLabel.alpha = 0.3
            turnDurationStepper.enabled = false
            turnDurationStepper.alpha = 0.3
            turnDurationPreviewLabel.alpha = 0.3
        } else {
            numberOfPlayers = Players.Multi
            
            turnDurationLabel.alpha = 1.0
            turnDurationStepper.enabled = true
            turnDurationStepper.alpha = 1.0
            turnDurationPreviewLabel.alpha = 1.0
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Segue Management
    // -------------------------------
    
    @IBAction func createGameButtonTapped() {
        self.performSegueWithIdentifier(SegueIdentifier.PushGameFromCreateGame, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.PushGameFromCreateGame {
            if let destination = segue.destinationViewController as? GameViewController {
//                destination.prepareGameSetup(self.currentGameSetup())
                destination.prepareGameSetup(currentGameSetup())
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func currentGameSetup() -> GameSetup<D> {
        let setup = GameSetup<D>(
            players: self.numberOfPlayers,
            setupForCreating: true,
            dimension: self.dimension,
            turnDuration: self.turnDuration)
        
        return setup
    }
}
