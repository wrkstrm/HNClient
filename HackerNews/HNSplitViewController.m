//
//  HNSplitViewController.m
//  HackerNews
//
//  Created by Cristian Monterroza on 10/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNSplitViewController.h"

@interface HNSplitViewController () <UISplitViewControllerDelegate>

@end

@implementation HNSplitViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"View Controllers: %@", self.viewControllers);
    [self.viewControllers[0] view].tintColor = SKColorMakeRGB(245.0f, 245.0f, 238.0f);
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
  ontoPrimaryViewController:(UIViewController *)primaryViewController {
    NSLog(@"Collapsing!");
    return YES;
}

//- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender {
//    NSLog(@"Here we go.");    
//    return NO;
//}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    NSLog(@"Display Mode: %li", displayMode);
    NSLog(@"Controllers: %@",self.viewControllers);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"Segue: %@", segue);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
