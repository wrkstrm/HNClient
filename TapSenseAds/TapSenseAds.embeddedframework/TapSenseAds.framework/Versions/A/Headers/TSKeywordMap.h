//
//  TSKeywordMap.h
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


typedef enum {
    kTSGenderUnknown = 1,
    kTSGenderMale = 2,
    kTSGenderFemale = 3
} TSGender;

@interface TSKeywordMap : NSObject

@property (nonatomic) TSGender gender;

@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong) NSDate *birthday;

- (void)setBirthdayWithMonth:(NSInteger)month
                         day:(NSInteger)day
                        year:(NSInteger)year;

- (void)setValue:(NSString *)value forKey:(NSString *)key;

@end
