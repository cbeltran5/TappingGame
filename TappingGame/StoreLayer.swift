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
}

class StoreLayer: SKSpriteNode {
    
    var rightButton:SKSpriteNode!
    var leftButton: SKSpriteNode!
    var selectButton: SKSpriteNode!
    
    var storeItems: [StoreObject]!
    var currentIndex = 0
    
    var nameLabel = SKLabelNode()
    var imageLabel = UIImageView()
    var preReqLabel = SKLabelNode()
    
    var delegate: StoreLayerDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        selectButton = SKSpriteNode(imageNamed: "selectButton")
        selectButton.position = CGPointMake(0, -(self.size.height / 2) - selectButton.size.height * 0.7)
        selectButton.zPosition = 100
        self.addChild(selectButton)
        
        leftButton = SKSpriteNode(imageNamed: "leftButton")
        leftButton.position = CGPointMake(0 - (self.size.width / 2) + (leftButton.size.width / 2), selectButton.position.y)
        leftButton.zPosition = 100
        self.addChild(leftButton)
        
        rightButton = SKSpriteNode(imageNamed: "rightButton")
        rightButton.position = CGPointMake(0 + (self.size.width / 2) - (rightButton.size.width / 2), selectButton.position.y)
        rightButton.zPosition = 100
        self.addChild(rightButton)
        
        updateDisplay(0)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            let thisPosition = touch.locationInNode(self)
            if self.nodeAtPoint(thisPosition) == selectButton {
                self.delegate?.selectButtonPressed("")
            }
            else if self.nodeAtPoint(thisPosition) == leftButton {
                updateDisplay(-1)
            }
            else if self.nodeAtPoint(thisPosition) == rightButton {
                updateDisplay(1)
            }
        }
    }
    
    // Updates the display (item name, item pre-requisites, item image) based on the index
    // Check if the object is unlocked. If it is, display the select button, and no
    // prequisites. Simply 'Unlocked!'
    // If it is locked, display pre-requite, but disable the select button
    func updateDisplay(indexIncrement: Int) {
        
        currentIndex += indexIncrement
        
        if currentIndex == 0 {
            leftButton.hidden = true
            leftButton.userInteractionEnabled = false
        }
        else if currentIndex + 1 == storeItems.count {
            rightButton.hidden = true
            rightButton.userInteractionEnabled = false
        }
        else {
            leftButton.hidden = false
            leftButton.userInteractionEnabled = true
            rightButton.hidden = false
            rightButton.userInteractionEnabled = true
        }
        
        //var currentObject = storeItems[currentIndex]
        // TODO:: retrieve the object's info and display accordingly
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}