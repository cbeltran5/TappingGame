//
//  Meter.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/30/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

protocol MeterDelegate {
    func meterRanOut()
}

class Meter: SKSpriteNode {
    
    var count = Int()
    var textureArray:[SKTexture] = []
    var delegate: MeterDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        count = 12
        
        for var i = 1; i < 14; i++ {
            textureArray.append(SKTexture(imageNamed: String(format: "meter-%d", i)))
        }
    }
    
    // Meter decrements by one every second
    func beginTimer() {
        let delay = SKAction.waitForDuration(1)
        let decrement = SKAction.runBlock({ self.count -= 1  })
        let checkTimer = SKAction.runBlock({ self.checkTimer() })
        let delayThenDecrement = (SKAction.sequence([delay, decrement, checkTimer]))
        self.runAction(SKAction.repeatActionForever(delayThenDecrement))
    }
    
    // Changes the texure for meter as count decrements, lets the delegate know 
    // when count reaches 0
    func checkTimer() {
        switch count {
        case 12:
            self.texture = textureArray[0]
        case 11:
            self.texture = textureArray[1]
        case 10:
            self.texture = textureArray[2]
        case 9:
            self.texture = textureArray[3]
        case 8:
            self.texture = textureArray[4]
        case 7:
            self.texture = textureArray[5]
        case 6:
            self.texture = textureArray[6]
        case 5:
            self.texture = textureArray[7]
        case 4:
            self.texture = textureArray[8]
        case 3:
            self.texture = textureArray[9]
        case 2:
            self.texture = textureArray[10]
        case 1:
            self.texture = textureArray[11]
        case 0:
            self.texture = textureArray[12]
            self.delegate?.meterRanOut()
        default:
            return
        }
    }
    
    // Stops the meter from decrementing anymore.
    func stop() {
        self.removeAllActions()
    }
    
    // reset count and the texture
    func reset() {
        count = 12
        self.removeAllActions()
        self.texture = textureArray[0]
    }
    
    // Whever the player picks up a consumable
    func addToCount() {
        if count < 11 {
            count += 2
        }
        else {
            count++
        }
        self.checkTimer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
