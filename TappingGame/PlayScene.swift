//
//  PlayScene.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/6/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit
import GameKit
import iAd
import Social
import AVFoundation

// Four unique masks to identify the bodies that come into contact
enum ColliderType:UInt32 {
    case Death = 0
    case Player = 0xFFFFFFFF
    case Bottom = 0b001
    case Platform = 0b010
}

class PlayScene: SKScene, SKPhysicsContactDelegate, ADBannerViewDelegate, GameLayerDelegate, PauseLayerDelegate {
    
    // I didn't know how else to do it :(
    let iPhone4Height = CGFloat(480)
    let iPhone5Height = CGFloat(568)
    let iPhone6Height = CGFloat(667)
    
    var viewController: GameViewController!
    
    var increaseDifficulty1 = true
    var increaseDifficulty2 = true
    var increaseDifficulty3 = true
    
    var player = SKSpriteNode(imageNamed: "player-still_01")
    var playerStillFrames: [SKTexture] = []
    var playerJumpLeftFrames: [SKTexture] = []
    var playerJumpRightFrames: [SKTexture] = []
    var playerJumpUpFrames: [SKTexture] = []
    
    var platformTexture = SKTexture(imageNamed: "platform-1")
    var bottom = SKNode()
    var grid = SKNode()
    var background: SKSpriteNode!
    var scoreLabel = SKLabelNode()
    var iPhoneModel: Int!
    
    var kFirstPathX = CGFloat()
    var kSecondPathX = CGFloat()
    
    var highScore = 0
    var defaults = NSUserDefaults()
    var score = 0
    
    var difficulty = 5
    var musicIsMuted: Bool!
    var effectsAreMuted: Bool!
    var game_started:Bool!
    var game_ended: Bool!
    var gameStartLayer: GameLayer!
    var gameOverLayer: GameLayer!
    var gamePauseLayer: PauseLayer!
    var gameLayerTexture = SKTexture(imageNamed: "gameLayer")
    var gamePauseTexture = SKTexture(imageNamed: "pauseLayer")
    
    var playButton: SKSpriteNode!
    var leaderboardsButton: SKSpriteNode!
    var twitterButton: SKSpriteNode!
    var pauseButton: SKSpriteNode!
    var storeButton: SKSpriteNode!
    
    var backgroundMusic = AVAudioPlayer()
    var introMusic = AVAudioPlayer()
    
//    // Sets default values to some settings
//    override init() {
//        super.init()
//        let defaultData: NSDictionary = ["musicIsMuted": false, "effectsAreMuted": false, "highScore": 0]
//        defaults.registerDefaults(defaultData)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func didMoveToView(view: SKView) {
        
        userInteractionEnabled = false
        
        let setupPlatforms = SKAction.runBlock({ self.setup_platforms() })
        let setupPlayer = SKAction.runBlock({ self.initializePlayer() })
        self.runAction(SKAction.sequence([setupPlatforms, setupPlayer]))
        
        game_started = false
        game_ended = false
        
        // Set up background
        setup_background()
        
        // Grid node in charge of all other moving sprites
        self.addChild(grid)
        
        // To remove any platform or enemies that goes off screen
        self.initializeBottom()
        
        // Get user high score and settings and set some defaults in case they don't exist
        highScore = defaults.integerForKey("highScore")
        musicIsMuted = defaults.boolForKey("musicIsMuted")
        effectsAreMuted = defaults.boolForKey("effectsAreMuted")
        
        // Add score label
        scoreLabel.text = "\(score)"
        scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.size.height * 0.7)
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = UIColor.redColor()
        self.addChild(scoreLabel)
        
        // Add pause button
        pauseButton = SKSpriteNode(imageNamed: "pauseButton")
        pauseButton.position = CGPointMake(scoreLabel.position.x, scoreLabel.position.y - scoreLabel.frame.size.height)
        pauseButton.zPosition = 100
        self.addChild(pauseButton)
        
        //Physics
        self.physicsWorld.contactDelegate = self
        
        // Paths for character position and spawn locations
        kFirstPathX = (CGRectGetMidX(self.frame) - (self.frame.width / 4))
        kSecondPathX = (CGRectGetMidX(self.frame) + (self.frame.width / 4))
        
        game_started = true
        
        setupAllAudio()
        
        presentGameStartLayer()
        
        if musicIsMuted == false {
            introMusic.play()
        }
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
            break;
        }
    }
    
    // Stop the player bobbing. Change the player's position based on the touch location
    // Move all platforms and enemies down by their size + 10 (gap)
    // Spawn 2 more sprites, update the score
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if game_started == true {
            
            for touch in touches {
                if self.nodeAtPoint(touch.locationInNode(self)) == pauseButton {
                    self.userInteractionEnabled = false
                    player.paused = true
                    presentGamePauseLayer()
                    return
                }
            }
            
            self.removeActionForKey("playerOnStandby")
            
            movePlayer(touches)
            
            movePlatforms(grid.children)
            
            spawnSomething()
            
            updateScore()
        }
    }
    
    // Moves every node on the screen down by its size and a gap
    func movePlatforms(children: [AnyObject]) {
        for child in children {
            let thisSprite = child as SKSpriteNode
            var newY = CGFloat(thisSprite.position.y - thisSprite.size.height - (thisSprite.size.height * 0.1))
            thisSprite.position.y = newY
        }
    }
    
    // Moves player based on where the user touches
    func movePlayer(touches: NSSet) {
        for touch in touches {
            let thisPosition:CGPoint = touch.locationInNode(self)
            var playerPosition = round(player.position.x * 100)/100
            if thisPosition.x < CGRectGetMidX(self.frame) {
                if playerPosition != kFirstPathX {
                    var jumpRightAction = SKAction.animateWithTextures(playerJumpRightFrames, timePerFrame: 0.05, resize: false, restore: true)
                    player.runAction(jumpRightAction, withKey: "jump")
                }
                player.position.x = kFirstPathX
            }
            else if thisPosition.x > CGRectGetMidX(self.frame) {
                if playerPosition != kSecondPathX {
                    var jumpLeftAction = SKAction.animateWithTextures(playerJumpLeftFrames, timePerFrame: 0.05, resize: false, restore: true)
                    player.runAction(jumpLeftAction, withKey: "jump")
                }
                player.position.x = kSecondPathX
            }
        }
    }
    
    // This function will be called a few times when the game first starts up to populate the screen with platforms.
    func setup() {
        movePlatforms(grid.children)
        
        var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
        leftSprite.name = "Platform"
        leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height * 0.75 )
        leftSprite.zPosition = -5
        leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.width / 2)
        leftSprite.physicsBody?.affectedByGravity = false
        leftSprite.physicsBody?.dynamic = false
        leftSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
        leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
        leftSprite.physicsBody?.collisionBitMask = 0
        grid.addChild(leftSprite)
        
        var rightSprite = SKSpriteNode(imageNamed: getRandomPlatform())
        rightSprite.name = "Platform"
        rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height * 0.75 )
        rightSprite.zPosition = -5
        rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.width / 2)
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
        if musicIsMuted == false {
            backgroundMusic.stop()
            backgroundMusic.currentTime = 0
        }
        self.userInteractionEnabled = false
        game_started = false
        game_ended = true
        presentGameOverLayer()
        
        // Update the high score if higher than previous high score
        if score > highScore {
            highScore = score
            NSUserDefaults().setInteger(highScore, forKey: "highscore")
            saveLeaderBoardScore("score_leaderboard", recievedScore: highScore)
        }
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
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height * 0.75)
            leftSprite.zPosition = -5
            leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.width / 2)
            leftSprite.physicsBody?.affectedByGravity = false
            leftSprite.physicsBody?.dynamic = false
            leftSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            leftSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(leftSprite)
            
            var rightSprite = SKSpriteNode()
            rightSprite.name = "Death"
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height + leftSprite.size.height * 0.2)
            rightSprite.zPosition = -5
            rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.width / 2)
            rightSprite.size.height = leftSprite.size.height
            rightSprite.physicsBody?.affectedByGravity = false
            rightSprite.physicsBody?.categoryBitMask = ColliderType.Death.rawValue
            rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue | ColliderType.Player.rawValue
            rightSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(rightSprite)
        }
        // Enemy on the left
        else if whereIsEnemy == 1 {
            var rightSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            rightSprite.name = "Platform"
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height * 0.75)
            rightSprite.zPosition = -5
            rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.width / 2)
            rightSprite.physicsBody?.affectedByGravity = false
            rightSprite.physicsBody?.dynamic = false
            rightSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            rightSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(rightSprite)
            
            var leftSprite = SKSpriteNode()
            leftSprite.name = "Death"
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height + rightSprite.size.height * 0.2)
            leftSprite.zPosition = -5
            leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.width / 2)
            leftSprite.size.height = rightSprite.size.height
            leftSprite.physicsBody?.affectedByGravity = false
            leftSprite.physicsBody?.categoryBitMask = ColliderType.Death.rawValue
            leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue | ColliderType.Player.rawValue
            leftSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(leftSprite)
        }
        // No enemy
        else {
            var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            leftSprite.name = "Platform"
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height * 0.75)
            leftSprite.zPosition = -5
            leftSprite.physicsBody = SKPhysicsBody(circleOfRadius: leftSprite.size.width / 2)
            leftSprite.physicsBody?.affectedByGravity = false
            leftSprite.physicsBody?.dynamic = false
            leftSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            leftSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            leftSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(leftSprite)
            
            var rightSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            rightSprite.name = "Platform"
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height * 0.75)
            rightSprite.zPosition = -5
            rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.width / 2)
            rightSprite.physicsBody?.affectedByGravity = false
            rightSprite.physicsBody?.dynamic = false
            rightSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            rightSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(rightSprite)
            
        }
    }
    
    // Initialize the player and its atlases for animations
    func initializePlayer() {
        var playerStillAtlas = SKTextureAtlas(named: "player-still")
        var playerJumpLeftAtlas = SKTextureAtlas(named: "player-left")
        var playerJumpRightAtlas = SKTextureAtlas(named: "player-right")
        var playerJumpUpAtlas = SKTextureAtlas(named: "player-jump")
        
        for (var i = 1; i <= playerStillAtlas.textureNames.count; i++) {
            var textureName = String(format: "player-still_0%d", i)
            var texture = SKTexture(imageNamed: textureName)
            playerStillFrames.append(texture)
        }
        for (var i = 2; i <= playerJumpLeftAtlas.textureNames.count; i++ ) {
            var textureName = String(format: "player-left_0%d", i)
            var texture = SKTexture(imageNamed: textureName)
            playerJumpLeftFrames.append(texture)
        }
        for (var i = 2; i <= playerJumpRightAtlas.textureNames.count; i++ ) {
            var textureName = String(format: "player-right_0%d", i)
            var texture = SKTexture(imageNamed: textureName)
            playerJumpRightFrames.append(texture)
        }
        for (var i = 1; i <= playerJumpUpAtlas.textureNames.count; i++ ) {
            var textureName = String(format: "player-jump_0%d", i)
            var texture = SKTexture(imageNamed: textureName)
            playerJumpUpFrames.append(texture)
        }
        
        player.position = CGPointMake(kFirstPathX, getBottomPlatformY())
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
        player.name = "Player"
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.dynamic = false
        player.physicsBody?.categoryBitMask = ColliderType.Player.rawValue
        player.physicsBody?.contactTestBitMask = ColliderType.Death.rawValue
        player.physicsBody?.collisionBitMask = 0
        self.addChild(player)
        self.playerStandby()
    }
    
    // Animates the player while idle
    func playerStandby() {
        var delay = SKAction.waitForDuration(0.4)
        var standbyAction = SKAction.repeatActionForever(SKAction.sequence([delay, SKAction.animateWithTextures(playerStillFrames, timePerFrame: 0.15, resize: false, restore: true)]))
        player.runAction(standbyAction, withKey: "playerOnStandby")
    }
    
    // Initialize the node that will remove the sprites that go off screen
    func initializeBottom() {
        bottom.name = "Bottom"
        bottom.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame) - 80)
        bottom.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, 10))
        bottom.physicsBody?.affectedByGravity = false
        bottom.zPosition = -5
        bottom.physicsBody?.categoryBitMask = ColliderType.Bottom.rawValue
        bottom.physicsBody?.contactTestBitMask = ColliderType.Platform.rawValue | ColliderType.Death.rawValue
        bottom.physicsBody?.collisionBitMask = 0
        self.addChild(bottom)
    }
    
    // Sets up the background
    func setup_background() {
        background = SKSpriteNode(imageNamed: "background")
        background.position = CGPointMake(self.size.width / 2, self.size.height / 2)
        background.zPosition = -100
        self.addChild(background)
    }
    
    // Setup the initial play scene with some platforms alreay on the screen, and the player
    func setup_platforms() {
        let addAndMove = SKAction.runBlock({ self.setup() })
        let addAndMove7 = SKAction.repeatAction(addAndMove, count: 7)
        self.runAction(addAndMove7)
    }
    
    // Sets up all audio for the game, TODO: change depending on user defaults
    func setupAllAudio() {
        backgroundMusic = self.setupAudioPlayerWithFile("Track-1", type: "mp3")
        backgroundMusic.volume = 0.05
        
        introMusic = self.setupAudioPlayerWithFile("Intro", type: "mp3")
        introMusic.numberOfLoops = -1
        introMusic.volume = 0.05
    }
    
    // Helper function that returns the avaudioplayer we specify
    func setupAudioPlayerWithFile(file: NSString, type: NSString) -> AVAudioPlayer {
        var path = NSBundle.mainBundle().pathForResource(file, ofType: type)
        var url = NSURL.fileURLWithPath(path!)
        var error: NSError?
        var audioPlayer: AVAudioPlayer?
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        return audioPlayer!
    }
    
    // It's supposed to get the y position of the bottom-most platform
    func getBottomPlatformY() -> CGFloat {
        var lowestY = self.frame.height
        for child in self.grid.children {
            let thisPlatform = child as SKSpriteNode
            if thisPlatform.position.y < lowestY && thisPlatform.position.y > -40 {
                lowestY = thisPlatform.position.y
            }
        }
        return lowestY + (platformTexture.size().height * 0.64)
    }
    
    // Returns a random image name for a platform
    func getRandomPlatform() -> String {
        let randomNumber = arc4random_uniform(UInt32(2)) + 1
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
        }
        else if score == 200 && increaseDifficulty2 {
            increaseDifficulty2 = false
            difficulty--
        }
        else if score == 300 && increaseDifficulty3 {
            increaseDifficulty3 = false
            difficulty--
        }
    }
    
    // Presents the game center
    func leaderboardsButtonPressed() {
        GCHelper.sharedInstance.showGameCenter(viewController, viewState: GKGameCenterViewControllerState.Leaderboards)
    }
    
    // Allows the user to share an image of their score along with a link to the game
    func twitterButtonPressed() {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
            var twitterSheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitterSheet.setInitialText("Try beating me! #doyoueven")
            twitterSheet.addImage(takeScreenShotToShare())
            viewController.presentViewController(twitterSheet, animated: true, completion: nil)
        }
        else {
            var alert = UIAlertController(title: "Accounts", message: "Please log in to a Twitter account to share", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // Dismisses the game over screen and resets the scene
    func playButtonPressed() {
        self.userInteractionEnabled = true
        if game_started == true {
            dismissLayer(gameStartLayer)
            if musicIsMuted == false {
                introMusic.stop()
                backgroundMusic.play()
            }
        }
        else if game_ended == true {
            if musicIsMuted == false {
                backgroundMusic.play()
            }
            dismissLayer(gameOverLayer)
            let resetScene = SKAction.runBlock({ self.resetScene() })
            let delay = SKAction.waitForDuration(0.2)
            self.runAction(SKAction.sequence([delay, resetScene]))
            game_started = true
            game_ended = false
        }
    }
    
    // Starts the game with the game layer (play button, leaderboards, store, twitter, game logo)
    func presentGameStartLayer() {
        gameStartLayer = GameLayer(typeofLayer:"GameStart", texture: gameLayerTexture, color: nil, size: gameLayerTexture.size())
        gameStartLayer.delegate = self
        gameStartLayer.position = CGPointMake(self.frame.midX, UIScreen.mainScreen().bounds.minY + gameStartLayer.size.height * 0.7)
        gameStartLayer.zPosition = 100
        gameStartLayer.userInteractionEnabled = true
        self.addChild(gameStartLayer)
    }
    
    // Presents a screen where user is given details about score and is given the option to play again
    func presentGameOverLayer() {
        
        gameOverLayer = GameLayer(typeofLayer: "GameOver", texture: gameLayerTexture, color: nil, size: gameLayerTexture.size())
        gameOverLayer.delegate = self
        gameOverLayer.position = CGPointMake(self.frame.midX, UIScreen.mainScreen().bounds.maxY + gameOverLayer.size.height/2)
        gameOverLayer.zPosition = 100
        gameOverLayer.userInteractionEnabled = true
        self.addChild(gameOverLayer)
        
        twitterButton = SKSpriteNode(imageNamed: "twitterButton")
        twitterButton.position = CGPointMake(0, 0 - (gameOverLayer.size.height / 2) + (twitterButton.size.height * 0.8))
        twitterButton.zPosition = 100
        gameOverLayer.twitterButton = self.twitterButton
        gameOverLayer.addChild(twitterButton)
        
        let moveDown = SKAction.moveToY(UIScreen.mainScreen().bounds.minY + gameStartLayer.size.height * 0.7, duration: 0.4)
        gameOverLayer.runAction(moveDown)
    }
    
    // Removes the game over screen from the screen and resets the scene
    func dismissLayer(screen: SKSpriteNode) {
        let moveUp = SKAction.moveToY(self.frame.maxY + screen.frame.size.height, duration: 0.4)
        let removeChildren = SKAction.runBlock { () -> Void in
            screen.removeAllChildren()
        }
        let removeSelf = SKAction.runBlock { () -> Void in
            screen.removeFromParent()
        }
        screen.runAction(SKAction.sequence([moveUp, removeChildren, removeSelf]))
    }
    
    // Presents a pause screen when the user presses the pause button
    func presentGamePauseLayer() {
        gamePauseLayer = PauseLayer(typeofLayer: "GamePaused", texture: gamePauseTexture, color: nil, size: gamePauseTexture.size())
        gamePauseLayer.delegate = self
        gamePauseLayer.position = CGPointMake(UIScreen.mainScreen().bounds.midX, UIScreen.mainScreen().bounds.height + gamePauseLayer.size.height)
        gamePauseLayer.zPosition = 100
        gamePauseLayer.userInteractionEnabled = true
        self.addChild(gamePauseLayer)
        
        let moveDown = SKAction.moveToY(UIScreen.mainScreen().bounds.midY, duration: 0.4)
        gamePauseLayer.runAction(moveDown)
    }
    
    func resumeButtonPressed() {
        dismissLayer(gamePauseLayer)
        self.userInteractionEnabled = true
        player.paused = false
    }
    
    // Mutes the sound effects
    func muteEffectsButtonPressed() {
        
    }
    
    // Changes the user's background music preferences
    func muteMusicButtonPressed() {
        if musicIsMuted == false {
            backgroundMusic.stop()
            backgroundMusic.currentTime = 0
            musicIsMuted = true
            gamePauseLayer.musicButton.texture = SKTexture(imageNamed: "muteImage")
        }
        else if musicIsMuted == true {
            backgroundMusic.play()
            musicIsMuted = false
            gamePauseLayer.musicButton.texture = SKTexture(imageNamed: "notMuteImage")
        }
        
        defaults.setBool(musicIsMuted, forKey: "musicIsMuted")
    }

    // Resets the score, re-initializes platforms and the player
    func resetScene() {
        resetScoreAndDifficulty()
        grid.removeAllChildren()
        player.position.x = kFirstPathX
        setup_platforms()
    }
    
    // Resets the score, the score label, the difficulty, and grabs the newest high score
    func resetScoreAndDifficulty() {
        difficulty = 5
        increaseDifficulty1 = true
        increaseDifficulty2 = true
        increaseDifficulty3 = true
        highScore = defaults.integerForKey("highScore")
        score = 0
        scoreLabel.text = "\(score)"
    }
    
    // Takes a screenshot for the player to share high score to twitter
    func takeScreenShotToShare() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, 0);
        viewController.view.drawViewHierarchyInRect(viewController.view.bounds, afterScreenUpdates: true)
        var image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
    
    // Whenever a touch ends...
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if game_started == true {
            player.runAction(SKAction.sequence([ SKAction.waitForDuration(0.2),SKAction.runBlock({ () -> Void in
                self.player.removeActionForKey("jump")
                //self.player.texture = self.playerStillFrames[0]
            })]))
            self.playerStandby()
        }
    }
    
    // Should save the user settings right before app is suspended...?
    override func willMoveFromView(view: SKView) {
        defaults.setBool(musicIsMuted, forKey: "musicIsMuted")
        defaults.setBool(effectsAreMuted, forKey: "effectsAreMuted")
    }
}