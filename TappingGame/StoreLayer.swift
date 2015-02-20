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
    
    var nameLabel = SKLabelNode()
    var nameLabelShadow = SKLabelNode()
    var imageLabel = UIImageView()
    var preReqLabel = SKLabelNode()
    
    var delegate: StoreLayerDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        nameLabel = SKLabelNode(fontNamed: "DINAlternate-Bold")
        nameLabel.horizontalAlignmentMode = .Center
        nameLabel.fontColor = UIColor.whiteColor()
        nameLabel.zPosition = 50
        nameLabel.position = CGPointMake(0, 0)
        self.addChild(nameLabel)
        
        nameLabelShadow = SKLabelNode(fontNamed: "DINAlternate-Bold")
        nameLabelShadow.horizontalAlignmentMode = .Center
        nameLabelShadow.fontColor = UIColor.blackColor()
        nameLabelShadow.position = CGPointMake(0, nameLabel.position.y - 3)
        self.addChild(nameLabelShadow)
        
        selectButton = SKSpriteNode(imageNamed: "selectButton")
        selectButton.position = CGPointMake(0, -(self.size.height / 2) - selectButton.size.height * 0.7)
        selectButton.zPosition = 100
        self.addChild(selectButton)
        
        listenButton = SKSpriteNode(imageNamed: "listenButton")
        listenButton.zPosition = 100
        listenButton.position = CGPointMake(0, selectButton.position.y + selectButton.size.height * 2)
        self.addChild(listenButton)
        
        leftButton = SKSpriteNode(imageNamed: "leftButton")
        leftButton.position = CGPointMake(0 - (self.size.width / 2) + (leftButton.size.width / 2), selectButton.position.y)
        leftButton.zPosition = 100
        self.addChild(leftButton)
        
        rightButton = SKSpriteNode(imageNamed: "rightButton")
        rightButton.position = CGPointMake(0 + (self.size.width / 2) - (rightButton.size.width / 2), selectButton.position.y)
        rightButton.zPosition = 100
        self.addChild(rightButton)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == selectButton && selectButton.hidden == false {
                self.delegate?.selectButtonPressed(storeItems[currentIndex].key)
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
        
        // TODO:: retrieve the object's info and display accordingly
        var currentObject = storeItems[currentIndex]
        nameLabel.text = currentObject.name
        nameLabelShadow.text = currentObject.name
        
        // If the song is already selected, the select button should say 'Already Selected'
        if currentObject.isUnlocked == false {
            selectButton.hidden = true
            if currentObject.canSelect == false {
                // Display 'Locked' -- coming soon
            }
            else if currentObject.isUnlocked == false {
                // Diplay 'Buy' or 'Locked'
            }
        }
        else {
            selectButton.hidden = false
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}