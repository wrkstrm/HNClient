//
//  HNStoryManager.h
//  HackerNews
//
//  Created by Cristian Monterroza on 11/19/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNUser.h"

typedef NS_ENUM(NSInteger, HNSortStyle) {
    kHNSortStyleRank,
    kHNSortStylePoints,
    kHNSortStyleComments
};

@interface HNStoryManager : NSObject

/**
 The current user. This allows you to access his settings.
 */

@property (nonatomic, strong, readonly) HNUser *currentUser;

/**
 The current Top Stories according to the user. This property is KVO compliant.
 Because this doesn't change often, the best way to observe is through ReactiveCocoa.
 */

@property (nonatomic, strong, readonly) NSArray *currentTopStories;


/**
 A signal that sends all item changes from observed items. 
 */

@property (nonatomic, strong, readonly) RACSignal *itemUpdates;

/**
 The only way to change the sort style of the current top stories. 
 */
@property (nonatomic, readwrite) HNSortStyle sortStyle;

/**
 Shared Instance is the perferred way to get HN State.
 */

+ (instancetype)sharedInstance;

#pragma mark - User Initiated Actions

/**
 Call when you want to hide a story and update the currentTopStories;
 */

- (void)hideStory:(NSNumber *)number;

/**
 Call when you want to unhide a story and update the currentTopStories;
 */

- (void)unhideStory:(NSNumber *)number;

#pragma mark - State Methods.

/**
 The way to get the current state of a document. 
 Sign up for notifications on changes via the RACSignal (filter for number + subscribe)
 */

- (CBLModel *)modelForItemNumber:(NSNumber *)number;

/**
 Favicons are cached to avoid unnecessary network calls.
 This gives you a key that can be observed on the FaviconCache.
 */

- (UIImage *)getPlaceholderAndFaviconForItemNumber:(NSNumber *)itemNumber
                                           callback:(void(^)(UIImage *favicon))favicon;

#pragma mark - User State Access Methods.

/**
 The custom stories hidden by the user.
 */
- (NSArray *)userHiddenStories;

/**
 The stories hidden due to low comments.
 */

- (NSArray *)commentHiddenStories;

/**
 The stories hidden due to low Points.
 */
- (NSArray *)pointHiddenStories;


@end
