//
//  WebViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/4/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebViewController : UIViewController, WKNavigationDelegate {
    var document:CBLDocument?
    var webView:WKWebView! = WKWebView()
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    //MARK:- View Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = document!.properties["title"] as String!
        view.insertSubview(webView, belowSubview: toolbar)
        webView.frame = CGRectMake(0, 0,
            CGRectGetWidth(view.frame), CGRectGetHeight(view.frame) - 44)
        webView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth;
        webView.navigationDelegate = self
        if let urlString = self.document?.properties["url"] as? String {
            let url = NSURL(string: urlString)
            let urlRequest = NSURLRequest(URL: url!)
            webView.loadRequest(urlRequest)
        }
        weak var that = self;
        webView.rac_valuesForKeyPath("canGoForward", observer: self)
            .takeUntil(rac_willDeallocSignal())
            .subscribeNext { (enabled) -> Void in
                let bool = (enabled as NSNumber).boolValue
                that?.forwardButton.enabled = bool
        }
        webView.rac_valuesForKeyPath("canGoBack", observer: self)
            .takeUntil(rac_willDeallocSignal())
            .subscribeNext { (enabled) -> Void in
                let bool = (enabled as NSNumber).boolValue
                that?.backButton.enabled = bool
        }
        webView.rac_valuesForKeyPath("estimatedProgress", observer: self)
            .takeUntil(rac_willDeallocSignal())
            .subscribeNext { (progress) -> Void in
                if  progress as Float == 1 {
                    that?.toolbar.stopShimmering()
                } else if that?.toolbar.layer.mask == nil {
                    that?.toolbar.startShimmeringAtInterval(1.0)
                }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
    }
    
    //MARK:- Lifecycle Helpers
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest,
        navigationType: UIWebViewNavigationType) -> Bool {
            return true;
    }
    
    func hackerBeige() -> UIColor  {
        return SKColorMakeRGB(245.0, 245.0, 238.0)
    }
    
    //MARK:- IBActions
    
    @IBAction func backButtonTapped(sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forwardButtonTapped(sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func refreshTapped(sender: UIBarButtonItem) {
        webView.reload()
    }
    
    @IBAction func actionTapped(sender: UIBarButtonItem) {
        var itemsToShare:NSMutableArray = []
        let title = self.document?["title"] as String
        itemsToShare.addObject(title)
        if let urlString = self.document?.properties["url"] as? String {
            let url = NSURL(string: urlString)
            itemsToShare.addObject(url!)
        }
        
        let activityController = UIActivityViewController(activityItems:itemsToShare,
            applicationActivities: nil)
        let excludeActivities = [UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypePostToVimeo, UIActivityTypePostToFlickr, UIActivityTypeAirDrop]
        activityController.excludedActivityTypes = excludeActivities;
        self.presentViewController(activityController, animated: true) { () -> Void in }
    }
    
    //MARK:- Memory
    
    override func didReceiveMemoryWarning() {
        println("Memory!")
        super.didReceiveMemoryWarning()
        Flurry.logEvent("MemoryWarning")
    }
}