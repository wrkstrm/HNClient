//
//  HNWebViewController.m
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNWebViewController.h"

@implementation HNWebViewController

- (void)viewDidLoad {
    [self.webView loadRequest:self.request];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.webView = nil; 
}

- (void)didReceiveMemoryWarning {
    self.webView = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
