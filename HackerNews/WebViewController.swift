//
//  WebViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/4/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation
import UIKit

class WebViewController : UIViewController, UIWebViewDelegate {
    var document:CBLDocument?
    @IBOutlet var webView:UIWebView!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        if let urlString = self.document?.properties["url"] as? String {
            let url = NSURL(string: urlString)
            let urlRequest = NSURLRequest(URL: url!)
            self.webView.loadRequest(urlRequest)
        }
        
        if let title = self.document?.properties["title"] as? String {
            self.title = title
        }
        self.webView.delegate = self
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.hidesBarsOnSwipe = true
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest,
        navigationType: UIWebViewNavigationType) -> Bool {
        return true;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Flurry.logEvent("MemoryWarning")
        self.webView = nil
        self.navigationController?.popViewControllerAnimated(true)
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
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        println("Error : \(error)")
    }
}