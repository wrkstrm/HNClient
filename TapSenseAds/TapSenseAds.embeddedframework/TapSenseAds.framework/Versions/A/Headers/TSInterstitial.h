//
//  TSInterstitial.h
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TSAdInstance.h"

@protocol TSInterstitialDelegate;

@interface TSInterstitial : NSObject

@property (nonatomic, weak) id <TSInterstitialDelegate> delegate;
@property (nonatomic, strong) TSAdInstance *adInstance;
//Local ad unit id used to download resources with TSCacheManager
@property (nonatomic, copy) NSString *adUnitId;

- (void) requestInterstitial;
- (void) showInterstitialFromViewController: (UIViewController *) viewController;

@end

/**
 * The optional methods of this protocol allow the TSInterstitialDelegate to be
 * notified of interstitial state changes.
 */

@protocol TSInterstitialDelegate <NSObject>

- (void) interstitialDidLoad;
- (void) interstitialDidFailToLoadAdWithError:(NSError*)error;
- (void) interstitialWillAppear;
- (void) interstitialDidDisappear;

@end
