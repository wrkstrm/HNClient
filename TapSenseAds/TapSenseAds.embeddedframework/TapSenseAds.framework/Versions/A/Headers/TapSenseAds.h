//
//  TapSenseAds.h
//  Copyright (c) 2014 TapSense Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * The TapSense Ads class provides static methods to set global settings for the SDK
 */

@interface TapSenseAds : NSObject

/**
 * Sets TapSense Ads SDK to be in test mode.
 * Remember to remove this before submitting to Play Store.
 */
+ (void) setTestMode;

/**
 * Returns Boolean saying if TapSense Ads SDK is in test mode
 */
+ (BOOL) getTestMode;

/**
 * Turn on debug logging
 */
+ (void) setShowDebugLog;

/**
 * Check the SDK verion of the TapSense Ads SDK
 */
+ (NSString *) getSDKVersion;

/**
 * Clears cached items
 */
+ (void) clearCache;

/**
 * Send tracking link for the given ad unit id
 */
+ (void) trackForAdUnitId:(NSString *) adUnitId;

@end
