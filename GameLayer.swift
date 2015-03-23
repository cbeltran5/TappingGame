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
    func storeButtonPressed()
    func removeAdsButtonPressed()
}

class GameLayer: SKSpriteNode {
    
    var playButton:SKSpriteNode!
    var leaderboardsButton: SKSpriteNode!
    var storeButton: SKSpriteNode!
    var twitterButton: SKSpriteNode!
    var removeAdsButton: SKSpriteNode!
    var layerType: String!
    var delegate: GameLayerDelegate?
    
    var highScoreLabel: SKSpriteNode!
    var scoreLabel: SKSpriteNode!
    var score: Int?
    var highScore: Int?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    // Initializes the layer 
    // Two different layer types: GameStart and GameOver
    // They just display different information
    convenience init(typeofLayer: String, texture: SKTexture!, color: UIColor!, size: CGSize) {
        
        self.init(texture: nil, color: color, size: size)
        
        layerType = typeofLayer
        
        playButton = SKSpriteNode(imageNamed: "playButton")
        playButton.position = CGPointMake(0, (-UIScreen.mainScreen().bounds.height/2) + playButton.size.height/2 + 10)
        playButton.zPosition = 100
        self.addChild(playButton)
        
        leaderboardsButton = SKSpriteNode(imageNamed: "leaderboardsButton")
        leaderboardsButton.position = CGPointMake(0 - (UIScreen.mainScreen().bounds.width / 2) + (leaderboardsButton.size.width), playButton.position.y)
        leaderboardsButton.zPosition = 100
        self.addChild(leaderboardsButton)
        
        storeButton = SKSpriteNode(imageNamed: "storeButton")
        storeButton.position = CGPointMake(0 + (UIScreen.mainScreen().bounds.width / 2) - (storeButton.size.width), playButton.position.y)
        storeButton.zPosition = 100
        self.addChild(storeButton)
        
        // Custom layer stuff
        if typeofLayer == "GameStart" {
            var layer = SKSpriteNode(texture: texture)
            layer.position = CGPointMake(self.position.x, self.position.y + (playButton.size.height * 0.6))
            layer.zPosition = 100
            self.addChild(layer)
            
            // Add title of game
            var gameTitle = SKSpriteNode(imageNamed: "gameTitle")
            gameTitle.position = CGPointMake(0, (layer.frame.maxY - gameTitle.size.height * 0.7))
            gameTitle.zPosition = 115
            self.addChild(gameTitle)
            
            // Add remove ads button if the user hasn't purchased the IAP
            var purchased = NSUserDefaults.standardUserDefaults().boolForKey("removeAdsPurchased")
            if purchased == false {
                removeAdsButton = SKSpriteNode(imageNamed: "removeAdsButton")
                removeAdsButton.position = CGPointMake(0, layer.frame.minY + removeAdsButton.size.height * 1.6)
                removeAdsButton.zPosition = 115
                self.addChild(removeAdsButton)
            }
            
        }
        else if typeofLayer == "GameOver" {
            var layer = SKSpriteNode(texture: texture)
            layer.position = CGPointMake(self.position.x, self.position.y + (playButton.size.height * 0.6))
            layer.zPosition = 100
            self.addChild(layer)
            
            // Add game over text
            var gameOverTitle = SKSpriteNode(imageNamed: "gameOverTitle")
            gameOverTitle.position = CGPointMake(0, layer.frame.maxY - gameOverTitle.size.height * 0.65 )
            gameOverTitle.zPosition = 115
            self.addChild(gameOverTitle)
            
            // Add high score label
            highScoreLabel = SKSpriteNode(imageNamed: "highScoreLabel")
            highScoreLabel.position = CGPointMake(0, gameOverTitle.frame.minY - highScoreLabel.size.height * 0.7)
            highScoreLabel.zPosition = 115
            highScoreLabel.setScale(0.7)
            self.addChild(highScoreLabel)
            
            // Add score label
            scoreLabel = SKSpriteNode(imageNamed: "scoreLabel")
            scoreLabel.position = CGPointMake(0, highScoreLabel.position.y - scoreLabel.size.height * 1.5)
            scoreLabel.zPosition = 115
            scoreLabel.setScale(0.7)
            self.addChild(scoreLabel)
            
            // Add twitter button
            twitterButton = SKSpriteNode(imageNamed: "twitterButton")
            twitterButton.position = CGPointMake(layer.frame.minX + twitterButton.size.width, layer.frame.minY + twitterButton.size.height - 9)
            twitterButton.zPosition = 115
            self.addChild(twitterButton)
        }
    }
    
    // Sets the label for the score and high score
    func setScores() {
        // Display high score
        var highScoreNumber = BitMapFontLabel(text: "\(highScore!)", fontName: "number-", usingAtlas: "number")
        highScoreNumber.position = CGPointMake(0, highScoreLabel.position.y - highScoreLabel.size.height)
        highScoreNumber.zPosition = 115
        if UIScreen.mainScreen().bounds.size.height == 736 {
            highScoreNumber.setScale(1.75)
        }
        else {
            highScoreNumber.setScale(1.5)
        }
        self.addChild(highScoreNumber)
        
        // Display score
        var scoreNumber = BitMapFontLabel(text: "\(score!)", fontName: "number-", usingAtlas: "number")
        scoreNumber.position = CGPointMake(0, scoreLabel.position.y - scoreLabel.size.height)
        scoreNumber.zPosition = 115
        if UIScreen.mainScreen().bounds.size.height == 736 {
            scoreNumber.setScale(1.75)
        }
        else {
            scoreNumber.setScale(1.5)
        }
        self.addChild(scoreNumber)
        
    }
    
    // Register the different button presses
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition: CGPoint = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == playButton {
                delegate?.playButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == leaderboardsButton {
                delegate?.leaderboardsButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == storeButton {
                delegate?.storeButtonPressed()
            }
            else if layerType == "GameOver" && self.nodeAtPoint(thisPosition) == twitterButton {
                delegate?.twitterButtonPressed()
            }
            else if layerType == "GameStart" && self.nodeAtPoint(thisPosition) == removeAdsButton? {
                delegate?.removeAdsButtonPressed()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
