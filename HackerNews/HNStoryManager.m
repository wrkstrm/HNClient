//
//  HNStoryManager.m
//  HackerNews
//
//  Created by Cristian Monterroza on 11/19/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNStoryManager.h"
#import "HNUser.h"
#import "NSCache+WSMUtilities.h"

typedef NS_ENUM(NSInteger, HNSortStyle) {
    kHNSortStyleRank,
    kHNSortStylePoints,
    kHNSortStyleComments
};

@interface HNStoryManager ()

@property (nonatomic, strong) Firebase *hackerAPI;
@property (nonatomic, strong) Firebase *topStoriesAPI;
@property (nonatomic, strong) Firebase *itemsAPI;
@property (nonatomic) HNSortStyle sortStyle;

@property (nonatomic, strong) CBLDatabase *newsDatabase;
@property (nonatomic, strong) CBLDocument *topStoriesDocument;

@property (nonatomic, strong) NSMutableDictionary *firebaseSignalDictionary;
@property (nonatomic, strong) NSMutableDictionary *faviconKeySignalDictionary;


@property (nonatomic, strong) NSMutableDictionary *observationDictionary;
@property (nonatomic, strong) NSMutableDictionary *signalTuplesDictionary;

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableDictionary *storySignals;

@property (nonatomic, strong) NSCache *faviconCache;

//Placeholder Images
@property (nonatomic, strong) NSData *webImagePlaceholderData;

@end

@implementation HNStoryManager

WSM_SINGLETON_WITH_NAME(sharedInstance)

#define topStoriesDocID @"topstories"
#define webPlaceHolderName @"web_black"

- (instancetype)init {
    if (!(self = [super init])) return nil;
    _currentUser = [HNUser defaultUser] ?: [HNUser createDefaultUserWithProperties:nil];
    
    _newsDatabase = [_currentUser localDatabase];
    _newsDatabase.maxRevTreeDepth = 1;
    NSError *error;
    [_newsDatabase compact:&error];
    WSMLog(error, @"Error compacting database: %@", error);
    
    _topStoriesDocument = [_newsDatabase existingDocumentWithID:topStoriesDocID];
    WSM_LAZY(_topStoriesDocument, ({
        CBLDocument *doc = [_newsDatabase documentWithID:topStoriesDocID];
        NSError *error;
        [doc mergeUserProperties:@{@"stories":@[]} error:&error];
        WSMLog(error, @"ERROR: No topstories document - %@", error);
        doc;
    }));
    
    _queue = NSOperationQueue.new;
    _queue.maxConcurrentOperationCount = 1;
    _queue.qualityOfService = NSQualityOfServiceUserInitiated;
    
    //    _observationDictionary = @{}.mutableCopy;
    _firebaseSignalDictionary = @{}.mutableCopy;
    
    //    NSLog(@"Image path: %@", imagePath);
    _faviconCache = NSCache.new;
    _faviconCache[webPlaceHolderName] = [UIImage imageNamed:webPlaceHolderName];
    
    _hackerAPI = [[Firebase alloc] initWithUrl:@"https://hacker-news.firebaseio.com/v0/"];
    _topStoriesAPI = [_hackerAPI childByAppendingPath:@"topstories"];
    _itemsAPI = [_hackerAPI childByAppendingPath:@"item"];
    
    self.currentTopStories = self.topStoriesWithCurrentFilters;
    @weakify(self);
    [_topStoriesAPI observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        @strongify(self);
        if (snapshot.value) {
            [_topStoriesDocument mergeUserProperties:@{@"stories":snapshot.value} error: nil];
            self.currentTopStories = self.topStoriesWithCurrentFilters;
        }
    }];
    return self;
}

- (NSArray *)topStoriesWithCurrentFilters {
    NSArray *sortedArray;
    switch (self.sortStyle) {
        case kHNSortStylePoints: {
            sortedArray = [self.topStoriesDocument[@"stories"] sortedArrayUsingComparator:
                           ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                               CBLDocument *doc1 = [self.newsDatabase
                                                    documentWithID:[obj1 stringValue]];
                               CBLDocument *doc2 = [self.newsDatabase
                                                    documentWithID:[obj2 stringValue]];
                               NSInteger score1 = [doc1[@"score"] integerValue];
                               NSInteger score2 = [doc2[@"score"] integerValue];
                               WSM_COMPARATOR(score1 > score2);
                           }];
        } break;
        case kHNSortStyleComments: {
            sortedArray = [self.topStoriesDocument[@"stories"] sortedArrayUsingComparator:
                           ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                               CBLDocument *doc1 = [self.newsDatabase
                                                    documentWithID:[obj1 stringValue]];
                               CBLDocument *doc2 = [self.newsDatabase
                                                    documentWithID:[obj2 stringValue]];
                               NSInteger comments1 = [doc1[@"kids"] count];
                               NSInteger comments2 = [doc2[@"kids"] count];
                               WSM_COMPARATOR(comments1 > comments2);
                           }];
        } break;
        default: sortedArray = [self.topStoriesDocument[@"stories"] mutableCopy]; break;
    }
    NSLog(@"SortedArray: %@", sortedArray);
    return [sortedArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^
                                                     BOOL(NSNumber *storyNumber, NSDictionary *bindings) {
                                                         CBLDocument *document1 = [self.newsDatabase
                                                                                   documentWithID:[storyNumber stringValue]];
                                                         NSInteger score1 = [document1[@"score"] integerValue];
                                                         return ![self.currentUser.hiddenStories containsObject:storyNumber] || !(self.currentUser.minimumScore <=  score1);
                                                     }]];
    
}

- (RACSignal *)latestStateForItemNumber:(NSNumber *)storyNumber {
    return WSM_LAZY(self.signalTuplesDictionary[[storyNumber stringValue]], ({
        RACSignal *firebaseSignal = [self firebaseSignalForItemNumber:storyNumber];
        RACSignal *faviconSignal = [self faviconKeySignalForItemNumber:storyNumber];
        [RACSignal combineLatest:@[firebaseSignal, faviconSignal]
                          reduce:(id)^(CBLDocument *document, NSString *faviconKey){
                              return RACTuplePack(document, faviconKey);
                          }];
    }));
}

- (RACSignal *)firebaseSignalForItemNumber:(NSNumber *)itemNumber {
    return WSM_LAZY(self.firebaseSignalDictionary[[itemNumber stringValue]], ({
        RACSubject *storySubject = RACSubject.subject;
        RACSignal *replay = storySubject.replayLast;
        __block CBLDocument *storyDoc = [self.newsDatabase documentWithID:[itemNumber stringValue]];
        if (!storyDoc.userProperties) {
            [storyDoc mergeUserProperties:@{@"by":@"rismay",
                                            @"id":@0,
                                            @"kids":@[],
                                            @"score":@0,
                                            @"text":@"",
                                            @"time":@0,
                                            @"title":@"Fetching Story...",
                                            @"type":@"story",
                                            @"url":@""}
                                    error:nil];
        }
        Firebase *base = [self.itemsAPI childByAppendingPath:[itemNumber stringValue]];
        @weakify(storySubject);
        [base observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            @strongify(storySubject);
            if (snapshot.value) {
                NSError *error;
                WSMLog([storyDoc mergeUserProperties:snapshot.value error:&error],
                       @"Error merging doc after Firebase Event: %@", error);
                [storySubject sendNext:storyDoc];
            }
        }];
        @weakify(self);
        [storySubject doCompleted:^{
            @strongify(self);
            [base removeAllObservers];
            [self.firebaseSignalDictionary removeObjectForKey:[itemNumber stringValue]];
        }];
        
        [storySubject sendNext:storyDoc];
        replay;
    }));
}

- (RACSignal *)faviconKeySignalForItemNumber:(NSNumber *)itemNumber {
    return WSM_LAZY(self.faviconKeySignalDictionary[[itemNumber stringValue]], ({
        RACSubject *storySubject = RACSubject.subject;
        RACSignal *replay = storySubject.replayLast;
        CBLDocument *storyDoc = [self.newsDatabase documentWithID:[itemNumber stringValue]];
        NSString *hostURL = [self schemeAndHostFromURLString:storyDoc[@"url"]];
        if (hostURL && !self.faviconCache[hostURL]) {
            [storySubject sendNext:webPlaceHolderName];
            [self.queue addOperationWithBlock:^{
                NSURL *faviconURL = [NSURL URLWithString:
                                     [hostURL stringByAppendingString:@"/favicon.ico"]];
                NSData *faviconData = [NSData dataWithContentsOfURL:faviconURL];
                UIImage *faviconImage = [UIImage imageWithData:faviconData];
                if (!faviconImage) {
                    NSString *urlString = [NSString stringWithFormat:
                                           @"http://www.google.com/s2/favicons?domain=%@", hostURL];
                    NSURL *googleFavicon = [NSURL URLWithString:urlString];
                    faviconData = [NSData dataWithContentsOfURL:googleFavicon];
                    faviconImage = [UIImage imageWithData:faviconData];
                }
                if (faviconData) {
                    self.faviconCache[hostURL] = faviconImage;
                    [storySubject sendNext:@"urlString"];
                }
            }];
            
        }
        replay;
    }));
}

#pragma mark - Helper Methods

- (NSString *)schemeAndHostFromURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url.scheme && url.host) {
        return [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
    }
    return nil;
}

@end
