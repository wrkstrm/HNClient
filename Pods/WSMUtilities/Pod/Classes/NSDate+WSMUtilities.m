//
//  NSDate+WSMUtilities.m
//  wrkstrm_mac
//
//  Created by Cristian Monterroza on 1/18/14.
//
//

#import "NSDate+WSMUtilities.h"

@implementation NSDate (WSMUtilities)

static NSCalendar * _gregorian;

+ (void)load {
    _gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

+ (NSDate *)now:(NSCalendarUnit)components {
    return [NSDate date:[NSDate date] atResolution:components];
}

+ (NSDate *)tomorrow:(NSCalendarUnit)components {
    NSDateComponents *tomorrowComponents = NSDateComponents.new;
    [tomorrowComponents setDay:1];
    return [_gregorian dateByAddingComponents:tomorrowComponents
                                       toDate:[NSDate now:components]
                                      options:0];
}

+ (NSDate *)date:(NSDate *)date atResolution:(NSCalendarUnit)components {
    return [_gregorian dateFromComponents:[_gregorian components:components
                                                        fromDate:date]];
}

+ (NSTimeInterval)timeIntervalUntilNextMidNight {
    NSCalendarUnit resolution = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSTimeInterval midnight = [NSDate tomorrow:resolution].timeIntervalSinceReferenceDate;
    return midnight - NSDate.date.timeIntervalSinceReferenceDate;
}

+ (NSTimeInterval)timeIntervalUntilNextHour {
    NSDateComponents *nextHourComponents = NSDateComponents.new;
    [nextHourComponents setHour:1];
    NSCalendarUnit resolution = (NSCalendarUnitYear | NSCalendarUnitMonth
                                 | NSCalendarUnitDay | NSCalendarUnitHour);
    return [_gregorian dateByAddingComponents:nextHourComponents
                                       toDate:[NSDate now:resolution]
                                      options:0].timeIntervalSinceReferenceDate;
}

+ (NSTimeInterval)timeIntervalUntilNextSecond {
    NSTimeInterval integer, decimal; // You need to do this.
    return (decimal = 1 - modf(NSDate.date.timeIntervalSinceReferenceDate, &integer));
}

@end
