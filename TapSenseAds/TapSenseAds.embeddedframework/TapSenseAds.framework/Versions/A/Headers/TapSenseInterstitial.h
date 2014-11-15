//
//  TapSenseInterstitial.h
//  Copyright (c) 2014 TapSense Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TSKeywordMap.h"

@protocol TapSenseInterstitialDelegate;

/**
 * The TapSenseInterstitial class provides an interstitial ad.
 */

@interface TapSenseInterstitial : NSObject

/** NOTE: Make sure to set to nil when releasing TapSenseAds */
@property (nonatomic, weak) id <TapSenseInterstitialDelegate> delegate;

/**
 * Returns an instance of TapSenseInterstitial.
 *
 * @param adUnitId              The TapSense ad unit ID for this interstitial.
 *                              Ad units are created on the TapSense dashboard.
 * @param shouldAutoRequestAd   Boolean to control automatic pre-fetching. If
 *                              YES, the next ad will be pre-fetched
 *                              automatically on init, and when the previous one
 *                              is dismissed. If NO, you will need to explicitly
 *                              request an ad by calling `requestAd` before you
 *                              can show it.
 * @param keywordMap            A TSKeywordMap to supply additional targeting
 *                              information.
 */
- (id)initWithAdUnitId:(NSString *) adUnitId
   shouldAutoRequestAd:(BOOL) autoRequestAd
            keywordMap:(TSKeywordMap *) keywordMap;

/**
 * Returns an instance of TapSenseInterstitial. `shouldAutoRequestAd` is YES and
 * keywordMap is nil.
 */
- (id)initWithAdUnitId:(NSString *) adUnitId;

/**
 * Returns an instance of TapSenseInterstitial. `keywordMap` is nil.
 */
- (id)initWithAdUnitId:(NSString *) adUnitId
   shouldAutoRequestAd:(BOOL) autoRequestAd;

/**
 * Returns an instance of TapSenseInterstitial. `shouldAutoRequestAd` is YES.
 */
- (id)initWithAdUnitId:(NSString *) adUnitId
            keywordMap:(TSKeywordMap *) keywordMap;

/**
 * Show the ad from the specified view controller.
 * Returns NO instantly if the ad cannot be shown (refer to isReady for details)
 * This method also preloads the next ad regardless of the result of the display.
 * Implement TSAdDidFailToShow delegate to get error details.
 */
- (BOOL)showAdFromViewController:(UIViewController*)viewController;

/**
 * Checks if it is okay to display the ad.
 * isReady returns NO if any of the following is true:
 * a) Internet is not active        b) TapSense did not return an ad
 * c) Ad is still being downloaded  d) Preloaded ad's orientation is different from current orientation
 */
- (BOOL)isReady;

/**
 * Method to request an ad without displaying it. This is called automatically when
 * shouldAutoRequestAd is YES. You may implement the -interstitialDidLoad: and 
 * -interstitialDidFailToLoad:withError: delegate methods for the callback.
 * Returns NO instantly if the internet is down or another request is in progress.
 * This method does not automatically retry if it fails.
 */
- (BOOL)requestAd;

@end

/**
 * All delegate methods are optional.
 * Implement them only if you want more control over TapSenseAds life cycle.
 */
@protocol TapSenseInterstitialDelegate <NSObject>
@optional

/**
 * Called when the ad successfully loads its content.
 */
- (void)interstitialDidLoad:(TapSenseInterstitial*)interstitial;

/**
 * Called when the ad fails to load its content.
 */
- (void)interstitialDidFailToLoad:(TapSenseInterstitial*)interstitial
                        withError:(NSError*)error;

/**
 * Called when the ad is appearing. This might be a good time to pause your app.
 */
- (void)interstitialWillAppear:(TapSenseInterstitial*)interstitial;

/**
 * Called when the ad is disappearing. This might be a good time to resume your app.
 */
- (void)interstitialDidDisappear:(TapSenseInterstitial*)interstitial;

@end
