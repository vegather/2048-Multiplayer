//
//  JoinGameViewController.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 06/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class JoinGameViewController: UIViewController {

    @IBOutlet weak var gamePinTextField: UITextField!
    @IBOutlet weak var underJoinGameButtonConstraint: NSLayoutConstraint!
    
    var initialUnderJoinGameButtonConstraintConstant: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialUnderJoinGameButtonConstraintConstant = underJoinGameButtonConstraint.constant
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        gamePinTextField.resignFirstResponder()
    }

    // Animate button from keyboard frame

}
