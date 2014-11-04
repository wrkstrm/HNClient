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
    @IBOutlet var webView:UIWebView!
    var urlString:String = ""
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        let url = NSURL(string: self.urlString)
        let urlRequest = NSURLRequest(URL: url!)
        self.webView.delegate = self
        self.webView.loadRequest(urlRequest)
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
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        println("Error : \(error)")
    }
}