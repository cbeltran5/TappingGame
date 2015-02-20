//
//  StoreObject.swift
//  TappingGame
//
//  Created by Carlos Beltran on 2/17/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// A Store object contains a key to the object, as well as some information for how to display it
class StoreObject {
    var key: String!            // A String we can use to access in other places
    var name: String!           // The String to be displayed on-screen for the name
    var preRequisite: String    // To be displayed on screen, what is required to unlock
    var isUnlocked: Bool        // Is this object unlocked
    var canSelect: Bool         // Can the user select this item
    
    init(key: String, name: String, preRequisite: String) {
        self.name = name
        self.key = key
        self.isUnlocked = false
        self.preRequisite = preRequisite
        self.canSelect = false
    }
    
    func unlock() {
        self.isUnlocked = true
    }
}