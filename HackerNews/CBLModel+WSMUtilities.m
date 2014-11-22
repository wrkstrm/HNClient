//
//  CBLDocument+WSMUtilities.m
//  Here
//
//  Created by Cristian Monterroza on 11/3/14.
//  Copyright (c) 2014 Cristian Monterroza. All rights reserved.
//

#import "CBLModel+WSMUtilities.h"
#import "CBLDocument+WSMUtilities.h"

@implementation CBLModel (WSMUtilities)

- (NSString *) docID {
    return self.document.documentID;
}

- (id)objectForKeyedSubscript:(id)key {
    return self.document[key];
}

@end
