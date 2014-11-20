//
//  HNStoryManager.h
//  HackerNews
//
//  Created by Cristian Monterroza on 11/19/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNUser.h"

@interface HNStoryManager : NSObject

@property (nonatomic, strong) HNUser *currentUser;
@property (nonatomic, strong) NSArray *currentTopStories;

+ (instancetype)sharedInstance;

- (RACSignal *)latestStateForItemNumber:(NSNumber *)storyNumber;

@end
