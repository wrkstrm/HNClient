//
//  ViewController.h
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HNTopViewController : UITableViewController

@property (nonatomic, strong) NSMutableDictionary *rowHeightDictionary;
@property (nonatomic) NSMutableArray *currentSortedTopStories;

@end

