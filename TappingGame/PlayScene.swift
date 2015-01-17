//
//  PlayScene.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/6/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit
import iAd

// Four unique masks to identify the bodies that come into contact
enum ColliderType:UInt32 {
    case Death = 0
    case Player = 0xFFFFFFFF
    case Bottom = 0b001
    case Platform = 0b010
}

class PlayScene: SKScene, SKPhysicsContactDelegate, ADBannerViewDelegate {
    
    var increaseDifficulty1 = true
    var increaseDifficulty2 = true
    var increaseDifficulty3 = true
    
    var player = SKSpriteNode(imageNamed: "player")
    var platformTexture = SKTexture(imageNamed: "platform-1")
    var bottom = SKSpriteNode()
    var grid = SKNode()
    var scoreLabel = SKLabelNode()
    var iPhoneModel: Int!
    
    var kFirstPathX = CGFloat()
    var kSecondPathX = CGFloat()
    var playerPositionX = CGFloat()
    
    var highScore = 0
    var defaults = NSUserDefaults()
    var score = 0
    
    var difficulty = 5
        
    override func didMoveToView(view: SKView) {
        
        // Set up background
        var background: SKSpriteNode!
        if iPhoneModel == 4  || iPhoneModel == 5 {
            background = SKSpriteNode(imageNamed: String(format: "background-%d", iPhoneModel))
        }
        else {
            background = SKSpriteNode(imageNamed: "background")
        }
        
        background.position = CGPointMake(self.size.width / 2, self.size.height / 2)
        background.zPosition = -100
        self.addChild(background)
        
        // Setup the initial play scene with some platforms alreay on the screen, and the player
        let addAndMove = SKAction.runBlock({ self.setup() })
        let addAndMove7 = SKAction.repeatAction(addAndMove, count: 7)
        self.runAction(addAndMove7)
        
        // Grid node in charge of all other moving sprites
        self.addChild(grid)
        
        // To remove any platform or enemy that goes off screen
        self.initializeBottom()
        
        // Get previous high score
        highScore = defaults.integerForKey("highScore")
        
        // Presnt score label
        scoreLabel.text = "\(score)"
        scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.size.height * 0.7)
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = UIColor.redColor()
        self.addChild(scoreLabel)
        
        //Physics
        self.physicsWorld.contactDelegate = self
        
        // Paths for character position and spawn locations
        kFirstPathX = (CGRectGetMidX(self.frame) - (self.frame.width / 4))
        kSecondPathX = (CGRectGetMidX(self.frame) + (self.frame.width / 4))
        
        // Initialize the Player
        self.initializePlayer()
        
    }

    // If any two objects come into contact, this function is called.
    // If category Death and category Player come into contact, the game ends.
    // If Death OR Sprite come into contact with category Bottom, then the spritenode is removed from the parent.
    func didBeginContact(contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch contactMask {
        case ColliderType.Death.rawValue | ColliderType.Player.rawValue:
            died()
        case ColliderType.Platform.rawValue | ColliderType.Bottom.rawValue:
            if contact.bodyA.categoryBitMask == ColliderType.Platform.rawValue {
                var thisSprite = contact.bodyA.node as SKSpriteNode
                thisSprite.removeFromParent()
            }
            else {
                var thisSprite = contact.bodyB.node as SKSpriteNode
                thisSprite.removeFromParent()
            }
        case ColliderType.Death.rawValue | ColliderType.Bottom.rawValue:
            if contact.bodyA.categoryBitMask == ColliderType.Death.rawValue {
                var thisSprite = contact.bodyA.node as SKSpriteNode
                thisSprite.removeFromParent()
            }
            else {
                var thisSprite = contact.bodyB.node as SKSpriteNode
                thisSprite.removeFromParent()
            }
        default:
            println("Error: unexpected contact \(contactMask)")
        }
    }
    
    // Change the player's position based on the touch location
    // Move all platforms and enemies down by their size + 10 (gap)
    // Spawn 2 more sprites, update the score
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        movePlayer(touches)
        
        movePlatforms(grid.children)
        
        spawnSomething()
        
        updateScore()
    }
    
    // Moves every node on the screen down by its size and a gap
    func movePlatforms(children: [AnyObject]) {
        for child in children {
            let thisSprite = child as SKSpriteNode
            var newPosition = CGPointMake(thisSprite.position.x, thisSprite.position.y - thisSprite.size.height - (thisSprite.size.height * 0.2))
            thisSprite.position = newPosition
        }
    }
    
    // Moves player based on where the user touches
    func movePlayer(touches: NSSet) {
        for touch in touches {
            let thisPosition:CGPoint = touch.locationInNode(self)
            
            if thisPosition.x < CGRectGetMidX(self.frame) {
                player.position.x = kFirstPathX
            }
            else if thisPosition.x > CGRectGetMidX(self.frame) {
                player.position.x = kSecondPathX
            }
        }
    }
    
    // This function will be called a few times when the game first starts up to populate the screen with platforms.
    func setup() {
        movePlatforms(grid.children)
        
        var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
        leftSprite.name = "Platform"
        leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height)
        leftSprite.zPosition = -5
        leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.height / 2)
        leftSprite.physicsBody?.affectedByGravity = false
        leftSprite.physicsBody?.dynamic = false
        leftSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
        leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
        leftSprite.physicsBody?.collisionBitMask = 0
        grid.addChild(leftSprite)
        
        var rightSprite = SKSpriteNode(imageNamed: getRandomPlatform())
        rightSprite.name = "Platform"
        rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height)
        rightSprite.zPosition = -5
        rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.height / 2)
        rightSprite.physicsBody?.affectedByGravity = false
        rightSprite.physicsBody?.dynamic = false
        rightSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
        rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
        rightSprite.physicsBody?.collisionBitMask = 0
        grid.addChild(rightSprite)
    }
    
    // Takes the user to the main screen again after updating the highscore, and reporting to leaderboards
    // Might want to change this so it takes them to a screen displaying score, share, store, etc.
    func died() {
        
        // Update the high score if higher than previous high score
        if score > highScore {
            highScore = score
            NSUserDefaults().setInteger(highScore, forKey: "highscore")
            saveLeaderBoardScore("score_leaderboard", recievedScore: highScore)
        }
        
        // Present the "Play again?" scene
        var scene = GameOverScene(size: self.size)
        let skView = self.view as SKView!
        skView?.ignoresSiblingOrder = true
        scene.scaleMode = .ResizeFill
        scene.size = skView.bounds.size
        scene.iPhoneModel = self.iPhoneModel
        let transition = SKTransition.moveInWithDirection(SKTransitionDirection.Up, duration: 0.5)
        skView.presentScene(scene, transition: transition)
        
        // Remove all children and actions from the scene
        let delay = SKAction.waitForDuration(1.0)
        let deallocAction = SKAction.runBlock({ self.deallocate() })
        self.runAction(SKAction.sequence([delay, deallocAction]))
    }
    
    // Spawns two sprite nodes, one on the left and one on the right.
    // An "enemy" can only spawn on one side, not both
    // Variable 'difficulty' changes based on user's score, it dictates how often we have an enemy
    func spawnSomething() {
        
        let whereIsEnemy = arc4random_uniform(UInt32(difficulty))
        
        // Enemy on the right
        if whereIsEnemy == 0 {
            var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            leftSprite.name = "Platform"
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height)
            leftSprite.zPosition = -5
            leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.height / 2)
            leftSprite.physicsBody?.affectedByGravity = false
            leftSprite.physicsBody?.dynamic = false
            leftSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            leftSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(leftSprite)
            
            var rightSprite = SKSpriteNode(imageNamed: getRandomEnemy())
            rightSprite.name = "Death"
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height)
            rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.height / 2)
            rightSprite.physicsBody?.affectedByGravity = false
            //rightSprite.physicsBody?.dynamic = false
            rightSprite.physicsBody?.categoryBitMask = ColliderType.Death.rawValue
            rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue | ColliderType.Player.rawValue
            rightSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(rightSprite)
        }
        // Enemy on the left
        else if whereIsEnemy == 1 {
            var leftSprite = SKSpriteNode(imageNamed: getRandomEnemy())
            leftSprite.name = "Death"
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height)
            leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.height / 2)
            leftSprite.physicsBody?.affectedByGravity = false
            //leftSprite.physicsBody?.dynamic = false
            leftSprite.physicsBody?.categoryBitMask = ColliderType.Death.rawValue
            leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue | ColliderType.Player.rawValue
            leftSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(leftSprite)
            
            var rightSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            rightSprite.name = "Platform"
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height)
            rightSprite.zPosition = -5
            rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.height / 2)
            rightSprite.physicsBody?.affectedByGravity = false
            rightSprite.physicsBody?.dynamic = false
            rightSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            rightSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(rightSprite)
        }
        // No enemy
        else {
            var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            leftSprite.name = "Platform"
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height)
            leftSprite.zPosition = -5
            leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.height / 2)
            leftSprite.physicsBody?.affectedByGravity = false
            leftSprite.physicsBody?.dynamic = false
            leftSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            leftSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(leftSprite)
            
            var rightSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            rightSprite.name = "Platform"
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height)
            rightSprite.zPosition = -5
            rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.height / 2)
            rightSprite.physicsBody?.affectedByGravity = false
            rightSprite.physicsBody?.dynamic = false
            rightSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            rightSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(rightSprite)
            
        }
    }
    
    func initializePlayer() {
        player.position = CGPointMake(kFirstPathX, getBottomPlatformY(platformTexture.size().height))
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
        player.name = "Player"
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.dynamic = false
        player.physicsBody?.categoryBitMask = ColliderType.Player.rawValue
        player.physicsBody?.contactTestBitMask = ColliderType.Death.rawValue
        player.physicsBody?.collisionBitMask = 0
        self.addChild(player)
    }
    
    func initializeBottom() {
        bottom.name = "Bottom"
        bottom.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame))
        bottom.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, 1))
        bottom.physicsBody?.affectedByGravity = false
        bottom.physicsBody?.categoryBitMask = ColliderType.Bottom.rawValue
        bottom.physicsBody?.contactTestBitMask = ColliderType.Platform.rawValue | ColliderType.Death.rawValue
        bottom.physicsBody?.collisionBitMask = 0
        self.addChild(bottom)
    }
    
    func getBottomPlatformY(size: CGFloat) -> CGFloat {
        var yPosition = CGRectGetMaxY(self.frame) + (size/2)
        while (yPosition - size - (size * 0.2) - (size/2) > 0) {
            yPosition -= size - (size * 0.2) - (size/2)
        }
        return yPosition
    }
    
    // Returns a random image name for a platform
    func getRandomPlatform() -> String {
        let randomNumber = arc4random_uniform(UInt32(3)) + 1
        var ret = String(format: "platform-%d", randomNumber)
        return ret
    }
    
    // Returns a random image name for an "enemy" aka Death
    func getRandomEnemy() -> String {
        //let randomNumber = arc4random_uniform(UInt32(3))
        var ret = String(format: "enemy-%d", 1)
        return ret
    }
    
    // Updates score and the score label
    func updateScore() {
        score++
        scoreLabel.text = "\(score)"
    }
    
    // Reports score to leaderboard
    func saveLeaderBoardScore(leaderBoardID:String, recievedScore:Int){
        GCHelper.sharedInstance.reportLeaderboardIdentifier(leaderBoardID, score: recievedScore)
    }
    
    // Increase the chance of enemy platforms spawning after score of 100,200, and 300
    override func update(currentTime: NSTimeInterval) {
        if score == 100 && increaseDifficulty1 {
            increaseDifficulty1 = false
            difficulty--
            println("Difficulty is now \(difficulty)")
        }
        else if score == 200 && increaseDifficulty2 {
            increaseDifficulty2 = false
            difficulty--
            println("Difficulty is now \(difficulty)")
        }
        else if score == 300 && increaseDifficulty3 {
            increaseDifficulty3 = false
            difficulty--
            println("\(difficulty)")
        }
    }

    func deallocate() {
        grid.removeAllChildren()
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    // Whenever a touch ends...
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        
    }
    
    
}