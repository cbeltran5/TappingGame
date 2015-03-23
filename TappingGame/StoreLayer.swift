//
//  StoreLayer.swift
//  TappingGame
//
//  Created by Carlos Beltran on 2/1/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

protocol StoreLayerDelegate {
    func selectButtonPressed(newChoice: String)
    func listenButtonPressed(choice: String)
}

class StoreLayer: SKSpriteNode {
    
    var rightButton:SKSpriteNode!
    var leftButton: SKSpriteNode!
    var selectButton: SKSpriteNode!
    var listenButton: SKSpriteNode!
    
    var storeItems: [StoreObject]!
    var currentIndex = 0
    
    var nameLabel: SKSpriteNode!
    var preReqLabel: SKSpriteNode!
    
    var delegate: StoreLayerDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: nil, color: color, size: size)
        
        selectButton = SKSpriteNode(imageNamed: "selectButton")
        selectButton.position = CGPointMake(0, -(UIScreen.mainScreen().bounds.height/2) + selectButton.size.height/2 + 10)
        selectButton.zPosition = 100
        self.addChild(selectButton)
        
        var layer = SKSpriteNode(texture: texture)
        layer.position = CGPointMake(0, self.position.y + selectButton.size.height * 0.4)
        layer.zPosition = 100
        self.addChild(layer)
        
        nameLabel = SKSpriteNode(imageNamed: "track-1")
        nameLabel.position = CGPointMake(0, layer.frame.maxY - nameLabel.size.height * 3.8)
        nameLabel.zPosition = 115
        self.addChild(nameLabel)
        
        preReqLabel = SKSpriteNode(imageNamed: "unlocked")
        preReqLabel.position = CGPointMake(0, nameLabel.position.y - nameLabel.size.height * 3)
        preReqLabel.zPosition = 115
        self.addChild(preReqLabel)
        
        listenButton = SKSpriteNode(imageNamed: "listenButton")
        listenButton.zPosition = 100
        listenButton.position = CGPointMake(0, layer.frame.minY + listenButton.size.height + 10)
        self.addChild(listenButton)
        
        leftButton = SKSpriteNode(imageNamed: "leftButton")
        leftButton.position = CGPointMake(selectButton.frame.minX - leftButton.size.width, selectButton.position.y)
        leftButton.zPosition = 100
        self.addChild(leftButton)
        
        rightButton = SKSpriteNode(imageNamed: "rightButton")
        rightButton.position = CGPointMake(selectButton.frame.maxX + rightButton.size.width, selectButton.position.y)
        rightButton.zPosition = 100
        self.addChild(rightButton)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == selectButton && selectButton.hidden == false {
                self.delegate?.selectButtonPressed(storeItems[currentIndex].key)
            }
            else if self.nodeAtPoint(thisPosition) == listenButton && listenButton.hidden == false {
                self.delegate?.listenButtonPressed(storeItems[currentIndex].key)
                listenButton.hidden = true
            }
            else if self.nodeAtPoint(thisPosition) == leftButton && leftButton.hidden == false {
                updateDisplay(-1)
            }
            else if self.nodeAtPoint(thisPosition) == rightButton  && rightButton.hidden == false {
                updateDisplay(1)
            }
        }
    }
    
    // Updates the display (item name, item pre-requisites, item image) based on the index
    // Check if the object is unlocked. If it is, display the select button, and no
    // prequisites. Simply 'Unlocked!'
    // If it is locked, display pre-requite, but disable the select button
    // If it is selected, display already selected and disable the select button
    func updateDisplay(indexIncrement: Int) {
        
        if currentIndex != storeItems?.count && currentIndex + indexIncrement >= 0 {
            currentIndex += indexIncrement
        }
        
        if currentIndex == 0 {
            leftButton.hidden = true
        }
        else if currentIndex + 1 == storeItems.count {
            rightButton.hidden = true
        }
        else {
            leftButton.hidden = false
            rightButton.hidden = false
        }

        var currentObject = storeItems[currentIndex]
        
        // Update the text to be displayed
        updateText()
        
        // If the song is already selected, the select button should say 'Already Selected'
        if currentObject.isUnlocked == false {
            selectButton.hidden = true
            if currentObject.key == "coming_soon" {
                // Display 'Locked' -- coming soon
                listenButton.hidden = true
            }
            else {
                // Diplay 'Buy' or 'Locked'
                listenButton.hidden = false
                
            }
        }
        else {
            selectButton.hidden = false
            listenButton.hidden = true
        }
    }
    
    func updateText() {
        var currentObject = storeItems[currentIndex]
        
        if currentObject.key == "coming_soon" {
            nameLabel.texture = SKTexture(imageNamed: "coming-soon")
            nameLabel.size = SKTexture(imageNamed: "coming-soon").size()
            preReqLabel.hidden = true
        }
        else {
            var stringLength = countElements(currentObject.key)
            var nameString: String = String(format: "track-%@", currentObject.key[stringLength - 1])
            var preReqString: String = String(format: "pre-req-%@", currentObject.key[stringLength - 1])
            
            nameLabel.texture = SKTexture(imageNamed: nameString)
            nameLabel.size = SKTexture(imageNamed: nameString).size()
            
            preReqLabel.hidden = false
            if currentObject.isUnlocked == true {
                preReqLabel.texture = SKTexture(imageNamed: "unlocked")
                preReqLabel.size = SKTexture(imageNamed: "unlocked").size()
            }
            else {
                preReqLabel.texture = SKTexture(imageNamed: preReqString)
                preReqLabel.size = SKTexture(imageNamed: preReqString).size()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}