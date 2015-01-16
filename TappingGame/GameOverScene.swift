//
//  GameOverScene.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/12/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit
import GameKit

class GameOverScene: SKScene {
    
    var playButton = SKSpriteNode(imageNamed: "PlayButton")
    var leaderBoardsButton = SKSpriteNode(imageNamed: "LeaderboardsButton")
    var viewController: UIViewController!
    
    override func didMoveToView(view: SKView) {
        // Play button
        playButton.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame) + playButton.size.height)
        self.addChild(playButton)
        
        // Leaderboards button
        leaderBoardsButton.position = CGPointMake(CGRectGetMidX(self.frame) - playButton.size.width - 10, CGRectGetMinY(self.frame) + leaderBoardsButton.size.height)
        self.addChild(leaderBoardsButton)
        
        // Set viewController as root view controller
        viewController = self.view?.window?.rootViewController
        
        self.backgroundColor = UIColor(rgba: "#81D8FF")
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            if self.nodeAtPoint(location) == playButton {
                var scene = PlayScene(size: self.size)
                let skView = self.view as SKView!
                skView.ignoresSiblingOrder = true
                scene.scaleMode = .ResizeFill
                scene.size = skView.bounds.size
                
                let sceneTransition = SKTransition.revealWithDirection(SKTransitionDirection.Up, duration: 0.5)
                skView.presentScene(scene, transition: sceneTransition)
            }
            else if self.nodeAtPoint(location) == leaderBoardsButton {
                GCHelper.sharedInstance.showGameCenter(viewController, viewState: GKGameCenterViewControllerState.Leaderboards)
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
}