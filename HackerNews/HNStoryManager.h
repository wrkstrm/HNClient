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

@property (nonatomic, strong) HNUser *currentUser;

/**
 The current Top Stories according to the user. This property is KVO compliant.
 Because this doesn't change often, the best way to observe is through ReactiveCocoa.
 */

@property (nonatomic, strong, readonly) NSArray *currentTopStories;

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

#pragma mark - State Methods.

/**
 The way to get the current state of a document. This is also KVO compliant.
 Because, this needs to change often and ReactiveCocoa is slow, use Facebook KVO. 
 */

- (CBLDocument *)documentForItemNumber:(NSNumber *)number;

/**
 Favicons are cached to avoid unnecessary network calls.
 This gives you a key that can be observed on the FaviconCache.
 */

- (UIImage *)getPlaceholderAndFaviconForItemNumber:(NSNumber *)itemNumber
                                           callback:(void(^)(UIImage *favicon))favicon;


@end
