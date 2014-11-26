//
//  HNItem.h
//  HackerNews
//
//  Created by Cristian Monterroza on 11/21/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HNItem : CBLModel

//id
@property (nonatomic) BOOL deleted;
//type
@property (nonatomic, strong) NSString *by;
@property (nonatomic) NSTimeInterval time;
@property (nonatomic, strong) NSString *text;
@property (nonatomic) BOOL dead;
@property (nonatomic, strong) NSNumber *parent;
@property (nonatomic, strong) NSArray *kids;
@property (nonatomic, strong) NSString *url;
@property (nonatomic) NSInteger score;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *parts;

@property (nonatomic, strong) NSDate *lastAccessed;

@end

@interface HNJob : HNItem

@end

@interface HNStory : HNItem

@end

@interface HNFavicon : CBLModel

@end
