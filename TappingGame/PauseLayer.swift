//
//  PauseLayer.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/26/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

protocol PauseLayerDelegate {
    func resumeButtonPressed()
    func muteMusicButtonPressed()
    func muteEffectsButtonPressed()
}

class PauseLayer: SKSpriteNode {
    
    var resumeButton: SKSpriteNode!
    var muteMusicButton: SKSpriteNode!
    var muteEffectsButton: SKSpriteNode!
    var delegate: PauseLayerDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition: CGPoint = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == self.resumeButton {
                self.delegate?.resumeButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == muteMusicButton {
                self.delegate?.muteMusicButtonPressed()
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
