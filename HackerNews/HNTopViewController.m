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

@interface HNTopViewController ()

@property (nonatomic, strong) Firebase *topStoriesAPI;
@property (nonatomic, strong) Firebase *itemsAPI;

@property (nonatomic, strong) CBLDatabase *newsDatabase;
@property (nonatomic, strong) CBLDocument *topStoriesDocument;
@property (nonatomic, strong) RACSubject *topStoriesSubject;
@property (nonatomic, strong) NSMutableDictionary *observationDictionary;

@property (nonatomic, strong) NSMutableDictionary *rowHeights;

@end

@implementation HNTopViewController

#pragma mark - Property Instantiation

- (NSMutableDictionary *)rowHeights {
    return WSM_LAZY(_rowHeights, @{}.mutableCopy);
}

#pragma mark - View Lifecycle Managment

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = self.hackerBeige;
//    self.tableView.estimatedRowHeight = 50; This is horrible don't use it!
//    self.tableView.rowHeight = UITableViewAutomaticDimension; Seriously Apple....
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.topStoriesAPI = [delegate.hackerAPI childByAppendingPath:@"topstories"];
    self.itemsAPI = [delegate.hackerAPI childByAppendingPath:@"item"];
    
    [self removeOldObservations];
}

- (void)removeOldObservations {
    [[[self.topStoriesSubject combinePreviousWithStart:@[].mutableCopy reduce:^id(NSMutableArray *old, NSMutableArray *new) {
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
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows
                          withRowAnimation:UITableViewRowAnimationNone];
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
                    NSIndexPath *oldPath = [NSIndexPath indexPathForRow:previousItemIndex inSection:newsSection];
                    NSIndexPath *newPath = [NSIndexPath indexPathForRow:i inSection:newsSection];
                    [self.tableView moveRowAtIndexPath:oldPath toIndexPath:newPath];
                    [changedCells addObject:oldPath];
                }
            }
            [self.tableView endUpdates];
        } completion:^(BOOL finished) {
            [self.tableView reloadRowsAtIndexPaths:newCells withRowAnimation:UITableViewRowAnimationLeft];
            [self.tableView reloadRowsAtIndexPaths:changedCells withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
}

#pragma mark - Lazy Property Instantiation

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

#pragma mark - TableView DataSource and Delegate methods

- (NSMutableDictionary*)observationDictionary {
    return WSM_LAZY(_observationDictionary, @{}.mutableCopy);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.topStoriesDocument[@"stories"] count];
}

- (NSNumber *)itemNumberForeIndexPath:(NSIndexPath *)path {
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
    
    NSNumber *itemNumber = [self itemNumberForeIndexPath:indexPath];
    NSDictionary *properties = [[self observeAndGetdocumentForItem:itemNumber] userProperties];
    [cell prepareForHeadline:properties path:indexPath];
    return cell;
}

- (CBLDocument *)observeAndGetdocumentForItem:(NSNumber *)itemNumber {
    __block CBLDocument *storyDocument = [self.newsDatabase documentWithID:[itemNumber stringValue]];
    WSM_LAZY(self.observationDictionary[itemNumber], ({
        Firebase *base = [self.itemsAPI childByAppendingPath:[itemNumber stringValue]];
        @weakify(self);
        [base observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            @strongify(self);
            CBLUnsavedRevision *documentRevision = [storyDocument newRevision];
            [documentRevision setUserProperties:snapshot.value];
            [documentRevision save:nil];
            [self.tableView reloadRowsAtIndexPaths:@[[self indexPathForItemNumber:itemNumber]]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }];
        base;
    }));
    return storyDocument;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *itemNumber = [self itemNumberForeIndexPath:indexPath];
    CBLDocument *document = [self.newsDatabase documentWithID:[itemNumber stringValue]];
    if ([document[@"type"] isEqualToString:@"story"]) {
        if (![document[@"url"] isEqualToString:@""]) {
            [self performSegueWithIdentifier:@"webViewSegue" sender:indexPath];
        } else if (![document[@"text"] isEqualToString:@""]) {
            [self performSegueWithIdentifier:@"textViewSegue" sender:indexPath];
        }
    }
    [Flurry logEvent:document[@"type"]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)indexPath {
    NSNumber *itemNumber = [self itemNumberForeIndexPath:indexPath];
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
