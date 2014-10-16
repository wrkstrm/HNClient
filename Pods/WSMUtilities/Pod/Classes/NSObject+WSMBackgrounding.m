//
//  NSObject+WSMBackgrounding.m
//  Mesh
//
//  Created by Cristian Monterroza on 7/18/14.
//
//

#import <objc/runtime.h>
#import "NSObject+WSMBackgrounding.h"

@implementation NSObject (WSMBackgrounding)

#pragma mark - App Backgrounding

static const NSString * const kWSMBackgroundTask = @"backgroundTask";

- (void)setupBackgrounding {
    self.backgroundTask = UIBackgroundTaskInvalid;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appBackgrounding:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appForegrounding:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)appBackgrounding:(NSNotification *)notification {
    [self keepAlive];
}

- (void)keepAlive {
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
        [self keepAlive];
    }];
}

- (void)appForegrounding:(NSNotification *)notification {
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)setBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTask {
    [self willChangeValueForKey:[kWSMBackgroundTask copy]];
    objc_setAssociatedObject(self, &kWSMBackgroundTask,
                             [NSNumber numberWithUnsignedLong: backgroundTask],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:[kWSMBackgroundTask copy]];
}

- (UIBackgroundTaskIdentifier)backgroundTask {
    return [objc_getAssociatedObject(self, &kWSMBackgroundTask) unsignedLongValue];
}

@end
