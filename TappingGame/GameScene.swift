//
//  GameScene.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/5/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import SpriteKit
import GameKit

class GameScene: SKScene {
    
    var playButton = SKSpriteNode(imageNamed: "PlayButton")
    var leaderBoardsButton = SKSpriteNode(imageNamed: "LeaderboardsButton")
    var viewController: UIViewController!
    
    // I didn't know how else to do it :(
    let iPhone4Height = CGFloat(480)
    let iPhone5Height = CGFloat(568)
    let iPhone6Height = CGFloat(667)
    var iPhoneModel = Int()
    
    override func didMoveToView(view: SKView) {
        
        // :'(
        if self.view?.frame.height == iPhone4Height {
            iPhoneModel = 4
        }
        else if self.view?.frame.height == iPhone5Height {
            iPhoneModel = 5
        }
        else if self.view?.frame.height == iPhone6Height {
            // use default background.
            iPhoneModel = 6
        }
        
        // Play button
        playButton.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame) + playButton.size.height)
        self.addChild(playButton)
        
        // Leaderboards button
        leaderBoardsButton.position = CGPointMake(CGRectGetMidX(self.frame) - playButton.size.width - 10, CGRectGetMinY(self.frame) + leaderBoardsButton.size.height)
        self.addChild(leaderBoardsButton)
    }
    
    // Whenever the user touches something on the screen...
    // We can grab its location (of the touch)...
    // And grab the sprite in that area
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            if self.nodeAtPoint(location) == playButton {
                var scene = PlayScene(size: self.size)
                let skView = self.view as SKView!
                skView.ignoresSiblingOrder = true
                scene.scaleMode = .ResizeFill
                scene.size = skView.bounds.size
                // :'(
                scene.iPhoneModel = self.iPhoneModel
                
                let sceneTransition = SKTransition.pushWithDirection(SKTransitionDirection.Left, duration: 0.6)
                skView.presentScene(scene, transition: sceneTransition)
                self.removeAllChildren()
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
