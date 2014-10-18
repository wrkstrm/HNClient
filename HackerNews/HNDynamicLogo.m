//
//  HNDynamicLogo.m
//  HackerNews
//
//  Created by xes on 10/17/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNDynamicLogo.h"

@implementation HNDynamicLogo

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    [self createShadowEffect];
}

- (void)createShadowEffect {
    self.layer.shadowColor = SKColor.blackColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.layer.shadowOpacity = 1.0f;
    self.layer.shadowRadius = 0.0f;
    
    UIInterpolatingMotionEffect *horizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset.width"
                                                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontal.minimumRelativeValue = @-12;
    horizontal.maximumRelativeValue = @12;
    
    UIInterpolatingMotionEffect *vertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset.height"
                                                                                            type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    vertical.minimumRelativeValue = @-12;
    vertical.maximumRelativeValue = @14;
    
    [self addMotionEffect:horizontal];
    [self addMotionEffect:vertical];
}

-(UIColor *)hackerOrange {
    return SKColorMakeRGB(255.0f, 102.0f, 0.0f);
}

@end
