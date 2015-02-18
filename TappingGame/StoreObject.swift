//
//  StoreObject.swift
//  TappingGame
//
//  Created by Carlos Beltran on 2/17/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

class StoreObject {
    var key: String!
    var name: String!
    var preRequisite: String
    var isUnlocked: Bool
    
    init(key: String, name: String, preRequisite: String) {
        self.name = name
        self.key = key
        self.isUnlocked = false
        self.preRequisite = preRequisite
    }
    
    func unlock() {
        self.isUnlocked = true
    }
}