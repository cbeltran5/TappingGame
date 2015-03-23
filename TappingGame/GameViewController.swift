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
import StoreKit

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

class GameViewController: UIViewController, ADBannerViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    var bannerView: ADBannerView!
    var scene: PlayScene!
    let defaults = NSUserDefaults.standardUserDefaults()
    var product_id: NSString!
    
    func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
    override func viewWillAppear(animated: Bool) {
        var defaults = NSUserDefaults.standardUserDefaults()
        
        if defaults.boolForKey("removeAdsPurchased") == false {
            bannerView = ADBannerView(adType: .Banner)
            bannerView.delegate = self
            bannerView.hidden = true
            bannerView.frame = CGRectMake(0, 0, 0, 0)
            self.view.addSubview(bannerView)
        }
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        println("Called bannerViewDidLoadAd")
        bannerView.hidden = false
        banner.hidden = false
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1)
        UIView.commitAnimations()
        
        product_id = "removeAds"
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        println("Called didFail...")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0)
        UIView.commitAnimations()
        banner.hidden = true
        bannerView.hidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = PlayScene()
        let skView = self.view as SKView
        
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFit
        scene.size = skView.bounds.size
        
        // Set the view controller of the play scene to self to present leaderboards
        scene.viewController = self
        
        // Might need this to call a function to save settings
        appDelegate().viewController = self
        
        skView.presentScene(scene)
    }
    
    override func viewDidAppear(animated: Bool) {
        scene.rateMe()
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
    
    func fullScreenAd() {
        if self.requestInterstitialAdPresentation() == true {
            println("ad loaded")
        }
    }
    
    // IAP functions
    
    func removeAds() {
        if SKPaymentQueue.canMakePayments() {
            var productID:NSSet = NSSet(object: self.product_id!)
            var productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID)
            productsRequest.delegate = self
            productsRequest.start()
            println("Fetching products...")
        }
        else {
            println("Can't make purchases")
        }
    }
    
    func buyProduct(product: SKProduct) {
        println("Sending the Payment Request to Apple");
        var payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment);
    }
    
    func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        var count : Int = response.products.count
        if (count>0) {
            var validProducts = response.products
            var validProduct: SKProduct = response.products[0] as SKProduct
            if (validProduct.productIdentifier == self.product_id) {
                println(validProduct.localizedTitle)
                println(validProduct.localizedDescription)
                println(validProduct.price)
                buyProduct(validProduct);
            }
            else {
                println(validProduct.productIdentifier)
            }
        }
        else {
            println("nothing")
        }
    }
    
    func request(request: SKRequest!, didFailWithError error: NSError!) {
        println("Error fetching product info")
    }
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        println("Received Payment Transaction Response from Apple");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .Purchased:
                    println("Product Purchased");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as SKPaymentTransaction)
                    defaults.setBool(true , forKey: "removeAdsPurchased")
                    break;
                case .Failed:
                    println("Purchased Failed");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as SKPaymentTransaction)
                    break;
                case .Restored:
                    println("Already Purchased");
                    SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
                default:
                    break;
                }
            }
        }
    }
    
}
