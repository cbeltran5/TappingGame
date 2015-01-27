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
    var leaderBoardsButton: SKSpriteNode!
    var storeButton: SKSpriteNode!
    var twitterButton: SKSpriteNode!
    var delegate: GameLayerDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition: CGPoint = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == playButton {
                delegate?.playButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == leaderBoardsButton {
                delegate?.leaderboardsButtonPressed()
            }
            else if self.nodeAtPoint(thisPosition) == twitterButton {
                delegate?.twitterButtonPressed()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
