//
//  HNUser.h
//  HackerNews
//
//  Created by Cristian Monterroza on 11/5/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "WSMUser.h"
#import "CBLDocument+WSMUtilities.h"

@interface HNUser : WSMUser

@property (nonatomic, strong) NSArray *hiddenStories;
@property (nonatomic) NSInteger minimumScore;

@end
