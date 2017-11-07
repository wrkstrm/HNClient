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
    var story:HNItem?
    var webView:WKWebView! = WKWebView()
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)!
    }
    
    //MARK:- View Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = story?.title
        view.insertSubview(webView, belowSubview: toolbar)
        webView.frame = CGRect(x: 0, y: 0,
            width: view.frame.width, height: view.frame.height - 44)
        webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        webView.navigationDelegate = self
        if let urlString = self.story?.url {
            let url = URL(string: urlString)
            let urlRequest = URLRequest(url: url!)
            webView.load(urlRequest)
        }
        weak var that = self;
        webView.rac_values(forKeyPath: "canGoForward", observer: self)
            .take(until: rac_willDeallocSignal())
            .subscribeNext { (enabled) -> Void in
                let bool = (enabled as! NSNumber).boolValue
                that?.forwardButton.isEnabled = bool
        }
        webView.rac_values(forKeyPath: "canGoBack", observer: self)
            .take(until: rac_willDeallocSignal())
            .subscribeNext { (enabled) -> Void in
                let bool = (enabled as! NSNumber).boolValue
                that?.backButton.isEnabled = bool
        }
        webView.rac_values(forKeyPath: "estimatedProgress", observer: self)
            .take(until: rac_willDeallocSignal())
            .subscribeNext { (progress) -> Void in
                if  progress as! Float == 1 {
                    that?.toolbar.stopShimmering()
                } else if that?.toolbar.layer.mask == nil {
                    that?.toolbar.startShimmering(atInterval: 1.0)
                }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
    }
    
    //MARK:- Lifecycle Helpers
    
    func webView(_ webView: UIWebView, shouldStartLoadWithRequest request: URLRequest,
        navigationType: UIWebViewNavigationType) -> Bool {
            return true;
    }
    
    func hackerBeige() -> UIColor  {
        return UIColor.black
//        return SKColorMakeRGB(245.0, 245.0, 238.0)
    }
    
    //MARK:- IBActions
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func refreshTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    @IBAction func actionTapped(_ sender: UIBarButtonItem) {
        let itemsToShare:NSMutableArray = NSMutableArray()
        let title = story?.title
        itemsToShare.add(title!)
        if let urlString = story?.url {
            let url = URL(string: urlString)
            itemsToShare.add(url!)
        }
        
        let activityController = UIActivityViewController(activityItems:itemsToShare as [AnyObject],
            applicationActivities: nil)
        let excludeActivities = [UIActivityType.assignToContact, UIActivityType.saveToCameraRoll, UIActivityType.postToVimeo, UIActivityType.postToFlickr, UIActivityType.airDrop]
        activityController.excludedActivityTypes = excludeActivities;
        self.present(activityController, animated: true) { () -> Void in }
    }
    
    //MARK:- Memory
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        FIRAnalytics.logEvent(withName: "MemoryWanring", parameters: nil)
    }
}
