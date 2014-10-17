//
//  AppDelegate.m
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (void)load {
    WSMLogger *logger = WSMLogger.sharedInstance;
    [DDLog addLogger:logger];
    
    // Customize the WSLogger
    logger.formatStyle = kWSMLogFormatStyleQueue;
    logger[kWSMLogFormatKeyFile] = @7;
    logger[kWSMLogFormatKeyFunction] = @40;
    
    // Color the WSlogger. By default DDLog does not color VERBOSE or warn flags.
    [logger setColorsEnabled:YES];
    [logger setForegroundColor:SKColor.orangeColor
               backgroundColor:SKColor.blackColor
                       forFlag:LOG_FLAG_WARN];
    
    [logger setForegroundColor:SKColor.yellowColor
               backgroundColor:SKColor.blackColor
                       forFlag:LOG_FLAG_VERBOSE];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (Firebase *)hackerAPI {
    return WSM_LAZY(_hackerAPI, [[Firebase alloc] initWithUrl:@"https://hacker-news.firebaseio.com/v0/"]);
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSString *filePath = [NSBundle.mainBundle pathForResource:@"secrets"
                                                       ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *secrets = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions
                                                              error:nil];
    //Analytics
    [Flurry startSession:secrets[@"flurryKey"]];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
