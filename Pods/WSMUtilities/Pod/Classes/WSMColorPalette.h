//
//  WSColorPalette.h
//
//  Created by Cristian A Monterroza on 9/20/12.
//  Copyright (c) 2012 wrkstrm. All rights reserved.
//

// Ensure compatability between, OSX and iOS without SpriteKit
#ifndef SKColor
    #if TARGET_OS_IPHONE
        #define SKColor UIColor
    #else
        #define SKColor NSColor
    #endif
#endif

typedef NS_ENUM(NSUInteger, WSMAgendaType) {
    kWSMAgendaTypeUncategorized = 0,
    kWSMAgendaTypeRecuperate,
    kWSMAgendaTypeWork,
    kWSMAgendaTypeSocial,
    kWSMAgendaTypeExercise,
    kWSMAgendaTypeDeadTime,
} WSAgendaType;

typedef NS_ENUM(NSUInteger, WSMColorGradient) {
    kWSMGradientUncategorized = 0,
	kWSMGradientWhite,
	kWSMGradientGreen,
	kWSMGradientBlue,
	kWSMGradientRed,
	kWSMGradientBlack,
};

@interface WSMColorPalette : NSObject

SKColor* SKColorMakeRGB(CGFloat red, CGFloat green, CGFloat blue);

+ (SKColor *)colorForAgenda:(WSMAgendaType)agendaConstant forIndex:(NSInteger)index ofCount:(NSInteger)count reversed:(BOOL) reversed;

+ (SKColor *)colorGradient:(WSMColorGradient)colorGradient forIndex:(NSInteger)index ofCount:(NSInteger)count reversed:(BOOL)reversed;

@end
