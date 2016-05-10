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
    @IBOutlet weak var numberOfPlayersLabel: UILabel!
    
    var shouldCreateGameWithoutUser = false {
        didSet {
            updateWithOrWithoutUserState()
        }
    }
    
    private func updateWithOrWithoutUserState() {
        if shouldCreateGameWithoutUser {
            numberOfPlayersSegmentedControl.selectedSegmentIndex = 0
            numberOfPlayersDidChange(numberOfPlayersSegmentedControl)
            
            numberOfPlayersLabel.alpha = 0.3
            numberOfPlayersSegmentedControl.alpha = 0.3
            numberOfPlayersSegmentedControl.enabled = false
        } else {
            numberOfPlayersLabel.alpha = 1.0
            numberOfPlayersSegmentedControl.alpha = 1.0
            numberOfPlayersSegmentedControl.enabled = true
        }
    }
    
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
        
        numberOfPlayersSegmentedControl.selectedSegmentIndex = 0

        if numberOfPlayersSegmentedControl.selectedSegmentIndex == 0 {
            numberOfPlayers = Players.Single
        } else {
            numberOfPlayers = Players.Multi
        }
        
        updateButtonsState()
        updateWithOrWithoutUserState()
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
        updateButtonsState()
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
    
    func updateButtonsState() {
        if numberOfPlayersSegmentedControl.selectedSegmentIndex == 0 {
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
}
