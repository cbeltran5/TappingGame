//
//  GameViewController.swift
//  TappingGame
//
//  Created by Carlos Beltran on 1/5/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import UIKit
import SpriteKit
import iAd

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as PlayScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, ADBannerViewDelegate {
    
    var bannerView: ADBannerView = ADBannerView()
    
    func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
    override func viewWillAppear(animated: Bool) {
        //println("Called viewWillAppear")
        bannerView.delegate = self
        bannerView = self.appDelegate().adBannerView
        bannerView.frame = CGRectMake(0, 0, 0, 0)
        self.view.addSubview(bannerView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        //println("Called viewWillDisappear")
        bannerView.delegate = nil
        bannerView.removeFromSuperview()
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        //println("Called bannerViewDidLoad")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1)
        bannerView.alpha = 1
        UIView.commitAnimations()
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        //println("failed")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0)
        bannerView.alpha = 1
        UIView.commitAnimations()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = PlayScene()
        // Configure the view.
        let skView = self.originalContentView as SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        scene.size = skView.bounds.size
        
        // Set the view controller of the play scene to self to present leaderboards
        scene.viewController = self
        
        // Might need this to call a function to save settings
        appDelegate().viewController = self
        
        skView.presentScene(scene)
    }

    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
