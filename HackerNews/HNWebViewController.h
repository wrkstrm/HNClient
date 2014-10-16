//
//  HNWebViewController.h
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HNWebViewController : UIViewController

@property(nonatomic, weak) IBOutlet UIWebView *webView;
@property(nonatomic, strong) NSURLRequest *request;

@end
