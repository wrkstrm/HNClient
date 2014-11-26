//
//  AppDelegate.h
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) Firebase *hackerAPI;
@property (nonatomic, strong) NSDictionary *secrets;

+ (UIColor *)hackerBeige;

+ (UIColor *)hackerOrange;

@end

