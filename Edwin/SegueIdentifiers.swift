//
//  SegueIdentifiers.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 04/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

struct SegueIdentifier {
    // Push segue identifiers
    static let PushMainMenuFromLogin        = "Push Main Menu From Login"
    static let PushMainMenuFromCreateUser   = "Push Main Menu From Create User"
    static let PushCreateUser               = "Push Create User"
    static let PushCreateGame               = "Push Create Game"
    static let PushJoinGame                 = "Push Join Game"
    static let PushGameFromCreateGame       = "Push Game From Create Game"
    static let PushGameFromJoinGame         = "Push Game From Join Game"
    static let PushByPoppingToOverFromGame  = "Push By Popping To Game Over From Game"
    
    // Pop segue identifiers
    static let PopToLoginFromMainMenu       = "Pop To Login From Main Menu"
    static let PopToLoginFromCreateUser     = "Pop To Login From Create User"
    static let PopToMainMenuFromCreateGame  = "Pop To Main Menu From Create Game"
    static let PopToMainMenuFromJoinGame    = "Pop To Main Menu From Join Game"
    static let PopToMainMenuFromGameOver    = "Pop To Main Menu From Game Over"
}
