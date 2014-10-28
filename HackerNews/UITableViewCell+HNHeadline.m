//
//  UITableViewCell+prepareForHeadline.m
//  HackerNews
//
//  Created by Cristian Monterroza on 10/24/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "UITableViewCell+HNHeadline.h"
#import <DateTools/DateTools.h>

@implementation UITableViewCell (HNHeadline)

- (void)prepareForHeadline:(NSDictionary *)properties icon:(UIImage *)icon path:(NSIndexPath *)path {
    //Create the number - ex: 1.
    UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.text = [NSString stringWithFormat:@"%li.", (long)path.row + 1];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [label sizeToFit];
    self.imageView.image = [self imageWithColor:[UIColor clearColor]];
    [self.imageView addSubview: label];
    label.center = CGPointMake(0.5f, 0.5f);
    if (properties) {
        //Headline
        NSMutableString *title = @"".mutableCopy;
        self.textLabel.numberOfLines = 3; //Not sure why 2 doesn't work.
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [title appendString:properties[@"title"]];

        self.textLabel.text = title;
        [self.textLabel sizeToFit];
    
        NSMutableString *detailText = @"".mutableCopy;
        NSInteger score = [properties[@"score"] integerValue];
        [detailText appendString:[NSString stringWithFormat:@"%li %@",
                                  (long)score, (score != 1) ? @"points":@"point"]];
        [detailText appendString:[NSString stringWithFormat:@" by %@ ", properties[@"by"]]];
        NSString *timeAgo = [[NSDate dateWithTimeIntervalSince1970:[properties[@"time"]
                                                                    floatValue]] shortTimeAgoSinceNow];
        [detailText appendString:timeAgo];
        [detailText appendString:@" ago | "];
        NSInteger comments = [properties[@"kids"] count];
        [detailText appendString:[NSString stringWithFormat:@"%li %@",
                                  (long)comments, (comments != 1) ? @"comments": @"comment"]];
        self.detailTextLabel.text = detailText;
    } else {
        self.textLabel.text = @"Fetching Story...";
        self.detailTextLabel.text = @"0 points by rismay";
    }
    
    //Icon
    if (![icon isEqual:[NSNull null]]) {
        UIImageView *favicon = [[UIImageView alloc] initWithImage:icon];
        [favicon setFrame:CGRectMake(0, 0, 20, 20)];
        self.accessoryView =  favicon;
    } else {
        self.accessoryView = nil;
    }
    [[self.rac_prepareForReuseSignal take:1] subscribeNext:^(id x) {
        [label removeFromSuperview];
    }];
}

- (UIImage *) imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque,  [[UIScreen mainScreen] scale]);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
