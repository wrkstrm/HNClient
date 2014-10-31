//
//  WSMMacros.h
//  wrkstrm_mac
//
//  Created by Cristian Monterroza on 12/11/13.
//
//

#ifdef __OBJC__

/**
 Simply returns the number of seconds in a day
 */
#define WSM_SECONDS_PER_DAY 86400

/**
 Creates a basic singleton.
 */

#define WSM_SINGLETON_WITH_NAME(sharedInstanceName)  \
+ (instancetype)sharedInstanceName { \
    static id sInstance; \
    static dispatch_once_t onceToken; \
        dispatch_once(&onceToken, ^{ \
        sInstance = self.new; \
    }); \
    return sInstance; \
}

/**
 Wrapper around the DISPATCH_AFTER marcro.
 */

#define WSM_DISPATCH_AFTER(time, block) \
do { \
    NSTimeInterval delayInSeconds = time; \
    dispatch_time_t popTime = \
        dispatch_time(DISPATCH_TIME_NOW, \
            (int64_t) (delayInSeconds * NSEC_PER_SEC)); \
        dispatch_after(popTime, dispatch_get_main_queue(), \
            ^(void) block ); \
} while (0)

/**
 Awesomeness. Lazy instantiation as a function.
 Available in Ruby as ||= operator.
 I have *not* checked the compiled code to check for efficiency.
 */

#define WSM_LAZY(variable, assignment) (variable = variable ?: assignment)

/**
 Standard increasing order comparitor.
 */

#define WSM_COMPARATOR(boolean) \
do { \
    if (boolean) { \
        return NSOrderedAscending; \
    } else { \
        return NSOrderedDescending; \
    } \
    return NSOrderedSame;\
} while (0)

#endif
