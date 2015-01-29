//
//  GameLayer.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/17/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

protocol GameLayerDelegate {
    func playButtonPressed()
    func leaderboardsButtonPressed()
    func twitterButtonPressed()
}

class GameLayer: SKSpriteNode {
    
    var playButton:SKSpriteNode!
    var leaderboardsButton: SKSpriteNode!
    var storeButton: SKSpriteNode!
    var twitterButton: SKSpriteNode!
    var layerType: String!
    var delegate: GameLayerDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(typeofLayer: String, texture: SKTexture!, color: UIColor!, size: CGSize) {
        
        if typeofLayer == "GameStart" {
            self.init(texture: nil, color: color, size: size) }
        else {
            self.init(texture: texture, color: color, size: size) }
        layerType = typeofLayer
        
        playButton = SKSpriteNode(imageNamed: "playButton")
        playButton.position = CGPointMake(0, -(self.size.height / 2) - playButton.size.height * 0.7)
        playButton.zPosition = 100
        self.addChild(playButton)
        
        leaderboardsButton = SKSpriteNode(imageNamed: "leaderboardsButton")
        leaderboardsButton.position = CGPointMake(0 - (self.size.width / 2) + (leaderboardsButton.size.width / 2), playButton.position.y)
        leaderboardsButton.zPosition = 100
        self.addChild(leaderboardsButton)
        
        storeButton = SKSpriteNode(imageNamed: "storeButton")
        storeButton.position = CGPointMake(0 + (self.size.width / 2) - (storeButton.size.width / 2), playButton.position.y)
        storeButton.zPosition = 100
        self.addChild(storeButton)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition: CGPoint = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == playButton {
                delegate?.playButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == leaderboardsButton {
                delegate?.leaderboardsButtonPressed()
            }
            else if layerType == "GameOver" && self.nodeAtPoint(thisPosition) == twitterButton {
                delegate?.twitterButtonPressed()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
