//
//  ServerManager.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 05/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation
import UIKit

private let FIREBASE_URL = "https://project-edwin.firebaseio.com"

class ServerManager {
    class func dataBase() -> Firebase {
        return Firebase(url: FIREBASE_URL)
    }
}
