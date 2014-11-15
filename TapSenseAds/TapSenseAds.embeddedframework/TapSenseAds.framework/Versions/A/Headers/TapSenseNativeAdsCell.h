//
//  TapSenseNativeAdsCell.h
//  Copyright (c) 2014 TapSense Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TapSenseNativeAdsData.h"

/**
 TapSenseNativeAdsCell defines an interface for designing your own ad cell in a table view.
*/

@protocol TapSenseNativeAdsCell

/*
 If you are using the Interface Builder, make sure this matches the identifier in your nib file or storyboard.
*/
+ (NSString *)reuseIdentifier;


/*
 Design and create mappings from the given adData to your own cell layout.
 
 This method is called when an ad cell is about to be displayed. 
 
 The following methods of adData are avaliable to design your layout:
 
 - (void) loadImageIntoImageView: (UIImageView *) imageView;
 - (void) loadTitleIntoLabel: (UILabel *) label;
 - (void) loadDescriptionIntoLabel: (UILabel *) label;
 - (void) loadCallToActionIntoLabel: (UILabel *) label;
 - (void) loadSponsorNameIntoLabel: (UILabel *) label;
*/
- (void)updateWithAdData:(TapSenseNativeAdsData *)adData;

@optional
/*
 The height of the cell for the given layout. If this method is not implemented, the cell height
 will be determined by tableView:heightForRowAtIndexPath of the given UITable.
 */
+ (CGFloat) cellHeight;

@end