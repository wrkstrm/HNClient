//
//  UIView+WSMUtilities.m
//  HackerNews
//
//  Created by Cristian Monterroza on 10/30/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "WSMMacros.h"
#import "UIView+WSMUtilities.h"

@implementation UIView (WSMUtilities)

- (UIImage *) imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, [[UIScreen mainScreen] scale]);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)shimmerFor:(NSTimeInterval)timeInterval {
    [self startShimmeringAtInterval:timeInterval];
    WSM_DISPATCH_AFTER(timeInterval, {
        [self stopShimmering];
    });
}

- (void)startShimmeringAtInterval:(NSTimeInterval)duration {
    id light = (id)[UIColor colorWithWhite:0 alpha:0.25].CGColor;
    id dark  = (id)[UIColor blackColor].CGColor;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[dark, light, dark];
    gradient.frame = CGRectMake(-self.bounds.size.width, 0, 3*self.bounds.size.width,
                                self.bounds.size.height);
    gradient.startPoint = CGPointMake(0.0, 0.5);
    gradient.endPoint   = CGPointMake(1.0, 0.525); // slightly slanted forward
    gradient.locations  = @[@0.4, @0.5, @0.6];
    self.layer.mask = gradient;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"locations"];
    animation.fromValue = @[@0.0, @0.1, @0.2];
    animation.toValue   = @[@0.8, @0.9, @1.0];
    
    animation.duration = 1.0;
    animation.repeatCount = HUGE_VALF;
    [gradient addAnimation:animation forKey:@"shimmer"];
}

- (void)stopShimmering {
    self.layer.mask = nil;
}

@end
