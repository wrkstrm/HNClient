//
//  CBLDocument+WSMUtilities.h
//  HackerNews
//
//  Created by Cristian Monterroza on 10/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLDocument (WSMUtilities)

- (void)mergeUserProperties:(NSDictionary *)properties error:(NSError **)error;

@end
