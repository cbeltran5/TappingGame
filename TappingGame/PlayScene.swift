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

extension String {
    
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
}

// Four unique masks to identify the bodies that come into contact
enum ColliderType:UInt32 {
    case Death = 0x01
    case Player = 0x02
    case Bottom = 0x04
    case Platform = 0x08
    case Consumable = 0x10
}

class PlayScene: SKScene, SKPhysicsContactDelegate, ADBannerViewDelegate, GameLayerDelegate, PauseLayerDelegate, StoreLayerDelegate, MeterDelegate {
    
    var viewController: GameViewController!
    
    var increaseDifficulty1 = true
    var increaseDifficulty2 = true
    var increaseDifficulty3 = true
    
    var player = SKSpriteNode(imageNamed: "player-still")
    
    var platformTexture = SKTexture(imageNamed: "platform-1")
    var bottom = SKNode()
    var grid = SKNode()
    var background: SKSpriteNode!
    var scoreLabel: BitMapFontLabel!
    
    var kFirstPathX = CGFloat()
    var kSecondPathX = CGFloat()
    var playerPositionY = CGFloat()
    var stepLeft = true
    
    var highScore = 0
    var defaults = NSUserDefaults()
    var score = 0
    
    var meter: Meter!
    var meterTexture = SKTexture(imageNamed: "meter-1")
    
    var difficulty = 5
    var spawnDecider = 4
    var musicIsMuted: Bool!
    var effectsAreMuted: Bool!
    var game_started:Bool!
    var game_ended: Bool!
    var demoMusicIsPlaying = false
    var gameStartLayer: GameLayer!
    var gameOverLayer: GameLayer!
    var gamePauseLayer: PauseLayer!
    var gameStoreLayer: StoreLayer!
    var gameOverTexture = SKTexture(imageNamed: "gameOverLayer")
    var gameStartTexture = SKTexture(imageNamed: "gameStartLayer")
    var storeTexture = SKTexture(imageNamed: "storeLayer")
    var gamePauseTexture = SKTexture(imageNamed: "pauseLayer")
    var tapFrames: [SKTexture] = []
    var tapSprite2: SKSpriteNode!
    var tapSprite1: SKSpriteNode!
    var isTapDisplayed: Bool = false
    
    var playButton: SKSpriteNode!
    var leaderboardsButton: SKSpriteNode!
    var twitterButton: SKSpriteNode!
    var pauseButton: SKSpriteNode!
    var storeButton: SKSpriteNode!
    
    var backgroundMusic = AVAudioPlayer()
    var introMusic = AVAudioPlayer()
    var demoMusic = AVAudioPlayer()
    var sideStep = AVAudioPlayer()
    var deathSound = AVAudioPlayer()
    var popSound = AVAudioPlayer()
    
    var storeItems: [StoreObject] = []
    var storeDictionary = [String: StoreObject]()
    
    var rateMinSessions = 3
    var rateTryAgainSessions = 6
    
    override func didMoveToView(view: SKView) {
        userInteractionEnabled = false
        
        setupStoreObjects()
        
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
        
        setupPlayInterface()
        
        //Physics
        self.physicsWorld.contactDelegate = self
        
        // Paths for character position and spawn locations
        kFirstPathX = (CGRectGetMidX(self.frame) - (self.frame.width / 4))
        kSecondPathX = (CGRectGetMidX(self.frame) + (self.frame.width / 4))
        
        // The tap indicators
        var tapAtlas = SKTextureAtlas(named: "tap")
        for (var i = 0; i < tapAtlas.textureNames.count; i++) {
            var imageName = tapAtlas.textureNames[i] as String
            var texture = SKTexture(imageNamed: imageName)
            tapFrames.append(texture)
        }
        
        setupAllAudio()
        
        presentGameStartLayer(false)
        
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
            // Run an animation first
            self.userInteractionEnabled = false
            var dieAnimation = SKAction.animateWithTextures([SKTexture(imageNamed: "player-float")], timePerFrame: 1.0, resize: false, restore: false)
            var fallAction = SKAction.moveToY(-(UIScreen.mainScreen().bounds.height * 0.7), duration: 0.5)
            self.runAction(SKAction.sequence([SKAction.runBlock({ self.player.runAction(dieAnimation) }), SKAction.runBlock({ self.died() })]))
            
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
        case ColliderType.Player.rawValue | ColliderType.Consumable.rawValue:
            meter.addToCount()
            if effectsAreMuted == false {
                popSound.play()
            }
            if contact.bodyA.categoryBitMask == ColliderType.Player.rawValue {
                var thisSprite = contact.bodyB.node as SKSpriteNode
                thisSprite.removeFromParent()
            }
            else {
                var thisSprite = contact.bodyA.node as SKSpriteNode
                thisSprite.removeFromParent()
            }
        case ColliderType.Consumable.rawValue | ColliderType.Bottom.rawValue:
            if contact.bodyA.categoryBitMask == ColliderType.Consumable.rawValue {
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
    // Move all platforms down
    // Spawn more platforms, update the score
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if game_started == true {
            
            if isTapDisplayed == true {
                tapSprite1?.removeFromParent()
                tapSprite2?.removeFromParent()
                meter.beginTimer()
                isTapDisplayed = false
            }
            
            for touch in touches {
                if self.nodeAtPoint(touch.locationInNode(self)) == pauseButton {
                    pauseGame();
                    return
                }
            }
            
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
            let size = platformTexture.size().height
            var newY = CGFloat(thisSprite.position.y - size - (size * 0.1))
            thisSprite.position.y = newY
        }
    }
    
    // Chooses some step for the player to take.
    func someStep() -> String {
        if stepLeft == true {
            stepLeft = false
            return "player-jump-1"
        }
        else {
            stepLeft = true
            return "player-jump-2"
        }
    }
    
    // Moves player based on where the user touches
    func movePlayer(touches: NSSet) {
        for touch in touches {
            let thisPosition:CGPoint = touch.locationInNode(self)
            var playerPosition = round(player.position.x * 100)/100
            if thisPosition.x < CGRectGetMidX(self.frame) {
                if playerPosition != kFirstPathX {
                    self.playerTransitionTo("jumpLeft")
                    player.position.x = kFirstPathX
                    if effectsAreMuted == false {
                        sideStep.play()
                    }
                }
                else {
                    player.runAction(SKAction.animateWithTextures([SKTexture(imageNamed: someStep())], timePerFrame: 0.1, resize: false, restore: true))
                }
            }
            else if thisPosition.x > CGRectGetMidX(self.frame) {
                if playerPosition != kSecondPathX {
                    self.playerTransitionTo("jumpRight")
                    player.position.x = kSecondPathX
                    if effectsAreMuted == false {
                        sideStep.play()
                    }
                }
                else {
                    player.runAction(SKAction.animateWithTextures([SKTexture(imageNamed: someStep())], timePerFrame: 0.1, resize: false, restore: true))
                }
            }
        }
    }
    
    // This function will be called a few times when the game first starts up to populate the screen with platforms.
    func setup() {
        movePlatforms(grid.children)
        
        var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
        leftSprite.name = "Platform"
        leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height * 0.70 )
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
        rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height * 0.70 )
        rightSprite.zPosition = -5
        rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.width / 2)
        rightSprite.physicsBody?.affectedByGravity = false
        rightSprite.physicsBody?.dynamic = false
        rightSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
        rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
        rightSprite.physicsBody?.collisionBitMask = 0
        grid.addChild(rightSprite)
    }
    
    // Brings a game over layer into the view
    // Displays score, high score, and gives option to play again, show leaderboards, tweet, or go to store
    func died() {
        
        meter.stop()
        hideInterface()
        
        if musicIsMuted == false {
            backgroundMusic.volume -= 0.02
        }
        
        if effectsAreMuted == false {
            deathSound.play()
        }
        
        self.userInteractionEnabled = false
        game_ended = true
        presentGameOverLayer()
        
        // Update the high score if higher than previous high score
        if score > highScore {
            highScore = score
            NSUserDefaults().setInteger(highScore, forKey: "highScore")
            saveLeaderBoardScore("score_leaderboard", recievedScore: highScore)
        }
    }
    
    // Spawns two sprite nodes, one on the left and one on the right.
    // An "enemy" can only spawn on one side, not both, an enemy is just a hole the player can fall through
    // Variable 'difficulty' changes based on user's score, it dictates how often we have an 'enemy'
    func spawnSomething() {
        let whereIsEnemy = arc4random_uniform(UInt32(difficulty))
        // Enemy on the right
        if whereIsEnemy == 0 {
            var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            leftSprite.name = "Platform"
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height * 0.70)
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
            
            if shouldConsumableSpawn() == true {
                spawnConsumable(leftSprite.position)
            }
        }
        // Enemy on the left
        else if whereIsEnemy == 1 {
            var rightSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            rightSprite.name = "Platform"
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height * 0.70)
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
            
            if shouldConsumableSpawn() == true {
                spawnConsumable(rightSprite.position)
            }
        }
        // No enemy
        else {
            var leftSprite = SKSpriteNode(imageNamed: getRandomPlatform())
            leftSprite.name = "Platform"
            leftSprite.position = CGPointMake(kFirstPathX, CGRectGetMaxY(self.frame) + leftSprite.size.height * 0.70)
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
            rightSprite.position = CGPointMake(kSecondPathX, CGRectGetMaxY(self.frame) + rightSprite.size.height * 0.70)
            rightSprite.zPosition = -5
            rightSprite.physicsBody = SKPhysicsBody(circleOfRadius: rightSprite.size.width / 2)
            rightSprite.physicsBody?.affectedByGravity = false
            rightSprite.physicsBody?.dynamic = false
            rightSprite.physicsBody?.categoryBitMask = ColliderType.Platform.rawValue
            rightSprite.physicsBody?.contactTestBitMask = ColliderType.Bottom.rawValue
            rightSprite.physicsBody?.collisionBitMask = 0
            grid.addChild(rightSprite)
            
            if shouldConsumableSpawn() == true {
                if (arc4random_uniform(UInt32(2)) == 0) {
                    spawnConsumable(leftSprite.position)
                }
                else {
                    spawnConsumable(rightSprite.position)
                }
            }
        }
    }
    
    func beginGame() {
        game_started = true
        unhideInterface()
    }
    
    // Initialize the player and its atlases for animations
    func initializePlayer() {
        
        playerPositionY = getBottomPlatformY()
        player.position = CGPointMake(kFirstPathX, getBottomPlatformY())
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
        player.name = "Player"
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.dynamic = false
        player.physicsBody?.categoryBitMask = ColliderType.Player.rawValue
        player.physicsBody?.contactTestBitMask = ColliderType.Death.rawValue | ColliderType.Consumable.rawValue
        player.physicsBody?.collisionBitMask = 0
        self.addChild(player)
    }
    
    // Initialize the node that will remove the sprites that go off screen
    func initializeBottom() {
        bottom.name = "Bottom"
        bottom.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame) - 80)
        bottom.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, 10))
        bottom.physicsBody?.affectedByGravity = false
        bottom.zPosition = -5
        bottom.physicsBody?.categoryBitMask = ColliderType.Bottom.rawValue
        bottom.physicsBody?.contactTestBitMask = ColliderType.Platform.rawValue | ColliderType.Death.rawValue | ColliderType.Consumable.rawValue
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
    
    // Setup the initial play scene with some platforms alreay on the screen
    func setup_platforms() {
        let addAndMove = SKAction.runBlock({ self.setup() })
        let addAndMove7 = SKAction.repeatAction(addAndMove, count: 7)
        self.runAction(addAndMove7)
    }
    
    // Sets up all audio for the game, TODO: change depending on user defaults
    func setupAllAudio() {
        var songChoice = defaults.stringForKey("songChoice")
        if songChoice == nil {
            songChoice = "Song-1"
            defaults.setValue(songChoice, forKey: "songChoice")
        }
        
        var stringLength = countElements(songChoice!)
        var introString: String = String(format: "Intro-%@", songChoice![stringLength - 1])
        
        backgroundMusic = self.setupAudioPlayerWithFile(songChoice!, type: "aifc")
        backgroundMusic.numberOfLoops = -1
        backgroundMusic.volume = 0.05
        
        introMusic = self.setupAudioPlayerWithFile(introString, type: "aifc")
        introMusic.numberOfLoops = -1
        introMusic.volume = 0.05
        
        sideStep = self.setupAudioPlayerWithFile("Step-3", type: "caf")
        sideStep.volume = 0.25
        
        deathSound = self.setupAudioPlayerWithFile("Death-1", type: "caf")
        deathSound.volume = 0.03
        
        popSound = self.setupAudioPlayerWithFile("Blob-1", type: "caf")
        popSound.volume = 0.03
    }
    
    // Update the canSelect property for each item in the storeDictionary
    // Essentially, if it's not the one currently selected and it's not coming soon,
    // the user can select it.
    func updateAllChoices(currentlySelected: String) {
        for item in storeDictionary {
            if item.0 != currentlySelected && item.0 != "coming_soon" {
                item.1.canSelect = true
            }
            else if item.0 == currentlySelected {
                storeDictionary[currentlySelected]?.canSelect = false
            }
        }
    }
    
    // Updates the audio based on the user's new song selection
    func updateAudio(newSong: String) {
        backgroundMusic = self.setupAudioPlayerWithFile(newSong, type: "aifc")
        backgroundMusic.numberOfLoops = -1
        backgroundMusic.volume = 0.05
        
        var stringLength = countElements(newSong)
        var introString: String = String(format: "Intro-%@", newSong[stringLength - 1])
        
        introMusic = self.setupAudioPlayerWithFile(introString, type: "aifc")
        introMusic.numberOfLoops = -1
        introMusic.volume = 0.05
        
        if musicIsMuted == false {
            introMusic.play()
        }
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
    
    // Sets up the meter, the pause button, and the label for the score
    func setupPlayInterface() {
        
        scoreLabel = BitMapFontLabel(text: "0", fontName: "number-", usingAtlas: "number")
        if (UIScreen.mainScreen().bounds.size.height == 736) {
            scoreLabel.setScale(1.6)
        }
        else {
            scoreLabel.setScale(1.25)
        }
        
        scoreLabel.position = CGPointMake(UIScreen.mainScreen().bounds.midX, UIScreen.mainScreen().bounds.height * 0.8)
        self.addChild(scoreLabel)
        
        // Add pause button
        pauseButton = SKSpriteNode(imageNamed: "pauseButton")
        pauseButton.position = CGPointMake(scoreLabel.position.x, scoreLabel.position.y - pauseButton.size.height)
        pauseButton.zPosition = 25
        self.addChild(pauseButton)
        
        // Add meter
        meter = Meter(texture: meterTexture, color: nil, size: meterTexture.size())
        meter.position = CGPointMake(pauseButton.position.x, pauseButton.position.y - meter.size.height * 0.85)
        meter.zPosition = 25
        self.addChild(meter)
        meter.delegate = self
        
        scoreLabel.hidden = true
        pauseButton.hidden = true
        meter.hidden = true
    }
    
    func hideInterface() {
        scoreLabel.hidden = true
        pauseButton.hidden = true
        meter.hidden = true
    }
    
    func unhideInterface() {
        scoreLabel.hidden = false
        pauseButton.hidden = false
        meter.hidden = false
        
    }
    
    // Gets the y position of the bottom-most platfrom to place the player on
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
        let randomNumber = arc4random_uniform(UInt32(3)) + 1
        var ret = String(format: "platform-%d", randomNumber)
        return ret
    }
    
    // Determines whether aconsumable should spawn, pretty much a 50/50 chance every score of 5
    func shouldConsumableSpawn() -> Bool {
        if score % spawnDecider == 0 {
            let random = arc4random_uniform(UInt32(2))
            if random == 1 {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    func spawnConsumablesMoreOften() {
        spawnDecider = 3
    }
    
    // Spawns a consumable that will replenish the meter when the player touches it
    func spawnConsumable(position: CGPoint) {
        var consumable = SKSpriteNode(imageNamed: "consumable")
        consumable.physicsBody = SKPhysicsBody(circleOfRadius: consumable.size.width/4)
        consumable.physicsBody?.categoryBitMask = ColliderType.Consumable.rawValue
        consumable.physicsBody?.contactTestBitMask = ColliderType.Player.rawValue | ColliderType.Bottom.rawValue
        consumable.physicsBody?.affectedByGravity = false
        consumable.position = CGPointMake(position.x, position.y + platformTexture.size().height * 0.5)
        grid.addChild(consumable)
    }
    
    // Updates score and the score label
    func updateScore() {
        score++
        scoreLabel.setText("\(score)")
    }
    
    // Reports score to leaderboard
    func saveLeaderBoardScore(leaderBoardID:String, recievedScore:Int){
        GCHelper.sharedInstance.reportLeaderboardIdentifier(leaderBoardID, score: recievedScore)
    }
    
    // Increase the chance of empty spaces causing death to spawn after score of 100,200, and 300
    override func update(currentTime: NSTimeInterval) {
        if score == 100 && increaseDifficulty1 {
            increaseDifficulty1 = false
            difficulty--
        }
        else if score == 200 && increaseDifficulty2 {
            increaseDifficulty2 = false
            difficulty--
            self.spawnConsumablesMoreOften()
        }
        else if score == 300 && increaseDifficulty3 {
            increaseDifficulty3 = false
            difficulty--
            
            //Unlocked a new song!
            storeDictionary["Song-2"]?.isUnlocked = true
            defaults.setBool(true, forKey: "Song-2")
            println("Unlocked new song!")
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
            twitterSheet.setInitialText("I got \(score) in PlatJump! Can you do better?")
            twitterSheet.addImage(takeScreenShotToShare())
            viewController.presentViewController(twitterSheet, animated: true, completion: nil)
        }
        else {
            var alert = UIAlertController(title: "Accounts", message: "Please log in to a Twitter account to share", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // Dismisses the game layer 
    // If the game ended, resets the scene, otherwise just start the game for the first time
    func playButtonPressed() {
        self.userInteractionEnabled = true
        
        if game_started == false {
            dismissLayer(gameStartLayer)
            if musicIsMuted == false {
                introMusic.stop()
                backgroundMusic.play()
            }
            displayTapIndicators()
            beginGame()
        }
        else if game_ended == true {
            fadeInFadeOut()
            if musicIsMuted == false {
                backgroundMusic.volume += 0.02
            }
            dismissLayer(gameOverLayer)
            let resetScene = SKAction.runBlock({ self.resetScene() })
            let delay = SKAction.waitForDuration(0.2)
            let displayTapIndicators = SKAction.runBlock({ self.displayTapIndicators() })
            let unhideInterface = SKAction.runBlock({ self.unhideInterface() })
            self.runAction(SKAction.sequence([delay, resetScene, displayTapIndicators, unhideInterface]))
            game_started = true
            game_ended = false
        }
    }
    
    // Present the store layer when this button is pressed
    func storeButtonPressed() {
        if game_started == false {
            dismissLayer(gameStartLayer)
        }
        else {
            dismissLayer(gameOverLayer)
        }
        presentStoreLayer()
    }
    
    // Present a menu where the player can check the leaderboards in the game center, access the 'store',
    // purchase the 'Remove Ads' IAP, or start the game
    func presentGameStartLayer(animated: Bool) {
        gameStartLayer = GameLayer(typeofLayer:"GameStart", texture: gameStartTexture, color: nil, size: UIScreen.mainScreen().bounds.size)
        gameStartLayer.delegate = self
        gameStartLayer.userInteractionEnabled = true
        if animated == true {
            gameStartLayer.position = CGPointMake(self.frame.midX, UIScreen.mainScreen().bounds.maxY + gameStartLayer.size.height/2)
        }
        else {
            gameStartLayer.position = CGPointMake(self.frame.midX, UIScreen.mainScreen().bounds.minY + gameStartLayer.size.height * 0.5)
        }
        gameStartLayer.zPosition = 100
        self.addChild(gameStartLayer)
        
        if animated == true {
            let moveDown = SKAction.moveToY(UIScreen.mainScreen().bounds.midY, duration: 0.4)
            gameStartLayer.runAction(moveDown)
        }
    }
    
    // Presents a screen where user is given details about score, high score, is given the chance to post
    // to twitter as well as the main menu options
    func presentGameOverLayer() {
        
        gameOverLayer = GameLayer(typeofLayer: "GameOver", texture: gameOverTexture, color: nil, size: UIScreen.mainScreen().bounds.size)
        gameOverLayer.score = self.score
        if highScore < score {
            gameOverLayer.highScore = self.score
        }
        else {
            gameOverLayer.highScore = defaults.integerForKey("highScore")
        }
        gameOverLayer.setScores()
        gameOverLayer.delegate = self
        gameOverLayer.position = CGPointMake(self.frame.midX, UIScreen.mainScreen().bounds.maxY + gameOverLayer.size.height/2)
        gameOverLayer.zPosition = 100
        self.addChild(gameOverLayer)
        
        let moveDown = SKAction.moveToY(UIScreen.mainScreen().bounds.midY, duration: 0.4)
        gameOverLayer.runAction(SKAction.sequence([moveDown, SKAction.runBlock({ self.gameOverLayer.userInteractionEnabled = true }), SKAction.runBlock({ self.shouldLoadAd() })]))
    }
    
    // Removes the game layer screen
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
    
    // Presents a store layer where the user can choose other songs/art...
    func presentStoreLayer() {
        hideInterface()
        gameStoreLayer = StoreLayer(texture: storeTexture, color: nil, size: UIScreen.mainScreen().bounds.size)
        gameStoreLayer.delegate = self
        gameStoreLayer.position = CGPointMake(self.frame.midX, UIScreen.mainScreen().bounds.maxY + gameStoreLayer.size.height/2)
        gameStoreLayer.zPosition = 100
        gameStoreLayer.userInteractionEnabled = true
        self.addChild(gameStoreLayer)
        
        let moveDown = SKAction.moveToY(UIScreen.mainScreen().bounds.midY, duration: 0.4)
        gameStoreLayer.runAction(SKAction.sequence([SKAction.runBlock({ self.gameStoreLayer.storeItems = self.storeItems }), SKAction.runBlock({ self.gameStoreLayer.updateDisplay(0) }), moveDown]))
    }
    
    // Dismisses the game store layer and presents initial screen
    func selectButtonPressed(newChoice: String) {
        
        // Set the canSelect properties of the old selection and the new one
        storeDictionary[newChoice]?.canSelect = false
        
        var oldChoice = defaults.stringForKey("songChoice")
        storeDictionary[oldChoice!]?.canSelect = true
        
        // save settings
        defaults.setValue(newChoice, forKey: "songChoice")
        
        if demoMusicIsPlaying == true {
            demoMusicIsPlaying = false
            demoMusic.stop()
            demoMusic.currentTime = 0
        }
        
        
        // start new song
        updateAudio(newChoice)
        
        dismissLayer(gameStoreLayer)
        
        game_started = false
        game_ended = false
        fadeInFadeOut()
        let resetScene = SKAction.runBlock({ self.resetScene() })
        let delay = SKAction.waitForDuration(0.2)
        self.runAction(SKAction.sequence([delay, resetScene]))
        presentGameStartLayer(true)
        hideInterface()
    }
    
    // Lets the user briefly listen to whatever object they chose
    func listenButtonPressed(choice: String) {
        
        if introMusic.playing == true {
            introMusic.stop()
        }
        else if backgroundMusic.playing == true {
            backgroundMusic.stop()
        }
        demoMusicIsPlaying = true
        var stringLength = countElements(choice)
        var introSongString = String(format: "Intro-%@", choice[stringLength - 1])
        
        demoMusic = setupAudioPlayerWithFile(introSongString, type: "aifc")
        demoMusic.volume = 0.05
        demoMusic.play()
    }
    
    // Presents a pause screen when the user presses the pause button
    func presentGamePauseLayer() {
        gamePauseLayer = PauseLayer(typeofLayer: "GamePaused", texture: gamePauseTexture, color: nil, size: UIScreen.mainScreen().bounds.size)
        gamePauseLayer.delegate = self
        gamePauseLayer.position = CGPointMake(UIScreen.mainScreen().bounds.midX, UIScreen.mainScreen().bounds.midY)
        gamePauseLayer.zPosition = 100
        gamePauseLayer.userInteractionEnabled = true
        self.addChild(gamePauseLayer)
    }
    
    // Resumes the game
    func resumeButtonPressed() {
        dismissLayer(gamePauseLayer)
        unhideInterface()
        self.userInteractionEnabled = true
        player.paused = false
        meter.paused = false
    }
    
    // Mutes the sound effects
    func muteEffectsButtonPressed() {
        if effectsAreMuted == true {
            effectsAreMuted = false
            gamePauseLayer.soundButton.alpha = 1
        }
        else {
            effectsAreMuted = true
            gamePauseLayer.soundButton.alpha = 0.5
        }
        defaults.setBool(effectsAreMuted, forKey: "effectsAreMuted")
    }
    
    // Changes the user's background music preferences
    func muteMusicButtonPressed() {
        if musicIsMuted == false {
            backgroundMusic.stop()
            backgroundMusic.currentTime = 0
            musicIsMuted = true
            gamePauseLayer.musicButton.alpha = 0.5
        }
        else if musicIsMuted == true {
            backgroundMusic.play()
            musicIsMuted = false
            gamePauseLayer.musicButton.alpha = 1
        }
        
        defaults.setBool(musicIsMuted, forKey: "musicIsMuted")
    }

    // Resets the score, re-initializes platforms and the player
    func resetScene() {
        resetScoreAndDifficulty()
        grid.removeAllChildren()
        player.position.x = kFirstPathX
        player.position.y = playerPositionY
        player.texture = SKTexture(imageNamed: "player-still")
        setup_platforms()
        meter.reset()
    }
    
    // Resets the score, the score label, the difficulty, and grabs the newest high score
    func resetScoreAndDifficulty() {
        difficulty = 5
        increaseDifficulty1 = true
        increaseDifficulty2 = true
        increaseDifficulty3 = true
        highScore = defaults.integerForKey("highScore")
        score = 0
        scoreLabel.setText("\(score)")
    }
    
    // Takes a screenshot for the player to share high score to twitter
    func takeScreenShotToShare() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, 0);
        viewController.view.drawViewHierarchyInRect(viewController.view.bounds, afterScreenUpdates: true)
        var image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
    
    // The meter ran out, player failed to refill
    func meterRanOut() {
        var dieAnimation = SKAction.animateWithTextures([SKTexture(imageNamed: "player-death-1"), SKTexture(imageNamed: "player-death-2")], timePerFrame: 0.5, resize: false, restore: false)
        self.runAction(SKAction.sequence([SKAction.runBlock({ self.player.runAction(dieAnimation)}), SKAction.runBlock({  self.died() })]))
    }
    
    func playerTransitionTo(action: String) {
        switch action {
        case "jumpLeft":
            var jumpLeft = SKAction.animateWithTextures([SKTexture(imageNamed: "player-jump-left")], timePerFrame: 0.1, resize: false, restore: true)
            player.runAction(SKAction.sequence([jumpLeft]), withKey: "current")
        case "jumpRight":
            var jumpRight = SKAction.animateWithTextures([SKTexture(imageNamed: "player-jump-right")], timePerFrame: 0.1, resize: false, restore: true)
            player.runAction(SKAction.sequence([jumpRight]), withKey: "current")
        default:
            println("Error: invalid action")
        }
    }
    
    // Displays the tap indicators in the bottom of the screen
    func displayTapIndicators() {
        tapSprite1 = SKSpriteNode(imageNamed: "tap-1")
        tapSprite1.position = CGPointMake(kFirstPathX, self.frame.minY + tapSprite1.frame.height)
        tapSprite1.zPosition = 25
        self.addChild(tapSprite1)
        
        tapSprite2 = SKSpriteNode(imageNamed: "tap-1")
        tapSprite2.position = CGPointMake(kSecondPathX, self.frame.minY + tapSprite2.frame.height)
        tapSprite2.zPosition = 25
        self.addChild(tapSprite2)
        
        let runAnimation = SKAction.animateWithTextures(tapFrames, timePerFrame: 0.5)
        tapSprite1.runAction(SKAction.repeatActionForever(runAnimation))
        tapSprite2.runAction(SKAction.repeatActionForever(runAnimation))
        
        isTapDisplayed = true
    }
    
    // Removes the tap indicators from the screen
    func removeTapIndicators() {
        tapSprite1.removeAllActions()
        tapSprite1.removeFromParent()
        tapSprite2.removeAllActions()
        tapSprite2.removeFromParent()
        game_started = true
    }
    
    // Fades the background out and in while the scene resets
    func fadeInFadeOut() {
        var blackScreen = SKSpriteNode()
        blackScreen.size = CGSizeMake(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        blackScreen.position = CGPointMake(self.frame.midX, self.frame.midY)
        blackScreen.zPosition = 50
        blackScreen.color = UIColor.blackColor()
        blackScreen.alpha = 0.0
        self.addChild(blackScreen)
        
        blackScreen.runAction(SKAction.sequence([SKAction.fadeInWithDuration(0.3), SKAction.fadeOutWithDuration(0.3), SKAction.runBlock({ blackScreen.removeFromParent() })]))
    }
    
    // Whenever a touch ends...
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if game_started == true {
            var delay = SKAction.waitForDuration(0.15)
            player.runAction(SKAction.sequence([delay, SKAction.runBlock({ self.player.removeAllActions() }), SKAction.runBlock({ self.player.texture = SKTexture(imageNamed: "player-still_01") })]))
        }
    }
    
    // Pauses the game
    func pauseGame() {
        if game_started == true {
            self.userInteractionEnabled = false
            hideInterface()
            player.paused = true
            meter.paused = true
            presentGamePauseLayer()
        }
    }
    
    // One in five chance for a fullscreen ad to load
    func shouldLoadAd() {
        let random = arc4random_uniform(UInt32(5))
        if random == 1 {
            viewController.fullScreenAd()
        }
    }
    
    // Setup the array of Store objects, as well as a dictionary for us to make any quick changes
    func setupStoreObjects() {
        var song_one = StoreObject(key: "Song-1", name: "Song_One")
        var song_two = StoreObject(key: "Song-2", name: "Song_Two")
        var coming_soon = StoreObject(key: "coming_soon", name: "Coming Soon!")
        
        song_one.isUnlocked = true
        defaults.setBool(true, forKey: "Song-1")
        
        song_two.isUnlocked = defaults.boolForKey("Song-2")
        coming_soon.isUnlocked = false
        
        storeItems.append(song_one)
        storeItems.append(song_two)
        storeItems.append(coming_soon)
        
        storeDictionary["Song-1"] = song_one
        storeDictionary["Song-2"] = song_two
        storeDictionary["coming_soon"] = coming_soon
    }
    
    // Delegates the work to the view controller 
    func removeAdsButtonPressed() {
        self.viewController.removeAds()
    }
    
    //
    func rateMe() {
        var neverRate = NSUserDefaults.standardUserDefaults().boolForKey("neverRate")
        var numLaunches = NSUserDefaults.standardUserDefaults().integerForKey("numLaunches") + 1
        
        if (!neverRate && (numLaunches == rateMinSessions || numLaunches >= (rateMinSessions + rateTryAgainSessions + 1)))
        {
            showRateMe()
            numLaunches = rateMinSessions + 1
        }
        NSUserDefaults.standardUserDefaults().setInteger(numLaunches, forKey: "numLaunches")
    }
    
    //
    func showRateMe() {
        var alert = UIAlertController(title: "Rate Us", message: "Thanks for playing!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Rate PlatJump", style: UIAlertActionStyle.Default, handler: { alertAction in
            UIApplication.sharedApplication().openURL(NSURL(string : "itms-apps://itunes.apple.com/app/bars/957839280")!)
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No Thanks", style: UIAlertActionStyle.Default, handler: { alertAction in
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "neverRate")
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Maybe Later", style: UIAlertActionStyle.Default, handler: { alertAction in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.viewController.presentViewController(alert, animated: true, completion: nil)
    }
}