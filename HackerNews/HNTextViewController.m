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
    NSString *htmlString = [NSString stringWithFormat:@"<style> body {font-family:\"Helvetica Neue\", Helvetica, Arial, \"Lucida Grande\", sans-serif; font-weight: 300; font-size:20 } </style> <body> %@ </body>", self.text];
    self.textView.attributedText = [[NSAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUnicodeStringEncoding]
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
