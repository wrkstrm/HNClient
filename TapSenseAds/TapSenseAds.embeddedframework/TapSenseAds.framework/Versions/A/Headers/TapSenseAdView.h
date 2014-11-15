//
//  TapSenseAdView.h
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSKeywordMap.h"

#define TS_BANNER_SIZE           CGSizeMake(320, 50)
#define TS_MEDIUM_RECT_SIZE      CGSizeMake(300, 250)
#define TS_LEADERBOARD_SIZE      CGSizeMake(728, 90)
#define TS_IPAD_BANNER_SIZE      CGSizeMake(768, 66)

@protocol TapSenseAdViewDelegate;

/**
 * The TapSenseAdView class provides a view that displays banner ads.
 */

@interface TapSenseAdView : UIView

/**
 * Required reference to the current root view controller.
 * This is used when TSAdView attempts to present new modal view.
 */
@property (nonatomic, weak) UIViewController *rootViewController;

/**
 * Default YES. Set to NO to allow manual refreshing by calling refreshAd
 */
@property (nonatomic) BOOL shouldAutoRefresh;

/**
 * A TSKeywordMap to supply additional targeting information.
 */
@property (nonatomic, strong) TSKeywordMap *keywordMap;

/**
 * NOTE: Make sure to set to nil before releasing the ad view
 */
@property (nonatomic, weak) id<TapSenseAdViewDelegate> delegate;

/**
 * The TapSense ad unit ID for this banner. Ad units are created on the
 * TapSense dashboard.
 */
@property (nonatomic, strong) NSString *adUnitId;

/**
 * Initializes a TSAdView and sets the ad unit ID with specified size.
 * The ad unit id here should be the same as shown on the dashboard.
 */
- (id) initWithAdUnitId:(NSString *)adUnitId;

/**
 * Sends an ad request to the ad server and loads the ad. An ad unit ID
 * must be set in order to receive a valid ad. Once loadAd is called,
 * the ad view will start refreshing if shouldAutoRefresh is true.
 */
- (void) loadAd;

/**
 * Call to manually refresh the ad.
 */
- (void) refreshAd;

@end

@protocol TapSenseAdViewDelegate <NSObject>

@optional
/**
 * Called when the ad successfully loads its content.
 */
- (void) adViewDidLoadAd:(TapSenseAdView *)view;

/**
 * Called when the ad fails to load its content.
 */
- (void) adViewDidFailToLoad:(TapSenseAdView *)view withError:(NSError *)error;

/**
 * Called when the ad is about to expand. This might be a good time to pause your app.
 */
- (void) adViewWillPresentModalView:(TapSenseAdView *)view;

/**
 * Called when the ad is about to collapse. This might be a good time to resume your app.
 */
- (void) adViewDidDismissModalView:(TapSenseAdView *)view;

@end
