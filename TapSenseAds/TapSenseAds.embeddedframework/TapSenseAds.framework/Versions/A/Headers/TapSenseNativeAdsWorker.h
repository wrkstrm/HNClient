//
//  TapSenseNativeAdsWorker.h
//  Copyright (c) 2014 TapSense Inc. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "TSKeywordMap.h"

/**
 * A worker handles ad requests and inserts native ads into a given UITableView.
 * A cell class and UITableView must be registered to display ads correctly.
 */

@interface TapSenseNativeAdsWorker : UITableViewController

-(void) registerWithTableView: (UITableView *) tableView cellClass:(Class) cellClass;

- (id)initWithAdUnitId:(NSString *) adUnitId;

- (id)initWithAdUnitId:(NSString *) adUnitId
            keywordMap:(TSKeywordMap *) keywordMap;

@end

