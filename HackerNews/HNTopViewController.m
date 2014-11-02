//
//  ViewController.m
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "AppDelegate.h"
#import "HNTopViewController.h"
#import "HNWebViewController.h"
#import "HNTextViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UITableViewCell+HNHeadline.h"
#import "NSCache+WSMUtilities.h"
#import "UIView+WSMUtilities.h"
#import "CBLDocument+WSMUtilities.h"

typedef NS_ENUM(NSInteger, HNSortStyle) {
    kHNSortStyleRank,
    kHNSortStylePoints,
    kHNSortStyleComments
};

@interface HNTopViewController ()

@property (nonatomic, strong) Firebase *topStoriesAPI;
@property (nonatomic, strong) Firebase *itemsAPI;

@property (nonatomic, strong) CBLDatabase *newsDatabase;
@property (nonatomic, strong) CBLDocument *topStoriesDocument;
@property (nonatomic, strong) RACSubject *topStoriesSubject;
@property (nonatomic, strong) NSMutableDictionary *observationDictionary;
@property (nonatomic, strong) NSMutableDictionary *rowHeightDictionary;

@property (nonatomic, strong) NSCache *faviconCache;

@property (nonatomic) HNSortStyle sortStyle;
@property (nonatomic) NSMutableArray *currentSortedTopStories;

@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation HNTopViewController

#pragma mark - Property Instantiation

- (NSMutableDictionary *)observationDictionary {
    return WSM_LAZY(_observationDictionary, @{}.mutableCopy);
}

- (NSMutableDictionary *)rowHeightDictionary {
    return WSM_LAZY(_rowHeightDictionary, @{}.mutableCopy);
}

- (NSCache *)faviconCache {
    return WSM_LAZY(_faviconCache, NSCache.new);
}

- (NSOperationQueue *)queue {
    return WSM_LAZY(_queue, ({
        NSOperationQueue *q = [[NSOperationQueue alloc] init];
        q.maxConcurrentOperationCount = 1;
        q;
    }));
}

- (CBLDatabase *)newsDatabase {
    return WSM_LAZY(_newsDatabase, ({
        NSError *error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:@"hackernews" error:&error];
        WSMLog(error, @"Error initializing database: %@",error);
        [db compact:nil];
        db;
    }));
}

- (NSMutableArray*)currentSortedTopStories {
    return WSM_LAZY(_currentSortedTopStories,
                    [self arrayWithCurrentSortFilter:self.topStoriesDocument[@"stories"]]);
}

- (CBLDocument *)topStoriesDocument {
    return WSM_LAZY(_topStoriesDocument, [self.newsDatabase documentWithID:@"topStories"]);
}

- (RACSubject *)topStoriesSubject {
    return WSM_LAZY(_topStoriesSubject, [RACSubject subject]);
}

#pragma mark - View Lifecycle Managment

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = self.hackerBeige;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.topStoriesAPI = [delegate.hackerAPI childByAppendingPath:@"topstories"];
    self.itemsAPI = [delegate.hackerAPI childByAppendingPath:@"item"];
    
    [[[NSNotificationCenter.defaultCenter
       rac_addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil]
      takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        self.rowHeightDictionary = nil;
        [self.tableView reloadData];
    }];
    
    [self removeOldObservations];
}

- (void)removeOldObservations {
    [[[self.topStoriesSubject combinePreviousWithStart:@[].mutableCopy
                                                reduce:^id(NSMutableArray *old, NSMutableArray *new)
       {
           [old removeObjectsInArray:new];
           return old;
       }] map:^NSArray *(NSMutableArray *oldStories) {
           NSNull *null = [NSNull null];
           NSMutableArray *staleObservations = [[self.observationDictionary objectsForKeys:oldStories
                                                                            notFoundMarker:null] mutableCopy];
           [self.observationDictionary removeObjectsForKeys:oldStories];
           [staleObservations removeObject:null];
           return staleObservations;
       }] subscribeNext:^(NSMutableArray *oldObservations) {
           for (Firebase *observation in oldObservations) {
               [observation removeAllObservers];
           }
       }];
}

- (void)viewWillAppear:(BOOL)animated {
    [self formatTitleView];
    @weakify(self);
    [self.topStoriesAPI observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        @strongify(self);
        NSArray *previous = self.topStoriesDocument[@"stories"];
        [self.topStoriesDocument mergeUserProperties:@{@"stories":snapshot.value} error:nil];
        NSArray *current = snapshot.value;
        NSMutableArray *previousSorted = [self arrayWithCurrentSortFilter:previous];
        self.currentSortedTopStories = [self arrayWithCurrentSortFilter:current];
        [self updateTableView:previousSorted current:self.currentSortedTopStories];
        [self.topStoriesSubject sendNext:self.currentSortedTopStories];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    for (NSIndexPath *path in self.tableView.indexPathsForVisibleRows) {
        [self observeAndGetDocumentForItem:[self itemNumberForIndexPath:path]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    self.parentViewController.navigationItem.titleView = nil;
    [self.topStoriesSubject sendNext:@[].mutableCopy];
    [self.topStoriesAPI removeAllObservers];
}

#define newsSection 0

- (void)updateTableView:(NSArray *)previous current:(NSArray *)current {
    NSMutableArray *newCells = @[].mutableCopy;
    NSMutableArray *changedCells = @[].mutableCopy;
    if ([self.tableView numberOfRowsInSection:0] == 0) {
        [self.tableView reloadData];
    } else {
        [self.tableView beginUpdates];
        for (NSInteger i = 0; i < current.count; i++) {
            BOOL previouslyContained = [previous containsObject:current[i]];
            NSUInteger previousItemIndex = [previous indexOfObject:current[i]];
            if (!previouslyContained) {
                [newCells addObject:[NSIndexPath indexPathForRow:i inSection:newsSection]];
            } else if (previouslyContained && ![current[i] isEqualToNumber:previous[i]]) {
                NSIndexPath *oldPath = [NSIndexPath indexPathForRow:previousItemIndex
                                                          inSection:newsSection];
                NSIndexPath *newPath = [NSIndexPath indexPathForRow:i inSection:newsSection];
                [self.tableView moveRowAtIndexPath:oldPath toIndexPath:newPath];
                [changedCells addObject:oldPath];
            }
        }
        [self.tableView endUpdates];
        for (NSIndexPath *path in [newCells arrayByAddingObjectsFromArray:changedCells]) {
            NSNumber *itemNumber = [self itemNumberForIndexPath:path];
            CBLDocument *document = [self observeAndGetDocumentForItem:itemNumber];
            NSString *faviconURL = [self cacheFaviconForItem:itemNumber url:document[@"url"]];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
            [cell prepareForHeadline:document.properties iconData:self.faviconCache[faviconURL] path:path];
        }
    }
}

#define Lifecycle Helpers

- (void)formatTitleView {
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"Points", @""),
                                                                                       NSLocalizedString(@"Rank", @""),
                                                                                       NSLocalizedString(@"Comments", @"")
                                                                                       ]];
    segmentedControl.selectedSegmentIndex = 1;
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.frame = CGRectMake(0, 0, 200.0f, 30.0f);
    [segmentedControl addTarget:self action:@selector(sortCategory:) forControlEvents:UIControlEventValueChanged];
    self.parentViewController.navigationItem.titleView = segmentedControl;
}

- (void)sortCategory:(UISegmentedControl *)sortSegment {
    NSArray *previousSorted = self.currentSortedTopStories;
    switch (sortSegment.selectedSegmentIndex) {
        case 0: {
            self.sortStyle = kHNSortStylePoints;
        } break;
        case 1: {
            self.sortStyle = kHNSortStyleRank;
        } break;
        case 2: {
            self.sortStyle = kHNSortStyleComments;
        } break;
    }
    self.currentSortedTopStories = [self arrayWithCurrentSortFilter:previousSorted];
    [self updateTableView:previousSorted current:self.currentSortedTopStories];
}

- (NSMutableArray *)arrayWithCurrentSortFilter:(NSArray *)unsortedArray {
    switch (self.sortStyle) {
        case kHNSortStylePoints: {
            NSMutableArray *sortedArray = [unsortedArray sortedArrayUsingComparator:
                                           ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                                               CBLDocument *document1 = [self.newsDatabase documentWithID:[obj1 stringValue]];
                                               CBLDocument *document2 = [self.newsDatabase documentWithID:[obj2 stringValue]];
                                               NSInteger score1 = [document1[@"score"] integerValue];
                                               NSInteger score2 = [document2[@"score"] integerValue];
                                               WSM_COMPARATOR(score1 > score2);
                                           }].mutableCopy;
            return sortedArray;
        } break;
        case kHNSortStyleComments: {
            NSMutableArray *sortedArray = [unsortedArray sortedArrayUsingComparator:
                                           ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                                               CBLDocument *document1 = [self.newsDatabase documentWithID:[obj1 stringValue]];
                                               CBLDocument *document2 = [self.newsDatabase documentWithID:[obj2 stringValue]];
                                               NSInteger comments1 = [document1[@"kids"] count];
                                               NSInteger comments2 = [document2[@"kids"] count];
                                               WSM_COMPARATOR(comments1 > comments2);
                                           }].mutableCopy;
            return sortedArray;
        } break;
        default: {
            return [self.topStoriesDocument[@"stories"] mutableCopy];
        } break;
    }
}

#pragma mark - TableView DataSource and Delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *itemNumber = [self itemNumberForIndexPath:indexPath];
    CBLDocument *document = [self observeAndGetDocumentForItem:itemNumber];
    NSNumber *rowHeight = WSM_LAZY(self.rowHeightDictionary[itemNumber],
                                   @([UITableViewCell getCellHeightForDocument:document
                                                                          view:self.view]));
    return [rowHeight floatValue];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.currentSortedTopStories count];
}

- (NSNumber *)itemNumberForIndexPath:(NSIndexPath *)path {
    return self.currentSortedTopStories[path.row];
}
- (NSIndexPath *)indexPathForItemNumber:(NSNumber *)itemNumber {
    return [NSIndexPath indexPathForRow:[self.currentSortedTopStories indexOfObject:itemNumber]
                              inSection:newsSection];;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = self.hackerBeige;
}

#define CELL_IDENTIFIER @"storyCell"

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    WSM_LAZY(cell, [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CELL_IDENTIFIER]);
    
    NSNumber *itemNumber = [self itemNumberForIndexPath:indexPath];
    NSDictionary *properties = [[self observeAndGetDocumentForItem:itemNumber] properties];
    NSString *faviconURL = [self cacheFaviconForItem:itemNumber url:properties[@"url"]];
    
    [cell prepareForHeadline:properties iconData:self.faviconCache[faviconURL] path:indexPath];
    return cell;
}

- (CBLDocument *)observeAndGetDocumentForItem:(NSNumber *)itemNumber {
    __block CBLDocument *storyDocument = [self.newsDatabase documentWithID:[itemNumber stringValue]];
    if (!storyDocument.properties) {
        [storyDocument mergeUserProperties:@{@"by":@"rismay",
                                             @"id":@0,
                                             @"kids":@[],
                                             @"score":@0,
                                             @"text":@"",
                                             @"time":@0,
                                             @"title":@"Fetching Story...",
                                             @"type":@"story",
                                             @"url":@""} error:nil];
    }
    WSM_LAZY(self.observationDictionary[itemNumber], ({
        Firebase *base = [self.itemsAPI childByAppendingPath:[itemNumber stringValue]];
        @weakify(self);
        [base observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            @strongify(self);
            [storyDocument mergeUserProperties:snapshot.value error:nil];
            //Get Favicon
            NSString *faviconURL = [self cacheFaviconForItem:itemNumber url:storyDocument[@"url"]];
            CGFloat newRowHeight = [UITableViewCell getCellHeightForDocument:storyDocument
                                                                        view:self.view];
            CGFloat oldRowHeight = [self.rowHeightDictionary[itemNumber] floatValue];
            NSIndexPath *indexPath = [self indexPathForItemNumber:itemNumber];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell prepareForHeadline:storyDocument.properties
                            iconData:self.faviconCache[faviconURL]
                                path:indexPath];
            if (newRowHeight != oldRowHeight) {
                //Reloading rows, even just 1 is naive. So we have to get the cell and configue it.
                self.rowHeightDictionary[itemNumber] = @(newRowHeight);
                [self.tableView reloadRowsAtIndexPaths:@[[self indexPathForItemNumber:itemNumber]] withRowAnimation:UITableViewRowAnimationNone];
            }
            [cell.textLabel shimmerFor:1.0f];
            [cell.detailTextLabel shimmerFor:1.0f];
        }];
        base;
    }));
    return storyDocument;
}

- (NSString *)cacheFaviconForItem:(NSNumber *)itemNumber url:(NSString *)urlString {
    NSString *faviconURL = [self schemeAndHostFromURLString:urlString];
    if (faviconURL && !self.faviconCache[faviconURL]) {
        [self.queue addOperationWithBlock:^{
            NSURL *nativeFavicon = [NSURL URLWithString:
                                    [faviconURL stringByAppendingString:@"/favicon.ico"]];
            NSPurgeableData *faviconData = [NSPurgeableData dataWithContentsOfURL:nativeFavicon];
            UIImage *faviconImage = [UIImage imageWithData:faviconData];
            if (!faviconImage) {
                NSURL *googleFavicon = [NSURL URLWithString:[NSString stringWithFormat:
                                                             @"http://www.google.com/s2/favicons?domain=%@", faviconURL]];
                faviconData = [NSPurgeableData dataWithContentsOfURL:googleFavicon];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (faviconData) {
                    self.faviconCache[faviconURL] = faviconData;
                }
                NSIndexPath *indexPath = [self indexPathForItemNumber:itemNumber];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                CBLDocument *storyDocument = [self observeAndGetDocumentForItem:itemNumber];
                [cell prepareForHeadline:storyDocument.properties
                                iconData:faviconData
                                    path:indexPath];
            });
        }];
    }
    return faviconURL;
}

- (NSString *)schemeAndHostFromURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url.scheme && url.host) {
        return [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *itemNumber = [self itemNumberForIndexPath:indexPath];
    CBLDocument *document = [self.newsDatabase documentWithID:[itemNumber stringValue]];
    if ([document[@"type"] isEqualToString:@"story"]) {
        if (![document[@"url"] isEqualToString:@""]) {
            HNWebViewController *controller = [self.storyboard
                                               instantiateViewControllerWithIdentifier:@"HNWebViewController"];
            controller.title = document[@"title"];
            controller.requestURL =  [NSURL URLWithString:document[@"url"]];
            [self.parentViewController.navigationController pushViewController:controller animated:YES];
        } else if (![document[@"text"] isEqualToString:@""]) {
            [self performSegueWithIdentifier:@"textViewSegue" sender:document[@"text"]];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [Flurry logEvent:document[@"type"]];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.rowHeightDictionary = nil;
        [self.tableView reloadData];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {}];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSString *)sender {
    if ([segue.identifier isEqualToString:@"textViewSegue"]) {
        HNTextViewController *controller = segue.destinationViewController;
        controller.text = sender;
    }
}

-(UIColor *)hackerOrange {
    return SKColorMakeRGB(255.0f, 102.0f, 0.0f);
}

-(UIColor *)hackerBeige {
    return SKColorMakeRGB(245.0f, 245.0f, 238.0f);
}

- (void)didReceiveMemoryWarning {
    [Flurry logEvent:@"MemoryWarning"];
}

@end
