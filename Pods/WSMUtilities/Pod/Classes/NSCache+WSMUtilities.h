//
//  NSCache+WSMUtilities.h
//  HackerNews
//
//  Created by Cristian Monterroza on 10/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCache (WSMUtilities)

/** 
 Shorthand for [self.properties objectForKey: key]. 
 */
- (void)setObject:(id)object forKeyedSubscript:(id)key;

/** 
 Same as -propertyForKey:. Enables "[]" access in Xcode 4.4+ 
 */
- (id)objectForKeyedSubscript:(id)key;

@end
