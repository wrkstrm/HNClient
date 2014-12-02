//
//  UITableViewController+HNUtilities.h
//  HackerNews
//
//  Created by Cristian Monterroza on 11/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewController (HNUtilities)

/**
 The Update TableView Algo works like this and only works for tableViews with 1 section.
 1. If starting out, reload data.
 2. If removing cells, reload data. This will be updated later.
 3. If adding cells:
 A. only insert cells at the end.
 B. If not previosly present, update cell which will now contain it.
 C. If previously present, try to animate the cell to new position, then update.
 */

+ (NSArray *)tableView:(UITableView*)tableView
         updateSection:(NSInteger)section
              previous:(NSArray *)previous
               current:(NSArray *)current;

@end
