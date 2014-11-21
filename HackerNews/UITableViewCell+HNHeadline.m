//
//  UITableViewCell+prepareForHeadline.m
//  HackerNews
//
//  Created by Cristian Monterroza on 10/24/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "UITableViewCell+HNHeadline.h"
#import <DateTools/DateTools.h>
#import "UIView+WSMUtilities.h"

@implementation UITableViewCell (HNHeadline)

- (void)prepareForHeadline:(NSDictionary *)properties path:(NSIndexPath *)path {
    //Create the number - ex: 1.
    UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.text = @(path.row + 1).stringValue;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    [label sizeToFit];
    label.tag = 1;
    self.imageView.image = nil;
    for (UIView *view in self.imageView.subviews) {
        [view removeFromSuperview];
    }
    self.imageView.image = [self imageWithColor:[UIColor clearColor] size:CGSizeMake(1.0f, 1.0f)];
    [self.imageView addSubview: label];
    label.center = CGPointMake(0.5f, 0.5f);
    if (properties) {
        //Headline
        NSMutableString *title = @"".mutableCopy;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [title appendString:properties[@"title"]];
        
        self.textLabel.text = title;
        
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
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.text = detailText;
    } else {
        self.textLabel.text = @"Fetching Story...";
        self.detailTextLabel.text = @"0 points by rismay";
    }
    [self.textLabel sizeToFit];
    [self.detailTextLabel sizeToFit];
}

- (void)setFavicon:(UIImage *)image {
    CGFloat faviconSize = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize + 1;
    UIImageView *favicon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, faviconSize, faviconSize)];
    [favicon setImage:image];
    self.accessoryView = favicon;
}

+ (CGFloat) getCellHeightForDocument:(CBLDocument *)document view:(UIView *)tableView {
    CGFloat labelWidth = CGRectGetWidth(tableView.frame) - 55;
    CGFloat titleHeight = [UITableViewCell getTitleHeight:document[@"title"] forWidth:labelWidth];
    CGFloat infoHeight = [UITableViewCell getInfoHeight:document forWidth:labelWidth];
    CGFloat final = ceil(titleHeight + infoHeight);
    return final;
}

+ (CGFloat)getTitleHeight:(NSString *)title forWidth:(CGFloat)labelWidth {
    NSMutableParagraphStyle *paragrapthStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    paragrapthStyle.alignment = NSTextAlignmentRight;
    UIFont *perferredFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    NSAttributedString *questionText = [[NSAttributedString alloc] initWithString:title
                                                                       attributes:@{NSParagraphStyleAttributeName:paragrapthStyle,
                                                                                    NSFontAttributeName:perferredFont}];
    CGSize labelConstraint = CGSizeMake(labelWidth, CGFLOAT_MAX);
    return CGRectGetHeight([questionText boundingRectWithSize:labelConstraint
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                      context:nil]) + perferredFont.pointSize * 1.1;
}

+ (CGFloat)getInfoHeight:(CBLDocument *)document forWidth:(CGFloat)labelWidth {
    NSMutableString *text = @"".mutableCopy;
    NSInteger score = [document[@"score"] integerValue];
    [text appendString:[NSString stringWithFormat:@"%li %@",
                        (long)score, (score != 1) ? @"points":@"point"]];
    [text appendString:[NSString stringWithFormat:@" by %@ ", document[@"by"]]];
    NSString *timeAgo = [[NSDate dateWithTimeIntervalSince1970:[document[@"time"]
                                                                floatValue]] shortTimeAgoSinceNow];
    [text appendString:timeAgo];
    [text appendString:@" ago | "];
    NSInteger comments = [document[@"kids"] count];
    [text appendString:[NSString stringWithFormat:@"%li %@",
                        (long)comments, (comments != 1) ? @"comments": @"comment"]];
    CGSize labelConstraint = CGSizeMake(labelWidth, CGFLOAT_MAX);
    NSMutableParagraphStyle *paragrapthStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    paragrapthStyle.alignment = NSTextAlignmentRight;
    UIFont *perferredFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    NSAttributedString *detailText = [[NSAttributedString alloc] initWithString:text
                                                                     attributes:@{NSParagraphStyleAttributeName:paragrapthStyle,
                                                                                  NSFontAttributeName:perferredFont}];
    return CGRectGetHeight([detailText boundingRectWithSize:labelConstraint
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                    context:nil]) * 2.3;
}

@end
