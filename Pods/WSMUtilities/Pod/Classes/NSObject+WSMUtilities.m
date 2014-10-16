//
//  NSObject+WSNanoTimer.m
//  WSNanoTimer
//
//  Created by Cristian A Monterroza on 4/4/13.
//  Copyright (c) 2013 wrkstrm. All rights reserved.
//

#import "NSObject+WSMUtilities.h"
#import <mach/mach_time.h>
#import <objc/runtime.h>

static uint64_t sTimebaseRatio;

@implementation NSObject (WSMUtilities)

#pragma mark - Debugging stuff

+ (void)load {
    mach_timebase_info_data_t sTimebaseInfo;
    mach_timebase_info(&sTimebaseInfo);
    
    sTimebaseRatio = sTimebaseInfo.numer / sTimebaseInfo.denom;
}

+ (CFTimeInterval)executionTime:(WSMTimeUnit)timeUnit block:(void (^)(void))block {
    uint64_t startTime = mach_absolute_time();
    block();
    uint64_t endTime = mach_absolute_time();
    return (endTime - startTime) * sTimebaseRatio / pow(10, 9 - timeUnit);
}

- (void)runBlockInMainQueue:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)executeBlockSafely:(void (^)(void))block {
    if (block) {
        block();
    }
}

@end
