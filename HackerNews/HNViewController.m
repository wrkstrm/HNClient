//
//  ViewController.m
//  HackerNews
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "AppDelegate.h"
#import "HNViewController.h"
#import "HNTopStories.h"
#import "HNWebViewController.h"

@interface HNViewController ()

@property (nonatomic, strong) Firebase *topStoriesAPI;
@property (nonatomic, strong) Firebase *itemsAPI;
@property (nonatomic, strong) CBLDocument *topStoriesDocument;
@property (nonatomic, strong) RACSubject *topStoriesSubject;
@property (nonatomic, strong) NSMutableDictionary *firebaseDictionary;

@end

@implementation HNViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Hacker News Live";
    self.navigationController.navigationBar.BarTintColor = self.hackerOrange;
    self.tableView.backgroundColor = self.hackerBeige;
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.topStoriesAPI = [delegate.hackerAPI childByAppendingPath:@"topstories"];
    self.itemsAPI = [delegate.hackerAPI childByAppendingPath:@"item"];
    
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
    
    [self removeOldObservations];
}

- (void)removeOldObservations {
    [[[self.topStoriesSubject combinePreviousWithStart:@[].mutableCopy
                                                reduce:^id(NSMutableArray *old, NSMutableArray *new) {
                                                    [old removeObjectsInArray:new];
                                                    return old;
                                                }] map:^NSArray *(NSMutableArray *oldStories) {
                                                    NSMutableArray *staleObservations = [[self.firebaseDictionary objectsForKeys:oldStories
                                                                                                                  notFoundMarker:[NSNull null]] mutableCopy];
                                                    [staleObservations removeObject:[NSNull null]];
                                                    return staleObservations;
                                                }] subscribeNext:^(NSMutableArray *oldObservations) {
                                                    for (Firebase *observation in oldObservations) {
                                                        [observation removeAllObservers];
                                                    }
                                                }];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.topStoriesSubject sendNext:nil];
}

#define newsSection 0

- (void)updateTableView:(NSArray *)previous current:(NSArray *)current {
    NSMutableArray *newCells = @[].mutableCopy;
    NSMutableArray *changedCells = @[].mutableCopy;
    [UIView animateWithDuration:2.5f animations:^{
        [self.tableView beginUpdates];
        for (NSInteger i = 0; i < current.count; i++) {
            BOOL previouslyContained = [previous containsObject:current[i]];
            NSUInteger previousItemIndex = [previous indexOfObject:current[i]];
            if (previous.count < i || !previouslyContained) {
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
        [self.tableView reloadRowsAtIndexPaths:changedCells withRowAnimation:UITableViewRowAnimationFade];
    }];
}

#pragma mark - Lazy Property Instantiation

- (CBLDocument *)topStoriesDocument {
    return WSM_LAZY(_topStoriesDocument, ({
        CBLDatabase *newsDatabase = [[CBLManager sharedInstance] databaseNamed:@"hackernews" error:nil];
        [newsDatabase compact:nil];
        [newsDatabase documentWithID:@"topStories"];
    }));
}

- (RACSubject *)topStoriesSubject {
    return WSM_LAZY(_topStoriesSubject, [RACSubject subject]);
}

#pragma mark - TableView DataSource and Delegate methods

- (NSMutableDictionary*)firebaseDictionary {
    return WSM_LAZY(_firebaseDictionary, @{}.mutableCopy);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
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

#define cellIdentifier @"storyCell"

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    NSNumber *itemNumber = [self itemNumberForeIndexPath:indexPath];
    NSDictionary *properties = [[self observeAndGetdocumentForItem:itemNumber] userProperties];
    
    if (properties) {
        cell.textLabel.text = properties[@"title"];
        NSInteger score = [properties[@"score"] integerValue];
        NSString *pointString = [NSString stringWithFormat:@"%li %@",
                                 (long)score, (score != 1) ? @"points":@"point"];
        NSString *username = [NSString stringWithFormat:@" by %@", properties[@"by"]];
        
        cell.detailTextLabel.text = [pointString stringByAppendingString:username];
    } else {
        cell.textLabel.text = @"Fetching Story...";
        cell.detailTextLabel.text = @"0 points by rismay";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"webViewSegue" sender:indexPath];
}

- (CBLDocument *)observeAndGetdocumentForItem:(NSNumber *)itemNumber {
    CBLDatabase *newsDatabase = [[CBLManager sharedInstance] databaseNamed:@"hackernews" error:nil];
    __block CBLDocument *storyDocument = [newsDatabase documentWithID:[itemNumber stringValue]];
    
    @weakify(self);
    WSM_LAZY(self.firebaseDictionary[itemNumber], ({
        Firebase *base = [self.itemsAPI childByAppendingPath:[itemNumber stringValue]];
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

-(UIColor *)hackerOrange {
    return SKColorMakeRGB(255.0f, 102.0f, 0.0f);
}

-(UIColor *)hackerBeige {
    return SKColorMakeRGB(245.0f, 245.0f, 238.0f);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)sender {
    if ([segue.identifier isEqualToString:@"webViewSegue"]) {
        HNWebViewController *controller = segue.destinationViewController;
        
        CBLDocument *document = [self observeAndGetdocumentForItem:[self itemNumberForeIndexPath:sender]];
        NSURL *storyURL = [NSURL URLWithString:document[@"url"]];
        NSLog(@"URL: %@", storyURL);
        controller.request =  [NSURLRequest requestWithURL:storyURL];
    }
}
@end
