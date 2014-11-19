//
//  CBLDocument+WSMUtilities.m
//  HackerNews
//
//  Created by Cristian Monterroza on 10/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "CBLDocument+WSMUtilities.h"
#import <CouchbaseLite/CBLRevision.h>

@implementation CBLDocument (WSMUtilities)

- (BOOL)mergeUserProperties:(NSDictionary *)properties error:(NSError **)error {
    NSMutableDictionary *mutableOldUserProperties = (self.properties ?: @{}).mutableCopy;
    for (NSString *key in properties) {
        mutableOldUserProperties[key] = properties[key];
    }
    [self putProperties:mutableOldUserProperties error:error];
    return !!error;
}

@end
