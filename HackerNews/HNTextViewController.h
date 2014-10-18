//
//  HNTextViewController.h
//  HackerNews
//
//  Created by xes on 10/18/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HNTextViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSString *text;

@end
