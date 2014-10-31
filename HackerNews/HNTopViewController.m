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

@interface HNTopViewController ()

@property (nonatomic, strong) Firebase *topStoriesAPI;
@property (nonatomic, strong) Firebase *itemsAPI;

@property (nonatomic, strong) CBLDatabase *newsDatabase;
@property (nonatomic, strong) CBLDocument *topStoriesDocument;
@property (nonatomic, strong) RACSubject *topStoriesSubject;
@property (nonatomic, strong) NSMutableDictionary *observationDictionary;
@property (nonatomic, strong) NSMutableDictionary *rowHeightDictionary;

@property (nonatomic, strong) NSCache *faviconCache;

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

- (CBLDatabase *)newsDatabase {
    return WSM_LAZY(_newsDatabase, ({
        NSError *error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:@"hackernews" error:&error];
        WSMLog(error, @"Error initializing database: %@",error);
        [db compact:nil];
        db;
    }));
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
           [self.observationDictionary removeObjectForKey:oldStories];
           [staleObservations removeObject:null];
           return staleObservations;
       }] subscribeNext:^(NSMutableArray *oldObservations) {
           for (Firebase *observation in oldObservations) {
               [observation removeAllObservers];
           }
       }];
}

- (void)viewWillAppear:(BOOL)animated {
    self.parentViewController.title = @"HN 100";
    @weakify(self);
    [self.topStoriesAPI observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        @strongify(self);
        CBLUnsavedRevision *revision = [self.topStoriesDocument newRevision];
        NSArray *current = snapshot.value;
        NSArray *previous = revision[@"stories"];
        revision[@"stories"] = snapshot.value;
        [revision save:nil];
        [self updateTableView:previous current:current];
        [self.topStoriesSubject sendNext:current];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    for (NSIndexPath *path in self.tableView.indexPathsForVisibleRows) {
        [self observeAndGetDocumentForItem:[self itemNumberForIndexPath:path]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.topStoriesSubject sendNext:@[].mutableCopy];
    [self.topStoriesAPI removeAllObservers];
}

#define newsSection 0

- (void)updateTableView:(NSArray *)previous current:(NSArray *)current {
    NSMutableArray *newCells = @[].mutableCopy;
    NSMutableArray *changedCells = @[].mutableCopy;
    if (previous.count == 0) {
        [self.tableView reloadData];
    } else {
        [UIView animateWithDuration:1.0f animations:^{
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
        } completion:^(BOOL finished) {
            [self.tableView reloadRowsAtIndexPaths:newCells
                                  withRowAnimation:UITableViewRowAnimationLeft];
            [self.tableView reloadRowsAtIndexPaths:changedCells
                                  withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
}

#pragma mark - TableView DataSource and Delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CBLDocument *document = [self observeAndGetDocumentForItem:[self itemNumberForIndexPath:indexPath]];
    NSNumber *rowHeight = WSM_LAZY(self.rowHeightDictionary[[self itemNumberForIndexPath:indexPath]],
                                   @([UITableViewCell getCellHeightForDocument:document view:self.view]));
    return [rowHeight floatValue];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.topStoriesDocument[@"stories"] count];
}

- (NSNumber *)itemNumberForIndexPath:(NSIndexPath *)path {
    return self.topStoriesDocument[@"stories"][path.row];
}
- (NSIndexPath *)indexPathForItemNumber:(NSNumber *)itemNumber {
    return [NSIndexPath indexPathForRow:[self.topStoriesDocument[@"stories"] indexOfObject:itemNumber]
                              inSection:newsSection];;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = self.hackerBeige;
}

#define CELL_IDENTIFIER @"storyCell"

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    WSM_LAZY(cell, [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CELL_IDENTIFIER]);
    
    NSNumber *itemNumber = [self itemNumberForIndexPath:indexPath];
    NSDictionary *properties = [[self observeAndGetDocumentForItem:itemNumber] userProperties];
    NSString *faviconURL = [self cacheFaviconForItem:itemNumber url:properties[@"url"]];
    
    [cell prepareForHeadline:properties iconData:self.faviconCache[faviconURL] path:indexPath];
    return cell;
}

- (CBLDocument *)observeAndGetDocumentForItem:(NSNumber *)itemNumber {
    __block CBLDocument *storyDocument = [self.newsDatabase documentWithID:[itemNumber stringValue]];
    if (!storyDocument.properties) {
        CBLUnsavedRevision *documentRevision = [storyDocument newRevision];
        [documentRevision setUserProperties:@{@"by":@"rismay",
                                              @"id":@0,
                                              @"kids":@[],
                                              @"score":@0,
                                              @"text":@"",
                                              @"time":@0,
                                              @"title":@"Fetching Story...",
                                              @"type":@"story",
                                              @"url":@""
                                              }];
        [documentRevision save:nil];
    }
    WSM_LAZY(self.observationDictionary[itemNumber], ({
        Firebase *base = [self.itemsAPI childByAppendingPath:[itemNumber stringValue]];
        @weakify(self);
        [base observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            @strongify(self);
            CBLUnsavedRevision *documentRevision = [storyDocument newRevision];
            [documentRevision setUserProperties:snapshot.value];
            [documentRevision save:nil];
            //Get Favicon
            NSString *faviconURL = [self cacheFaviconForItem:itemNumber url:snapshot.value[@"url"]];
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
        }];
        base;
    }));
    return storyDocument;
}

- (NSString *)cacheFaviconForItem:(NSNumber *)itemNumber url:(NSString *)urlString {
    NSString *faviconURL = [self schemeAndHostFromURLString:urlString];
    if (faviconURL) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            if (!self.faviconCache[faviconURL]) {
                NSURL *nativeFavicon = [NSURL URLWithString:
                                        [faviconURL stringByAppendingString:@"/favicon.ico"]];
                NSPurgeableData *faviconData = [NSPurgeableData dataWithContentsOfURL:nativeFavicon];
                UIImage *faviconImage = [UIImage imageWithData:faviconData];
                if (!faviconImage) {
                    NSURL *googleFavicon = [NSURL URLWithString:[NSString stringWithFormat:
                                                                 @"http://www.google.com/s2/favicons?domain=%@", faviconURL]];
                    faviconData = [NSPurgeableData dataWithContentsOfURL:googleFavicon];
                }
                NSIndexPath *indexPath = [self indexPathForItemNumber:itemNumber];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                CBLDocument *storyDocument = [self observeAndGetDocumentForItem:itemNumber];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell prepareForHeadline:storyDocument.properties
                                    iconData:faviconData
                                        path:indexPath];
                });
                if (faviconData) {
                    self.faviconCache[faviconURL] = faviconData;
                }
            }
        });
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
            [self performSegueWithIdentifier:@"webViewSegue" sender:indexPath];
        } else if (![document[@"text"] isEqualToString:@""]) {
            [self performSegueWithIdentifier:@"textViewSegue" sender:indexPath];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [Flurry logEvent:document[@"type"]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)indexPath {
    NSNumber *itemNumber = [self itemNumberForIndexPath:indexPath];
    CBLDocument *document = [self.newsDatabase documentWithID:[itemNumber stringValue]];
    if ([segue.identifier isEqualToString:@"webViewSegue"]) {
        HNWebViewController *controller = segue.destinationViewController;
        NSURL *storyURL = [NSURL URLWithString:document[@"url"]];
        controller.request =  [NSURLRequest requestWithURL:storyURL];
    } else if ([segue.identifier isEqualToString:@"textViewSegue"]) {
        HNTextViewController *controller = segue.destinationViewController;
        controller.text = document[@"text"];
    }
}

-(UIColor *)hackerOrange {
    return SKColorMakeRGB(255.0f, 102.0f, 0.0f);
}

-(UIColor *)hackerBeige {
    return SKColorMakeRGB(245.0f, 245.0f, 238.0f);
}

@end
