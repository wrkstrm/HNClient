//
//  ViewController.m
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "AppDelegate.h"
#import "HNTopViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UITableViewCell+HNHeadline.h"
#import "NSCache+WSMUtilities.h"
#import "UIView+WSMUtilities.h"
#import "CBLDocument+WSMUtilities.h"
#import "HNStoryManager.h"
#import "HNItems.h"
#import "HackerNews-Swift.h"

@interface HNTopViewController ()

@end

@implementation HNTopViewController

#pragma mark - Property Instantiation

- (NSMutableDictionary *)rowHeightDictionary {
    return WSM_LAZY(_rowHeightDictionary, @{}.mutableCopy);
}

#pragma mark - Tableview Update Managment

#define newsSection 0

- (void)respondToItemUpdates {
    [[[HNStoryManager sharedInstance] itemUpdates] subscribeNext:^(RACTuple *tuple) {
        [self updateCellWithTuple:tuple];
    }];
}

- (void)updateCellWithTuple:(RACTuple *)tuple {
    NSNumber *number = (NSNumber *) tuple.first;
    HNStory *story = (HNStory *) tuple.second;
    CGFloat newRowHeight = [UITableViewCell getCellHeightForStory:story
                                                             view:self.view];
    CGFloat oldRowHeight = [self.rowHeightDictionary[number] floatValue];
    NSIndexPath *indexPath = [self indexPathForItemNumber:number];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (!cell && !oldRowHeight) {
        self.rowHeightDictionary[number] = @(newRowHeight);
    } else if (cell && newRowHeight == oldRowHeight) {
        [self updateCell:cell atIndexPath:indexPath shimmer:YES];
    } else if (newRowHeight != oldRowHeight) {
        self.rowHeightDictionary[number] = @(newRowHeight);
        [self.tableView reloadRowsAtIndexPaths:@[[self indexPathForItemNumber:number]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - TableView DataSource and Delegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *itemNumber = [self itemNumberForIndexPath:indexPath];
    CBLModel *story = [HNStoryManager.sharedInstance modelForItemNumber:itemNumber];
    NSNumber *rowHeight = WSM_LAZY(self.rowHeightDictionary[itemNumber],
                                   @([UITableViewCell getCellHeightForStory:(HNStory *)story
                                                                       view:self.view]));
    return [rowHeight floatValue];
}

- (NSArray *)tableView:(UITableView *)tableView
editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *rowActions = @[];
    UITableViewRowAction *hide = [UITableViewRowAction
                                  rowActionWithStyle:UITableViewRowActionStyleNormal
                                  title:@"Hide"
                                  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                  {
                                      [Flurry logEvent:@"Hide"];
                                      NSNumber *iNumber = [self itemNumberForIndexPath:indexPath];
                                      [self.tableView deselectRowAtIndexPath:indexPath
                                                                    animated:YES];
                                      [self.tableView beginUpdates];
                                      [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                                            withRowAnimation:UITableViewRowAnimationRight];
                                      [[HNStoryManager sharedInstance] hideStory:iNumber];
                                      [self.tableView endUpdates];
                                      for (NSIndexPath *path in self.tableView.indexPathsForVisibleRows) {
                                          [self updateCell:[self.tableView cellForRowAtIndexPath:path]
                                               atIndexPath:path
                                                   shimmer:NO];
                                      }
                                  }];
    hide.backgroundColor = [WSMColorPalette colorGradient:kWSMGradientBlack
                                                 forIndex:0
                                                  ofCount:0
                                                 reversed:NO];
    rowActions = [rowActions arrayByAddingObject:hide];
    return rowActions;
}

#define cellIdentifier @"storyCell"

- (void)updateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
           shimmer:(BOOL)shouldShimmer {
    NSNumber *number = [self itemNumberForIndexPath:indexPath];
    HNStory *story = (HNStory *) [HNStoryManager.sharedInstance modelForItemNumber:number];
    [cell prepareForHeadline:story.document.userProperties path:indexPath];
    UIImage *image = [HNStoryManager.sharedInstance
                      getPlaceholderAndFaviconForItemNumber:number
                      callback:^(UIImage *favicon) {
                          if (favicon) {
                              UITableViewCell *currentCell =
                              [self.tableView cellForRowAtIndexPath:
                               [self indexPathForItemNumber:number]];
                              [currentCell setFavicon:favicon];
                          }
                      }];
    [cell setFavicon:image];
    if (shouldShimmer) {
        [cell shimmerFor:1.0f];
    }
}

- (NSNumber *)itemNumberForIndexPath:(NSIndexPath *)path {
    return self.currentSortedTopStories[path.row];
}

- (NSIndexPath *)indexPathForItemNumber:(NSNumber *)itemNumber {
    return [NSIndexPath indexPathForRow:[self.currentSortedTopStories indexOfObject:itemNumber]
                              inSection:newsSection];;
}

- (NSArray *)currentSortedTopStories {
    return HNStoryManager.sharedInstance.currentTopStories;
}

@end
