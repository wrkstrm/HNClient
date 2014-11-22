//
//  UITableViewCell+prepareForHeadline.h
//  HackerNews
//
//  Created by Cristian Monterroza on 10/24/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNItems.h"

@interface UITableViewCell (HNHeadline)

- (void)prepareForHeadline:(NSDictionary *)properties path:(NSIndexPath *)path;

- (void)setFavicon:(UIImage *)image;

+ (CGFloat) getCellHeightForStory:(HNStory *)story view:(UIView *)tableView;

@end
