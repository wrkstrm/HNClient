//
//  UITableViewController+HNUtilities.m
//  HackerNews
//
//  Created by Cristian Monterroza on 11/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "UITableViewController+HNUtilities.h"

@implementation UITableViewController (HNUtilities)

+ (NSArray *)tableView:(UITableView*)tableView
         updateSection:(NSInteger)section
              previous:(NSArray *)previous
               current:(NSArray *)current {
    NSMutableArray *previouslyUncontainedCells = @[].mutableCopy;
    NSMutableArray *changedCells = @[].mutableCopy;
    if (previous.count == 0 || [tableView numberOfRowsInSection:0] == 0) {
        [tableView reloadData];
    } else if (previous.count > current.count) {
        WSMLog(previous.count != current.count, @"Previous: %lu Current: %lu",
               (unsigned long)previous.count, (unsigned long)current.count);
        [tableView reloadData];
    } else {
        [Flurry logEvent:@"beginUpdates"];
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:0.5f
              initialSpringVelocity:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            [tableView beginUpdates];
            for (NSInteger index = 0; index < current.count; index++) {
                BOOL previouslyContained = [previous containsObject:current[index]];
                NSUInteger previousItemIndex = [previous indexOfObject:current[index]];
                //If we have more rows currently than previously, just insert
                if (previous.count <= index) {
                    NSIndexPath *newCell = [NSIndexPath indexPathForRow:index
                                                              inSection:section];
                    [tableView insertRowsAtIndexPaths:@[newCell]
                                     withRowAnimation:UITableViewRowAnimationTop];
                } else if (!previouslyContained) {
                    [previouslyUncontainedCells addObject:[NSIndexPath indexPathForRow:index
                                                                             inSection:section]];
                } else if (previouslyContained) {
                    if (![current[index] isEqualToNumber:previous[index]]) {
                        NSIndexPath *oldPath = [NSIndexPath indexPathForRow:previousItemIndex
                                                                  inSection:section];
                        NSIndexPath *newPath = [NSIndexPath indexPathForRow:index
                                                                  inSection:section];
                        [tableView moveRowAtIndexPath:oldPath toIndexPath:newPath];
                        [changedCells addObject:oldPath];
                    }
                }
            }
            [tableView endUpdates];
        } completion:^(BOOL finished) {}];
        [Flurry logEvent:@"endUpdates"];
    }
    return [previouslyUncontainedCells arrayByAddingObjectsFromArray:changedCells];
}

@end
