//
//  NSMutableArray+WSMUtilites.m
//  BuildFree
//
//  Created by Cristian Monterroza on 8/6/14.
//  Copyright (c) 2014 Sugar Skull Apps. All rights reserved.
//

#import "NSMutableArray+WSMUtilites.h"

@implementation NSMutableArray (WSMUtilites)

- (id)removeRandomObject {
    if (self.count == 0) return nil;

    NSUInteger indexOfObject = arc4random_uniform((u_int32_t)self.count);
    NSObject *object = self[indexOfObject];
    [self removeObjectAtIndex:indexOfObject];
    return object;
}


@end
