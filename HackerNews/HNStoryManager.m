//
//  HNStoryManager.m
//  HackerNews
//
//  Created by Cristian Monterroza on 11/19/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNStoryManager.h"
#import "HNUser.h"
#import "HNItems.h"
#import "NSCache+WSMUtilities.h"

NSString * const HNFilterKeyUserHidden = @"HNFilterKeyUserHidden";
NSString * const HNFilterKeyComments = @"HNFilterKeyComments";
NSString * const HNFilterKeyScore = @"HNFilterKeyScore";

@interface HNStoryManager ()

@property (nonatomic, strong) AFHTTPSessionManager *httpManager;
@property (nonatomic, strong) FIRDatabaseReference *hackerAPI;
@property (nonatomic, strong) FIRDatabaseReference *topStoriesAPI;
@property (nonatomic, strong) FIRDatabaseReference *itemsAPI;

@property (nonatomic, strong) NSMutableDictionary *observationDictionary;
@property (nonatomic, strong) NSMutableSet *purgeSet;

@property (nonatomic, strong, readwrite) NSCache *faviconCache;
@property (nonatomic, strong) CBLDatabase *newsDatabase;
@property (nonatomic, strong) CBLDocument *topStoriesDocument;

@property (nonatomic, strong, readwrite) NSArray *currentTopStories;

#pragma mark Filter Arrays
@property (nonatomic, strong, readwrite) NSArray *scoreFilteredStories;
@property (nonatomic, strong, readwrite) NSArray *commentFilteredStories;

//Placeholder Imagee
@property (nonatomic, strong) UIImage *webImagePlaceholderData;

@property (nonatomic, strong) RACSubject *top100Updates;
@property (nonatomic, strong, readwrite) RACSubject *itemUpdates;

@property (nonatomic) BOOL pendingRankingUpdate;

@end

@implementation HNStoryManager

WSM_SINGLETON_WITH_NAME(sharedInstance)

#define topStoriesDocID @"topstories"
#define webPlaceHolderName @"web_black"

- (instancetype)init {
    if (!(self = [super init])) return nil;
    _currentUser = [HNUser defaultUser] ?:
    [HNUser createDefaultUserWithProperties:@{@"hiddenStories":@[],
                                              @"minimumScore":@0,
                                              @"minimumComments":@0}];
    
    _newsDatabase = [_currentUser userDatabase];
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
    
    _observationDictionary = @{}.mutableCopy;
    
    _faviconCache = NSCache.new;
    
    _httpManager = [AFHTTPSessionManager manager];
    _httpManager.operationQueue.maxConcurrentOperationCount = 1;
    _httpManager.operationQueue.qualityOfService = NSQualityOfServiceUserInitiated;

//    @"https://hacker-news.FIRDatabaseReferenceio.com/v0/"];
    _hackerAPI = [[FIRDatabase database] reference];
    _topStoriesAPI = [_hackerAPI child:@"topstories"];
    _itemsAPI = [_hackerAPI child:@"item"];
    
    [[CBLModelFactory sharedInstance] registerClass:@"HNFavicon" forDocumentType:@"HNFavicon"];
    [[CBLModelFactory sharedInstance] registerClass:@"HNStory" forDocumentType:@"story"];
    [[CBLModelFactory sharedInstance] registerClass:@"HNJob" forDocumentType:@"job"];
    [[CBLModelFactory sharedInstance] registerClass:@"HNPoll" forDocumentType:@"poll"];
    [[CBLModelFactory sharedInstance] registerClass:@"HNPollopt" forDocumentType:@"pollopt"];
    //    [[CBLModelFactory sharedInstance] registerClass:@"HNComment" forDocumentType:@"comment"];
    
    _top100Updates = [RACSubject subject];
    _itemUpdates = [RACSubject subject];
    
    self.currentTopStories = self.topStoriesWithCurrentFilters;
    
    _purgeSet = [NSMutableSet set];
    
    @weakify(self);
    [_topStoriesAPI observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        @strongify(self);
        if (!(snapshot.value == [NSNull null])) {
            NSError *error;
            [_topStoriesDocument mergeUserProperties:@{@"stories":snapshot.value} error:&error];
            WSMLog(error, @"Error updating top stories: %@", error);
            self.currentTopStories = self.topStoriesWithCurrentFilters;
            [_top100Updates sendNext:_topStoriesDocument[@"stories"]];
        }
    }];
    
    [self manageNewObservations];
    [self manageOldObservations];
    return self;
}

- (void)setSortStyle:(HNSortStyle)sortStyle {
    if (_sortStyle != sortStyle) {
        _sortStyle = sortStyle;
        self.currentTopStories = [self topStoriesWithCurrentFilters];
    }
}

- (void)manageNewObservations {
    [[self.top100Updates combinePreviousWithStart:@[] reduce:^id(NSArray *old, NSArray *new) {
        return [[new.rac_sequence filter:^BOOL(NSNumber *value) {
            return ![old containsObject:value];
        }] array];
    }] subscribeNext:^(NSArray *newStories) {
        for (NSNumber *number in newStories) {
            [self observationForItemNumber:number];
        }
    }];
}

- (void)manageOldObservations {
    [[self.top100Updates combinePreviousWithStart:@[] reduce:^id(NSArray *old, NSArray *new) {
        return [[old.rac_sequence filter:^BOOL(NSNumber *value) {
            return ![new containsObject:value];
        }] array];
    }] subscribeNext:^(NSArray *oldStories) {
        NSNull *null = [NSNull null];
        NSMutableArray *staleObservations = [[self.observationDictionary
                                              objectsForKeys:oldStories
                                              notFoundMarker:null] mutableCopy];
        [staleObservations removeObject:null];
        [self.observationDictionary removeObjectsForKeys:staleObservations];
        for (FIRDatabaseReference *base in staleObservations) {
            [base removeAllObservers];
        }
        for (NSNumber *number in oldStories) {
            [self.purgeSet addObject:number];
        }
        [self updateItemRankings];
    }];
}

- (void)updateItemRankings {
    if (!self.pendingRankingUpdate) {
        self.pendingRankingUpdate = YES;
        WSM_DISPATCH_AFTER(1.0f, {
            for (NSNumber *number in self.purgeSet) {
                [self unhideStory:number];
                NSError *error;
                [[self.newsDatabase documentWithID:number.stringValue] purgeDocument:&error];
                WSMLog(error, @"Error Purging Old Document: %@", error);
            }
            self.purgeSet = [NSMutableSet set];
            self.commentFilteredStories = nil;
            self.scoreFilteredStories = nil;
            self.currentTopStories = [self topStoriesWithCurrentFilters];
            self.pendingRankingUpdate = NO;
        });
    }
}

- (NSArray *)topStoriesWithCurrentFilters {
    NSArray *sortedArray;
    switch (self.sortStyle) {
        case kHNSortStylePoints: {
            sortedArray = [self.topStoriesDocument[@"stories"] sortedArrayUsingComparator:
                           ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                               CBLDocument *doc1 = [self documentForItemNumber:obj1];
                               CBLDocument *doc2 = [self documentForItemNumber:obj2];
                               NSInteger score1 = [doc1[@"score"] integerValue];
                               NSInteger score2 = [doc2[@"score"] integerValue];
                               WSM_COMPARATOR(score1 > score2);
                           }];
        } break;
        case kHNSortStyleComments: {
            sortedArray = [self.topStoriesDocument[@"stories"] sortedArrayUsingComparator:
                           ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                               CBLDocument *doc1 = [self documentForItemNumber:obj1];
                               CBLDocument *doc2 = [self documentForItemNumber:obj2];
                               NSInteger comments1 = [doc1[@"kids"] count];
                               NSInteger comments2 = [doc2[@"kids"] count];
                               WSM_COMPARATOR(comments1 > comments2);
                           }];
        } break;
        default: sortedArray = [self.topStoriesDocument[@"stories"] mutableCopy]; break;
    }
    return [sortedArray filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^
             BOOL(NSNumber *storyNumber, NSDictionary *bindings) {
                 return ![self.scoreFilteredStories containsObject:storyNumber] &&
                 ![self.commentFilteredStories containsObject:storyNumber] &&
                 ![self.currentUser.hiddenStories containsObject:storyNumber];
             }]];
}

- (FIRDatabaseReference *)observationForItemNumber:(NSNumber *)itemNumber {
    FIRDatabaseReference *base = self.observationDictionary[itemNumber];
    if (!base) {
        base = [self.itemsAPI child:[itemNumber stringValue]];
        @weakify(self)
        [base observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            @strongify(self)
            if (!(snapshot.value == [NSNull null])) {
                [[CBLManager sharedInstance] doAsync:^{
                    NSError *error;
                    if ([snapshot.value[@"deleted"] boolValue]) {
                        NSMutableArray *array = [self.topStoriesDocument[@"stories"] mutableCopy];
                        [array removeObject:snapshot.value[@"id"]];
                        [self.topStoriesDocument mergeUserProperties:@{@"stories":[NSArray arrayWithArray:array]}
                                                               error:&error];
                        WSMLog(error, @"Error deleting doc after FIRDatabaseReference Event: %@", error);
                        [self.purgeSet addObject:itemNumber];
                    } else  {
                        CBLDocument *doc = [self documentForItemNumber:itemNumber];
                        [doc mergeUserProperties:snapshot.value error:&error];
                        WSMLog(error, @"Error merging doc after FIRDatabaseReference Event: %@", error);
                        [(RACSubject*) self.itemUpdates sendNext:
                         RACTuplePack(itemNumber,[CBLModel modelForDocument:doc])];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateItemRankings];
                    });
                }];
            }
        }];
    }
    return base;
}

- (UIImage *)getPlaceholderAndFaviconForItemNumber:(NSNumber *)itemNumber
                                          callback:(void(^)(UIImage *favicon))completion {
    HNItem *storyModel = (HNItem *)[self modelForItemNumber:itemNumber];
    NSString *hostURL = [self schemeAndHostFromURLString:storyModel.url];
    if (!hostURL) {
        completion(nil);
        return self.faviconCache[webPlaceHolderName];
    } else {
        HNFavicon *model = [self modelForFaviconKey:hostURL];
        CBLAttachment *attachment = [model attachmentNamed:model.attachmentNames.firstObject];
        UIImage *image = [[UIImage alloc] initWithData:attachment.content];
        if (self.faviconCache[hostURL]) {
            completion(nil);
        } else if (!self.faviconCache[hostURL] && image) {
            self.faviconCache[hostURL] = image;
            completion(nil);
        } else {
            self.faviconCache[hostURL] = [UIImage imageNamed:webPlaceHolderName];
            [self getFaviconFrom:[hostURL stringByAppendingString:@"/favicon.ico"]
                      completion:^(UIImage *favicon)
             {
                 if (favicon) {
                     [self saveFavicon:favicon onDisk:model inMemory:hostURL];
                     completion(favicon);
                     return;
                 }
                 [self getFaviconFrom:[NSString stringWithFormat:
                                       @"http://www.google.com/s2/favicons?domain=%@", hostURL]
                           completion:^(UIImage *favicon)
                  {
                      if (favicon) {
                          [self saveFavicon:favicon onDisk:model inMemory:hostURL];
                          completion(favicon);
                      } else {
                          completion(nil);
                      }
                  }];
             }];
        }
    }
    return self.faviconCache[hostURL];
}

- (void)getFaviconFrom:(NSString *)hostURL completion:(void(^)(UIImage *favicon))completion {
    NSURL *faviconURL = [NSURL URLWithString:hostURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:faviconURL];
    self.httpManager.responseSerializer = [AFImageResponseSerializer serializer];
    [self.httpManager dataTaskWithRequest:request
                        completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        completion(responseObject);
    }];
}

- (void)saveFavicon:(UIImage *)image onDisk:(HNFavicon *)fModel inMemory:(NSString *)hostURL {
    self.faviconCache[hostURL] = image;
    [fModel setAttachmentNamed:@"favicon"
               withContentType:@"image/png"
                       content:UIImagePNGRepresentation(image)];
    NSError *error;
    [fModel save:&error];
    WSMLog(error, @"Error Saving Attachment: %@", error);
}

#pragma mark - User Hidden Stories

- (void)hideStory:(NSNumber *)number {
    NSArray *array = self.currentUser.hiddenStories;
    [self saveHiddenStoriesForUser:[array arrayByAddingObject:number]];
}

- (void)unhideStory:(NSNumber *)number {
    NSMutableArray *array = self.currentUser.hiddenStories.mutableCopy;
    [array removeObject:number];
    [self saveHiddenStoriesForUser:array];
}

- (void)saveHiddenStoriesForUser:(NSArray *)array {
    self.currentUser.hiddenStories = array;
    NSError *error;
    [self.currentUser save:&error];
    WSMLog(error, @"User Could Save New Hiddens Stories array: %@", error);
    self.currentTopStories = [self topStoriesWithCurrentFilters];
}

#pragma mark - Helper Methods

- (HNFavicon *)modelForFaviconKey:(NSString *)key {
    CBLDocument *doc = [self.newsDatabase documentWithID:key];
    if (!doc.properties) {
        NSError *error;
        [doc mergeUserProperties:@{@"_id":key, @"type":@"HNFavicon"} error:&error];
        WSMLog(error, @"Failed merging Favicon Document: %@",error);
    }
    return [HNFavicon modelForDocument:doc];
}

- (CBLModel *)modelForItemNumber:(NSNumber *)number {
    return [CBLModel modelForDocument:[self documentForItemNumber:number]];
}

- (CBLDocument *)documentForItemNumber:(NSNumber *)number {
    CBLDocument *doc = [self.newsDatabase documentWithID:number.stringValue];
    if (!doc.userProperties) {
        NSError *error;
        [doc mergeUserProperties:@{@"by":@"rismay",
                                   @"id":@0,
                                   @"kids":@[],
                                   @"score":@0,
                                   @"text":@"",
                                   @"time":@0,
                                   @"title":@"Fetching Story...",
                                   @"type":@"story",
                                   @"url":@""}
                           error:&error];
        WSMLog(error, @"Error Saving initial doc: %@, %@", error, doc.properties);
    }
    return doc;
}

- (UIImage *)faviconForKey:(NSString *)key {
    return self.faviconCache[key];
}

- (NSString *)schemeAndHostFromURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url.scheme && url.host) {
        return [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
    }
    return nil;
}

- (id)objectForKeyedSubscript:(id)key {
    NSArray *filteredStories;
    if ([key isEqualToString:HNFilterKeyUserHidden]) {
        filteredStories = self.userHiddenStories;
    } else if ([key isEqualToString:HNFilterKeyScore]) {
        filteredStories = self.scoreFilteredStories;
    } else if ([key isEqualToString:HNFilterKeyComments]){
        filteredStories = self.commentFilteredStories;
    } else {
        NSAssert(false, @"Only Filter keys are allowed to be subscripted");
    }
    return filteredStories;
}

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    NSError *error;
    if ([key isEqualToString:HNFilterKeyScore]) {
        self.currentUser.minimumScore = [object floatValue];
        [self.currentUser save:&error];
        NSInteger previous = self.scoreFilteredStories.count;
        self.scoreFilteredStories = [self filteredArrayForKey:HNFilterKeyScore];
        if (previous != self.scoreFilteredStories.count) {
            self.currentTopStories = [self topStoriesWithCurrentFilters];
        }
    } else if ([key isEqualToString:HNFilterKeyComments]) {
        self.currentUser.minimumComments = [object floatValue];
        [self.currentUser save:&error];
        NSInteger previous = self.commentFilteredStories.count;
        self.commentFilteredStories = [self filteredArrayForKey:HNFilterKeyComments];
        if (previous != self.commentFilteredStories.count) {
            self.currentTopStories = [self topStoriesWithCurrentFilters];
        }
    } else {
        NSAssert(false, @"Only Comment and Score keys are allowed to be subscripted");
    }
    WSMLog(error, @"Error saving new filters: %@", error);
}

- (NSArray *)userHiddenStories {
    return [self.currentUser.hiddenStories filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject,
                                                  NSDictionary *bindings) {
        return [self.topStoriesDocument[@"stories"] containsObject:evaluatedObject];
    }]];
}

- (NSArray *)scoreFilteredStories {
    return WSM_LAZY(_scoreFilteredStories, [self filteredArrayForKey:HNFilterKeyScore]);
}

- (NSArray *)commentFilteredStories {
    return WSM_LAZY(_commentFilteredStories, [self filteredArrayForKey:HNFilterKeyComments]);
}

- (NSArray *)filteredArrayForKey:(NSString *)key {
    NSArray *filteredArrayForKey;
    if ([key isEqualToString:HNFilterKeyScore]) {
        CGFloat currentMinimumScore = self.currentUser.minimumScore;
        filteredArrayForKey = [self.topStoriesDocument[@"stories"] filteredArrayUsingPredicate:
                               [NSPredicate predicateWithBlock:^BOOL(NSNumber *evaluatedObject,
                                                                     NSDictionary *bindings) {
            CBLDocument *doc = [self documentForItemNumber:evaluatedObject];
            NSInteger points = [doc[@"score"] integerValue];
            return (points < currentMinimumScore);
        }]];
        filteredArrayForKey = [filteredArrayForKey sortedArrayUsingComparator:
                               ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                                   CBLDocument *doc1 = [self documentForItemNumber:obj1];
                                   CBLDocument *doc2 = [self documentForItemNumber:obj2];
                                   NSInteger score1 = [doc1[@"score"] integerValue];
                                   NSInteger score2 = [doc2[@"score"] integerValue];
                                   WSM_COMPARATOR(score1 > score2);
                               }];
    } else if ([key isEqualToString:HNFilterKeyComments]) {
        CGFloat currentMinimumComments = self.currentUser.minimumComments;
        filteredArrayForKey = [[self.topStoriesDocument[@"stories"] filteredArrayUsingPredicate:
                                [NSPredicate predicateWithBlock:^BOOL(NSNumber *evaluatedObject,
                                                                      NSDictionary *bindings) {
            CBLDocument *doc = (CBLDocument *)[self documentForItemNumber:evaluatedObject];
            NSInteger comments = [doc[@"kids"] count];
            return (comments < currentMinimumComments);
        }]] sortedArrayUsingComparator:
                               ^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                                   CBLDocument *doc1 = [self documentForItemNumber:obj1];
                                   CBLDocument *doc2 = [self documentForItemNumber:obj2];
                                   NSInteger comments1 = [doc1[@"kids"] count];
                                   NSInteger comments2 = [doc2[@"kids"] count];
                                   WSM_COMPARATOR(comments1 > comments2);
                               }];
    } else {
        NSAssert(false, @"Only Score and Comment Filter Arrays are available.");
    }
    return filteredArrayForKey;
}

@end
