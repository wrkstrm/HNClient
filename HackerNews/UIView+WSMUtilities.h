//
//  UIView+WSMUtilities.h
//  HackerNews
//
//  Created by Cristian Monterroza on 10/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (WSMUtilities)

- (UIImage *) imageWithView:(UIView *)view;

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

- (void)shimmerFor:(NSTimeInterval)timeInterval;

- (void)startShimmeringAtInterval:(NSTimeInterval)duration;

- (void)stopShimmering;

@end
