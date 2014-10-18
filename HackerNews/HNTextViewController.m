//
//  HNTextViewController.m
//  HackerNews
//
//  Created by xes on 10/18/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNTextViewController.h"

@interface HNTextViewController ()

@end

@implementation HNTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = self.hackerBeige;
    self.textView.backgroundColor = self.hackerBeige;
    self.textView.attributedText = [[NSAttributedString alloc] initWithData:[self.text dataUsingEncoding:NSUnicodeStringEncoding]
                                                                    options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType}
                                                         documentAttributes:nil
                                                                      error:nil];
}

-(UIColor *)hackerBeige {
    return SKColorMakeRGB(245.0f, 245.0f, 238.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
