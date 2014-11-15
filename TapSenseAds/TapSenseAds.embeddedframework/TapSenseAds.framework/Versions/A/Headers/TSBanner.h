//
//  TSBanner.h
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TSAdInstance.h"

@protocol TSBannerDelegate;

@interface TSBanner : NSObject

@property (nonatomic, weak) id <TSBannerDelegate> delegate;
@property (nonatomic, strong) TSAdInstance *adInstance;
@property (nonatomic, strong) UIViewController *rootViewController;

- (void) requestBannerWithSize:(CGSize)size;

@end

/**
 * The optional methods of this protocol allow the TSBannerDelegate to be
 * notified of banner state changes.
 */

@protocol TSBannerDelegate <NSObject>

- (void) bannerDidLoadAdView:(UIView *)view;
- (void) bannerDidFailToLoadAdWithError:(NSError*)error;
- (void) bannerWillShowModal;
- (void) bannerDidDismissModal;

@end
