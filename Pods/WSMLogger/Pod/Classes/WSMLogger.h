/**
 *
 * WSMLogger.h
 *
 * Created by Cristian A Monterroza on 6/20/13 for wrkstrm related projects.
 *
 * The project page has a decent amount of documentation if you have any questions:
 * https://github.com/rismay/WSMLogger
 *
 * The purpose of this class is to provide a single touchpoint for the LumberJack beginners.
 * Lumberjack is an amazingly versitle logging solution, but it can be intimidating to customize.
 * WSMLogger includes these simplifications:
 *
 * It has Bundleed two loggers into a class heiarchy: DDTTYLogger and ContextFilterLogFormatter
 * It has made multiple logging format styles available directly through the WSMLogger.
 *
 * Why WSMLogger?
 * the traditional NSLog() function directs it's output to two places:
 *
 * - Apple System Log (so it shows up in Console.app)
 * - StdErr (if stderr is a TTY, so log statements show up in Xcode console)
 *
 * WSMLogger is primarily interested in making the Xcode console AWESOME and easy to customize.
 * The standard WSMLogger/DDLog setup is geared so that you can start logging with very little setup.
 *
 * Step 1: Add "#import WSMLogger.h" to your .pch file
 * Step 2: There is no Step 2!
 *
 * As DDLog is included in many frameworks, WSMLogger is compatible with the the standard DDLog.
 **/

#import <libkern/OSAtomic.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#if TARGET_OS_IPHONE
    #import <UIKit/UIColor.h>
#else
    #import <AppKit/NSColor.h>
#endif


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Quickstart Macro Defines
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * You can turn off the QuickStart/Passive Loading by simply switching QUICKSTART to "NO".
 * Make sure to follow the below steps to alleviate any errors :
 
 * These macros provide drag and drop logging functionality by including WSMLogger in your *-Prefix.pch file.
 * Your projects *.pch file #imports any macros or frameworks inside it to every class included in your target.
 * These macros will replace your NSLog calls with a method that assures a sharedInstance is loaded before logging.
 *
 * This might seem inefficient, but DDLog is actually 5x to 6x faster than NSLog!
 *
 * Keep in mind the [AppDelegate application:didFinishLaunchingWithOptions:] may NOT be your apps first touchpoint!
 * For example: With storyboards, the RootViewController heiarchy is inialized prior to calling the AppDelegate.
 * If you wait until didFinishLaunching but implement a RootViewController that contains logging, those logs will fail.
 *
 *
 ////////////////////////////////////////////\ STEP 0: Load /\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 *
 * Implement the +[AppDelegate load] method and add the sharedInstance to DDLog.
 *
 * The most simple implementation would be
 *
 * + (void) load {
 *    WSMLogger *logger = [WSMLogger sharedInstance];
 *    [DDLog addLogger: sLogger];
 * }
 *
 ////////////////////////////////////////////\ STEP 1: Call /\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 *
 * Remove all NSLog calls with DDLog calls that you want to custom format.
 * Remove all WSMLog* macros as the project will no longer build.
 *
 *
 ////////////////////////////////////////////\ STEP 2: Customize /\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 *
 * Have fun! Learn how to customize logging styles and add color to your console!
 * For example, add color to your logs by going to:
 * AppTarget -> EditScheme -> Arguments -> EnviornmentVariables -> "XcodeColors" YES
 *
 */


#define QUICK_START NO

#if QUICK_START

#define NSLog(__FORMAT__, ...) WSMLogVerbose(__FORMAT__, ##__VA_ARGS__)

#define WSMLog(boolean, __FORMAT__, ...) do { if (boolean) WSMLogVerbose(__FORMAT__, ##__VA_ARGS__); } while (0)

//Level 0 - LOG_LEVEL_ERROR: Something really bad happened!
#define WSMLogError( __FORMAT__, ...)    do { [WSMLogger passiveLoad]; DDLogError( __FORMAT__, ##__VA_ARGS__); } while (0)
//Level 1 - LOG_LEVEL_WARN:
#define WSMLogWarn( __FORMAT__, ...)     do { [WSMLogger passiveLoad]; DDLogWarn( __FORMAT__, ##__VA_ARGS__); } while (0)
//Level 2 - LOG_LEVEL_INFO:
#define WSMLogInfo( __FORMAT__, ...)     do { [WSMLogger passiveLoad]; DDLogInfo( __FORMAT__, ##__VA_ARGS__); } while (0)
//Level 3 - LOG_LEVEL_VERBOSE: Fine grained implementation details.
#define WSMLogVerbose( __FORMAT__, ...)  do { [WSMLogger passiveLoad]; DDLogVerbose( __FORMAT__, ##__VA_ARGS__); } while (0)

#else

#define NSLog(__FORMAT__, ...) do { DDLogVerbose(__FORMAT__, ##__VA_ARGS__); } while (0)

#define WSMLog(boolean, __FORMAT__, ...) do { if (boolean) DDLogVerbose(__FORMAT__, ##__VA_ARGS__); } while (0)

#endif




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Global LogLevel Define
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * To set ddLogLevels by file simply change GLOBAL_LOG_LEVEL to NO.
 *
 * Logging is controlled per file by the ddLogLevel variable.
 * However, if you include WSMLogger in the .pch your entire project will log at the sameLevel.
 *
 * For simplicity, the default implementation will:
 *      1. During development (DEBUG = YES), show all logs (0, 1, 2, 3).
 *
 *      2. During Release (DEBUG = NO), show only warnings and errors (0, 1).
 *
 */

#define GLOBAL_LOG_LEVEL YES
#ifdef GLOBAL_LOG_LEVEL

#ifdef DEBUG
static const NSInteger ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const NSInteger ddLogLevel = LOG_LEVEL_WARN;
#endif

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - WSMLogFormatter: Style Switching Formatter
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * A log formatter can be added to any logger to format and/or filter its output.
 * You can learn more about log formatters here:
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomFormatters
 *
 * This base custom formatter was inspired by DDLogs QueueFormatter.
 * The original implementation provided a log containing the dispatch_queue label instead of the mach_thread_id.
 *
 * A typical NSLog (or DDTTYLogger) prints detailed info as [<process_id>:<thread_id>].
 * For example:
 *
 * 2011-10-17 20:21:45.435 AppName[19928:5207] Your log message here
 *
 * Where:
 * - 19928 = process id
 * -  5207 = thread id (mach_thread_id printed in hex)
 *
 * When using grand central dispatch (GCD), this information is less useful.
 * This is because a single serial dispatch queue may be run on any thread from an internally managed thread pool.
 * For example:
 *
 * 2011-10-17 20:32:31.111 AppName[19954:4d07] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.112 AppName[19954:5207] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.113 AppName[19954:2c55] Message from my_serial_dispatch_queue
 *
 * This formatter allows you to replace the standard [box:info] with the dispatch_queue name.
 * For example:
 *
 * 2011-10-17 20:32:31.111 AppName[img-scaling] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.112 AppName[img-scaling] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.113 AppName[img-scaling] Message from my_serial_dispatch_queue
 *
 * If the dispatch_queue doesn't have a set name, then it falls back to the thread name.
 * If the current thread doesn't have a set name, then it falls back to the mach_thread_id in hex (like normal).
 *
 * Note: If manually creating your own background threads (via NSThread/alloc/init or NSThread/detachNeThread),
 * you can use [[NSThread currentThread] setName:(NSString *)].
 **/

extern NSString * const kWSMLogFormatKeyQueue;
extern NSString * const kWSMLogFormatKeyFile;
extern NSString * const kWSMLogFormatKeyFunction;

typedef NS_ENUM(NSInteger, WSMLogFormatStyle) {
    kWSMLogFormatStyleNSLog,
    kWSMLogFormatStyleDefault,
    kWSMLogFormatStyleCBL,
    kWSMLogFormatStyleQueue
};

@interface WSMLogFormatter : NSObject <DDLogFormatter> {
@protected
    int32_t atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter; // Use [self stringFromDate]
    NSString *dateFormatString;
}


@property (nonatomic) WSMLogFormatStyle formatStyle;


/**
 * Standard init method.
 * Configure using properties as desired.
 **/

- (id)init;


/**
 * This dictionary holds the length of each attribute and style.
 * By default every call to it returns nil (or 0).
 * WSMLogFormatter interprets this result as an unlimited attribute.
 *
 *
 * The minQueueLength restricts the minimum size of the [detail box].
 * If the minQueueLength is set to 0, there is no restriction.
 *
 * For example, say a dispatch_queue has a label of "diskIO":
 *
 * If the minQueueLength is 0: [diskIO]
 * If the minQueueLength is 6: [diskIO]
 * If the minQueueLength is 7: [diskIO ]
 * If the minQueueLength is 8: [diskIO  ]
 *
 * The default minQueueLength is 0 (no minimum, so [detail box] won't be padded).
 *
 * If you want every [detail box] to have the exact same width,
 * set both minQueueLength and maxQueueLength to the same value.
 *
 *
 * The maxQueueLength restricts the number of characters that will be inside the [detail box].
 * If the maxQueueLength is 0, there is no restriction.
 *
 * For example, say a dispatch_queue has a label of "diskIO":
 *
 * If the maxQueueLength is 0: [diskIO]
 * If the maxQueueLength is 4: [disk]
 * If the maxQueueLength is 5: [diskI]
 * If the maxQueueLength is 8: [diskIO]
 *
 * The default maxQueueLength is 0 (no maximum, so [detail box] won't be truncated).
 *
 * If you want every [detail box] to have the exact same width,
 * set both minQueueLength and maxQueueLength to the same value.
 **/

@property (nonatomic, strong) NSMutableDictionary *styleAtrributeLengthDictionary;

/**
 * Sometimes queue labels have long names like "com.apple.main-queue",
 * but you'd prefer something shorter like simply "main".
 *
 * This method allows you to set such preferred replacements.
 * The above example is set by default.
 *
 * To remove/undo a previous replacement, invoke this method with nil for the 'shortLabel' parameter.
 **/
- (NSString *)replacementStringForQueueLabel:(NSString *)longLabel;
- (void)setReplacementString:(NSString *)shortLabel forQueueLabel:(NSString *)longLabel;

/**
 * This method provides shortened or padded thread labels for a given logMessage.
 */
- (NSString *)queueThreadLabelForLogMessage:(DDLogMessage *)logMessage;

/**
 * NSDate formatters are not threadsafe and super expensive to create.
 *
 * This method handles multiple NSDateFormatters across various threads.
 *
 */
- (NSString *)stringFromDate:(NSDate *)date;


/**
 * This method allows for adding of contraints to the current style.
 * It takes a key and a array of length 2 containing the min and max value for that attribute.
 */

- (void)restrictKey:(NSString *)key valueArray:(NSArray *)values;

- (void)setDictionaryForStyle:(NSMutableDictionary *)styleDictionary;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - WSMLogger: The Single touchpoint for the class.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef NS_ENUM(NSInteger, WSMLogContextStyle) {
    kWSMLogContextStyleNone,
    kWSMLogContextStyleBlack,
    kWSMLogContextStyleWhite
};

@interface WSMLogger : DDAbstractLogger <DDLogger> {
    NSCalendar *calendar;
    NSUInteger calendarUnitFlags;
    
    NSString *appName;
    char *app;
    size_t appLen;
    
    NSString *processID;
    char *pid;
    size_t pidLen;
    
    BOOL colorsEnabled;
    NSMutableArray *colorProfilesArray;
    NSMutableDictionary *colorProfilesDict;
}

+ (WSMLogger *)sharedInstance;

+ (void)passiveLoad;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Context Additions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@property (nonatomic) WSMLogContextStyle contextStyle;
@property (nonatomic) WSMLogFormatStyle formatStyle;
//Private methods & properties
@property (nonatomic, strong) NSMutableSet *whiteList, *blackList;

- (NSArray *)currentList;
- (void)addToList:(NSInteger)loggingContext;
- (void)removeFromList:(NSInteger)loggingContext;
- (BOOL)isOnList:(NSInteger)loggingContext;
- (BOOL)shouldLog:(NSInteger)loggingContext;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Formatter Literal Additions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)setObject:(id)obj forKeyedSubscript:(id)key;

- (id)objectForKeyedSubscript:(id)key;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Color Additions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* Inherited from the DDLogger protocol:
 *
 * Formatters may optionally be added to any logger.
 *
 * If no formatter is set, the logger simply logs the message as it is given in logMessage,
 * or it may use its own built in formatting style.
 *
 * More information about formatters can be found here:
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomFormatters
 *
 * The actual implementation of these methods is inherited from DDAbstractLogger.
 
 - (id <DDLogFormatter>)logFormatter;
 - (void)setLogFormatter:(id <DDLogFormatter>)formatter;
 
 */

/**
 * Want to use different colors for different log levels?
 * Enable this property.
 *
 * If you run the application via the Terminal (not Xcode),
 * the logger will map colors to xterm-256color or xterm-color (if available).
 *
 * Xcode does NOT natively support colors in the Xcode debugging console.
 * You'll need to install the XcodeColors plugin to see colors in the Xcode console.
 * https://github.com/robbiehanson/XcodeColors
 *
 * The default value if NO.
 **/
@property (readwrite, assign) BOOL colorsEnabled;

/**
 * The default color set (foregroundColor, backgroundColor) is:
 *
 * - LOG_FLAG_ERROR = (red, nil)
 * - LOG_FLAG_WARN  = (orange, nil)
 *
 * You can customize the colors however you see fit.
 * Please note that you are passing a flag, NOT a level.
 *
 * GOOD : [ttyLogger setForegroundColor:pink backgroundColor:nil forFlag:LOG_FLAG_INFO];  // <- Good :)
 *  BAD : [ttyLogger setForegroundColor:pink backgroundColor:nil forFlag:LOG_LEVEL_INFO]; // <- BAD! :(
 *
 * LOG_FLAG_INFO  = 0...00100
 * LOG_LEVEL_INFO = 0...00111 <- Would match LOG_FLAG_INFO and LOG_FLAG_WARN and LOG_FLAG_ERROR
 *
 * If you run the application within Xcode, then the XcodeColors plugin is required.
 *
 * If you run the application from a shell, then WSTTYLogger will automatically map the given color to
 * the closest available color. (xterm-256color or xterm-color which have 256 and 16 supported colors respectively.)
 *
 * This method invokes setForegroundColor:backgroundColor:forFlag:context: and passes the default context (0).
 **/
#if TARGET_OS_IPHONE
- (void)setForegroundColor:(UIColor *)txtColor backgroundColor:(UIColor *)bgColor forFlag:(NSInteger)mask;
#else
- (void)setForegroundColor:(NSColor *)txtColor backgroundColor:(NSColor *)bgColor forFlag:(NSInteger)mask;
#endif

/**
 * Just like setForegroundColor:backgroundColor:flag, but allows you to specify a particular logging context.
 *
 * A logging context is often used to identify log messages coming from a 3rd party framework,
 * although logging context's can be used for many different functions.
 *
 * Logging context's are explained in further detail here:
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomContext
 **/

#if TARGET_OS_IPHONE
- (void)setForegroundColor:(UIColor *)txtColor backgroundColor:(UIColor *)bgColor forFlag:(NSInteger)mask context:(NSInteger)ctxt;
#else
- (void)setForegroundColor:(NSColor *)txtColor backgroundColor:(NSColor *)bgColor forFlag:(NSInteger)mask context:(NSInteger)ctxt;
#endif

/**
 * Similar to the methods above, but allows you to map DDLogMessage->tag to a particular color profile.
 * For example, you could do something like this:
 *
 * static NSString *const PurpleTag = @"PurpleTag";
 *
 * #define DDLogPurple(frmt, ...) LOG_OBJC_TAG_MACRO(NO, 0, 0, 0, PurpleTag, frmt, ##__VA_ARGS__)
 *
 * And then in your applicationDidFinishLaunching, or wherever you configure Lumberjack:
 *
 * #if TARGET_OS_IPHONE
 *   UIColor *purple = [UIColor colorWithRed:(64/255.0) green:(0/255.0) blue:(128/255.0) alpha:1.0];
 * #else
 *   NSColor *purple = [NSColor colorWithCalibratedRed:(64/255.0) green:(0/255.0) blue:(128/255.0) alpha:1.0];
 *
 * [[WSTTYLogger sharedInstance] setForegroundColor:purple backgroundColor:nil forTag:PurpleTag];
 * [DDLog addLogger:[WSTTYLogger sharedInstance]];
 *
 * This would essentially give you a straight NSLog replacement that prints in purple:
 *
 * DDLogPurple(@"I'm a purple log message!");
 **/

#if TARGET_OS_IPHONE
- (void)setForegroundColor:(UIColor *)txtColor backgroundColor:(UIColor *)bgColor forTag:(id <NSCopying>)tag;
#else
- (void)setForegroundColor:(NSColor *)txtColor backgroundColor:(NSColor *)bgColor forTag:(id <NSCopying>)tag;
#endif

/**
 * Clearing color profiles.
 **/

- (void)clearColorsForFlag:(NSInteger)mask;
- (void)clearColorsForFlag:(NSInteger)mask context:(NSInteger)context;
- (void)clearColorsForTag:(id <NSCopying>)tag;
- (void)clearColorsForAllFlags;
- (void)clearColorsForAllTags;
- (void)clearAllColors;

@end

