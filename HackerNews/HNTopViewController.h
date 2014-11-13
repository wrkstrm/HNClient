//
//  ViewController.h
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HNSortStyle) {
    kHNSortStyleRank,
    kHNSortStylePoints,
    kHNSortStyleComments
};

@interface HNTopViewController : UITableViewController

@property (nonatomic, strong) Firebase *topStoriesAPI;
@property (nonatomic, strong) Firebase *itemsAPI;


@property (nonatomic, strong) CBLDatabase *newsDatabase;
@property (nonatomic, strong) CBLDocument *topStoriesDocument;
@property (nonatomic, strong) RACSubject *topStoriesSubject;

@property (nonatomic) HNSortStyle sortStyle;

@property (nonatomic, strong) NSMutableDictionary *rowHeightDictionary;
@property (nonatomic, strong) NSMutableArray *currentSortedTopStories;

@property (nonatomic, strong) NSCache *faviconCache;

- (void)removeOldObservations;

- (NSNumber *)itemNumberForIndexPath:(NSIndexPath *)path;

- (CBLDocument *)observeAndGetDocumentForItem:(NSNumber *)itemNumber;

- (NSString *)cacheFaviconForItem:(NSNumber *)itemNumber url:(NSString *)urlString;

- (NSMutableArray *)arrayWithCurrentSortFilter;

- (void)updateTableView:(NSArray *)previous current:(NSArray *)current;

@end

