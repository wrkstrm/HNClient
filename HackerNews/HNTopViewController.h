//
//  ViewController.h
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewController+HNUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNTopViewController : UITableViewController

@property (nonatomic, strong, nullable) NSMutableDictionary *rowHeightDictionary;
@property (nonatomic, strong, readonly) NSArray *currentSortedTopStories;

- (NSNumber *)itemNumberForIndexPath:(NSIndexPath *)path;

- (NSIndexPath *)indexPathForItemNumber:(NSNumber *)itemNumber;

- (void)respondToItemUpdates;

- (void)updateCell:(UITableViewCell *)cell
       atIndexPath:(NSIndexPath *)indexPath
           shimmer:(BOOL)shouldShimmer;

- (NSIndexPath * _Nullable)updateCellWithTuple:(NSArray *)tuple;

@end

NS_ASSUME_NONNULL_END
