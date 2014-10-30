//
//  NSCache+WSMUtilities.m
//  HackerNews
//
//  Created by Cristian Monterroza on 10/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "NSCache+WSMUtilities.h"

@implementation NSCache (WSMUtilities)

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    [self setObject:object forKey:key];
}

- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

@end
