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
    var musicButton: SKSpriteNode!
    var muteEffectsButton: SKSpriteNode!
    var musicLabel: SKSpriteNode!
    var delegate: PauseLayerDelegate?
    var defaults = NSUserDefaults()
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    convenience init(typeofLayer: String, texture: SKTexture!, color: UIColor!, size: CGSize) {
        self.init(texture: texture, color: color, size: size)
        
        resumeButton = SKSpriteNode(imageNamed: "resumeButton")
        resumeButton.position = CGPointMake(0, -self.size.height/2 + resumeButton.size.height)
        resumeButton.zPosition = 100
        self.addChild(resumeButton)
        
        musicLabel = SKSpriteNode(imageNamed: "musicLabel")
        musicLabel.position = CGPointMake(-musicLabel.size.width/2, musicLabel.size.height)
        musicLabel.zPosition = 100
        self.addChild(musicLabel)
        
        let musicIsMuted = defaults.boolForKey("musicIsMuted")
        if musicIsMuted == true {
            musicButton = SKSpriteNode(imageNamed: "muteImage")
            musicButton.position = CGPointMake(musicButton.size.width, musicLabel.position.y)
            musicButton.zPosition = 100
            self.addChild(musicButton)
        }
        else {
            musicButton = SKSpriteNode(imageNamed: "notMuteImage")
            musicButton.position = CGPointMake(musicButton.size.width, musicLabel.position.y)
            musicButton.zPosition = 100
            self.addChild(musicButton)
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition: CGPoint = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == self.resumeButton {
                self.delegate?.resumeButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == musicButton {
                self.delegate?.muteMusicButtonPressed()
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
