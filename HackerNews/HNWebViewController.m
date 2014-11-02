//
//  HNWebViewController.m
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNWebViewController.h"

@interface HNWebViewController () <UIWebViewDelegate>

@end

@implementation HNWebViewController

- (void)viewDidLoad {
    self.webView.delegate = self;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.requestURL]];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.hidesBarsOnSwipe = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Error : %@",error);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.webView = nil;
}

- (void)didReceiveMemoryWarning {
    [Flurry logEvent:@"MemoryWarning"];
    self.webView = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
