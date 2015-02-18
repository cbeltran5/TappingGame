//
//  BitmapFontLabel.swift
//  TappingGame
//
//  Created by Carlos Beltran on 2/15/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

class BitMapFontLabel: SKNode {
    
    var fontName = NSString()
    var text = NSString()
    var letterSpacing: CGFloat!
    
    override init() {
        super.init()
    }
    
    convenience init(text: NSString, fontName: NSString) {
        self.init()
        self.fontName = fontName
        self.text = text
        self.letterSpacing = 2.0
        self.updateText()
    }
    
    func setText(text: NSString) {
        if self.text != text {
            self.text = text
            updateText()
        }
    }
    
    func setFontName(fontName: NSString) {
        if self.fontName != fontName {
            self.fontName = fontName
            updateText()
        }
    }
    
    func setLetterSpacing(spacing: CGFloat) {
        if self.letterSpacing != spacing {
            self.letterSpacing = spacing
            updateText()
        }
    }
    
    func updateText() {
        // Remove unused nodes.
        if self.text.length < self.children.count {
            for var i = self.children.count; i > self.text.length; i-- {
                self.children[1].removeFromParent()
            }
        }
        
        var pos = CGPointZero
        var totalSize = CGSizeZero
        var atlas = SKTextureAtlas(named: "number")
        
        // Loop through all characters in text.
        for var i = 0; i < self.text.length; i++ {
            // Get character in text for current position in loop.
            var c = self.text.characterAtIndex(i)
            var textureName = String(format: "%@%C", self.fontName, c)
            var letter = SKSpriteNode()
            
            if i < self.children.count {
                // Reuse an existing node.
                letter = self.children[i] as SKSpriteNode
                letter.texture = atlas.textureNamed(textureName)
            } else {
                // Create a new letter node.
                letter = SKSpriteNode(texture: atlas.textureNamed(textureName))
                letter.anchorPoint = CGPointZero
                self.addChild(letter)
            }
            
            letter.position = pos
            pos.x += letter.size.width + self.letterSpacing
            totalSize.width += letter.size.width + self.letterSpacing
            if totalSize.height < letter.size.height {
                totalSize.height = letter.size.height
            }
        }
        
        if (self.text.length > 0) {
            totalSize.width -= self.letterSpacing;
        }
        
        // Center text.
        var adjustment = CGPointMake(-totalSize.width * 0.5, -totalSize.height * 0.5)
        for letter in self.children {
            let letterNode = letter as SKSpriteNode
            letterNode.position = CGPointMake(letter.position.x + adjustment.x, letter.position.y + adjustment.y);
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}