//
//  NSObject+WSMUtilities.h
//  WSNanoTimer
//
//  Created by Cristian A Monterroza on 4/4/13.
//  Copyright (c) 2013 wrkstrm. All rights reserved.
//

/*
typedef NS_ENUM(NSUInteger, WSMTimeUnit) {
    kWSMTimeUnitNanosecond,
    kWSMTimeUnitMicrosecond = 3,
    kWSMTimeUnitMillisecond = 6,
    kWSMTimeUnitCentisecond,
    kWSMTimeUnitDecisecond
    kWSMTimeUnitSecond
};
*/

typedef NS_ENUM(NSUInteger, WSMTimeUnit) {
    kWSMTimeUnitSecond,
    kWSMTimeUnitDecisecond,
    kWSMTimeUnitCentisecond,
    kWSMTimeUnitMillisecond,
    kWSMTimeUnitMicrosecond = 6,
    kWSMTimeUnitNanosecond = 9,
};

@interface NSObject (WSMUtilities)

+ (CFTimeInterval)executionTime:(WSMTimeUnit)timeUnit block:(void (^)(void))block;

- (void)runBlockInMainQueue:(void (^)(void))block;

- (void)executeBlockSafely:(void (^)(void))block;

@end
