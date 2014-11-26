//
//  AppDelegate.m
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "AppDelegate.h"
#import "HNStoryManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (void)load {
    WSMLogger *logger = WSMLogger.sharedInstance;
    
    // Customize the WSLogger
    logger.formatStyle = kWSMLogFormatStyleQueue;
    logger[kWSMLogFormatKeyFile] = @7;
    logger[kWSMLogFormatKeyFunction] = @40;
    
    [DDLog addLogger:logger];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window.tintColor = SKColorMakeRGB(245.0f, 245.0f, 238.0f);
    //Analytics
    [Flurry startSession:self.secrets[@"flurryKey"]];
    return YES;
}

- (Firebase *)hackerAPI {
    return WSM_LAZY(_hackerAPI,
                    [[Firebase alloc] initWithUrl:@"https://hacker-news.firebaseio.com/v0/"]);
}

- (NSDictionary *)secrets {
    return WSM_LAZY(_secrets, ({
        NSString *filePath = [NSBundle.mainBundle pathForResource:@"secrets"
                                                           ofType:@"json"];
        [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath]
                                        options:kNilOptions
                                          error:nil];
    }));
}

+ (UIColor *)hackerBeige {
    return SKColorMakeRGB(245.0, 245.0, 238.0);
}

+ (UIColor *)hackerOrange {
    return SKColorMakeRGB(255.0, 102.0, 0.0);
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
