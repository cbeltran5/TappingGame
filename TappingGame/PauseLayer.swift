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
    var soundButton: SKSpriteNode!
    var muteEffectsButton: SKSpriteNode!
    var musicLabel: SKSpriteNode!
    var soundLabel: SKSpriteNode!
    var delegate: PauseLayerDelegate?
    var defaults = NSUserDefaults()
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    convenience init(typeofLayer: String, texture: SKTexture!, color: UIColor!, size: CGSize) {
        self.init(texture: nil, color: color, size: size)
        
        var layer = SKSpriteNode(texture: texture)
        layer.position = CGPointMake(0, 0)
        layer.zPosition = 50
        self.addChild(layer)
        
        musicLabel = SKSpriteNode(imageNamed: "musicLabel")
        musicLabel.position = CGPointMake(-15, musicLabel.size.height/2)
        musicLabel.zPosition = 100
        self.addChild(musicLabel)
        
        soundLabel = SKSpriteNode(imageNamed: "soundLabel")
        soundLabel.position = CGPointMake(musicLabel.position.x, -musicLabel.size.height/2)
        soundLabel.zPosition = 100
        self.addChild(soundLabel)
        
        resumeButton = SKSpriteNode(imageNamed: "resumeButton")
        resumeButton.position = CGPointMake(0, soundLabel.position.y - resumeButton.size.height * 0.85)
        resumeButton.zPosition = 100
        self.addChild(resumeButton)
        
        let musicIsMuted = defaults.boolForKey("musicIsMuted")
        let soundIsMuted = defaults.boolForKey("effectsAreMuted")
        
        musicButton = SKSpriteNode(imageNamed: "muteIcon")
        musicButton.position = CGPointMake(layer.frame.maxX - musicButton.size.width * 1.7, musicLabel.position.y)
        musicButton.zPosition = 100
        self.addChild(musicButton)
        
        soundButton = SKSpriteNode(imageNamed: "muteIcon")
        soundButton.position = CGPointMake(layer.frame.maxX - soundButton.size.width * 1.7, soundLabel.position.y)
        soundButton.zPosition = 100
        self.addChild(soundButton)
        
        if musicIsMuted == true {
            musicButton.alpha = 0.5
        }
        if soundIsMuted == true {
            soundButton.alpha = 0.5
        }
        
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition: CGPoint = (touch as! UITouch).locationInNode(self)
            if self.nodeAtPoint(thisPosition) == self.resumeButton {
                self.delegate?.resumeButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == musicButton {
                self.delegate?.muteMusicButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == self.soundButton {
                // mute sounds
                self.delegate?.muteEffectsButtonPressed()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
