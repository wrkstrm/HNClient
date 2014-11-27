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

@property(nonatomic, strong) NSMutableArray *previouslyUncontainedCells;
@property(nonatomic, strong) NSMutableArray *changedCells;

@end

@implementation HNTopViewController

#pragma mark - Property Instantiation

- (NSMutableDictionary *)rowHeightDictionary {
    return WSM_LAZY(_rowHeightDictionary, @{}.mutableCopy);
}

#pragma mark - Tableview Update Managment

/**
 The Update TableView Algo goes like this:
 1. If starting out, reload data.
 2. If removing cells, reload data. This will be updated later.
 3. If adding cells:
 A. only insert cells at the end.
 B. If not previosly present, update cell which will now contain it.
 C. If previously present, try to animate the cell to new position, then update.
 */

#define newsSection 0

- (void)updateTableView:(NSArray *)previous current:(NSArray *)current {
    self.previouslyUncontainedCells = @[].mutableCopy;
    self.changedCells = @[].mutableCopy;
    if (previous.count == 0 || [self.tableView numberOfRowsInSection:0] == 0) {
        [self.tableView reloadData];
    } else if (previous.count > current.count) {
        NSLog(@"BEGIN: Number of Rows in Section: %lu", [self.tableView numberOfRowsInSection:0]);
        WSMLog(previous.count != current.count, @"Previous: %lu Current: %lu",
               previous.count, current.count);
        [self.tableView reloadData];
    } else {
        [Flurry logEvent:@"beginUpdates"];
        [self.tableView beginUpdates];
        for (NSInteger index = 0; index < current.count; index++) {
            BOOL previouslyContained = [previous containsObject:current[index]];
            NSUInteger previousItemIndex = [previous indexOfObject:current[index]];
            //If we have more rows currently than previously, just insert
            if (previous.count <= index) {
                NSIndexPath *newCell = [NSIndexPath indexPathForRow:index
                                                          inSection:newsSection];
                [self.tableView insertRowsAtIndexPaths:@[newCell]
                                      withRowAnimation:UITableViewRowAnimationTop];
            } else if (!previouslyContained) {
                [self.previouslyUncontainedCells addObject:[NSIndexPath indexPathForRow:index
                                                                              inSection:newsSection]];
            } else if (previouslyContained) {
                if (![current[index] isEqualToNumber:previous[index]]) {
                    NSIndexPath *oldPath = [NSIndexPath indexPathForRow:previousItemIndex
                                                              inSection:newsSection];
                    NSIndexPath *newPath = [NSIndexPath indexPathForRow:index
                                                              inSection:newsSection];
                    [self.tableView moveRowAtIndexPath:oldPath toIndexPath:newPath];
                    [self.changedCells addObject:oldPath];
                }
            }
        }
        [self.tableView endUpdates];
        [Flurry logEvent:@"endUpdates"];
        for (NSIndexPath *path in [self.previouslyUncontainedCells
                                   arrayByAddingObjectsFromArray:self.changedCells]) {
            NSNumber *number = [self itemNumberForIndexPath:path];
            HNStory *story = (HNStory *)[[HNStoryManager sharedInstance] modelForItemNumber:number];
            [self updateCellWithTuple:RACTuplePack(number, story)];
        }
    }
}

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
                                                            withRowAnimation:UITableViewRowAnimationBottom];
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
