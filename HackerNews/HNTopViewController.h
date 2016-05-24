//
//  ViewController.h
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewController+HNUtilities.h"

@interface HNTopViewController : UITableViewController

@property (nonatomic, strong) NSMutableDictionary *rowHeightDictionary;
@property (nonatomic, strong, readonly) NSArray *currentSortedTopStories;

- (NSNumber *)itemNumberForIndexPath:(NSIndexPath *)path;

- (NSIndexPath *)indexPathForItemNumber:(NSNumber *)itemNumber;

- (void)respondToItemUpdates;

- (void)updateCell:(UITableViewCell *)cell
       atIndexPath:(NSIndexPath *)indexPath
           shimmer:(BOOL)shouldShimmer;

- (NSIndexPath *)updateCellWithTuple:(NSArray *)tuple;

@end
