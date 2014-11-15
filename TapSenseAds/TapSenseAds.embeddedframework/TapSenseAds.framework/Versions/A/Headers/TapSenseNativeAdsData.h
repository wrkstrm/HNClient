//
//  TapSenseNativeAdsData.h
//  Copyright (c) 2014 TapSense Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** Class to hold attributes of a native ad.
    -(void) load...into... methods are used in TapSenseNativeAdsCell protocol
    to create mappings from adData to cell layout. 
 */

@interface TapSenseNativeAdsData : NSObject

- (void) loadImageIntoImageView: (UIImageView *) imageView;
- (void) loadTitleIntoLabel: (UILabel *) label;
- (void) loadAdDescriptionIntoLabel: (UILabel *) label;
- (void) loadCallToActionIntoLabel: (UILabel *) label;
- (void) loadSponsorNameIntoLabel: (UILabel *) label;

@end
