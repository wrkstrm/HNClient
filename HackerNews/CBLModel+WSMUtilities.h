//
//  CBLDocument+WSMUtilities.h
//  Here
//
//  Created by Cristian Monterroza on 11/3/14.
//  Copyright (c) 2014 Cristian Monterroza. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLModel (WSMUtilities)

- (NSString *) docID;

/** Shorthand for [self.properties objectForKey: key]. */
- (void)setObject:(id)object forKeyedSubscript:(id)key;

/** Same as -propertyForKey:. Enables "[]" access in Xcode 4.4+ */
- (id)objectForKeyedSubscript:(id)key;

@end
