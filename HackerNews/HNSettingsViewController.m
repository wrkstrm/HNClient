//
//  HNSettingsTableViewController.m
//  HackerNews
//
//  Created by Cristian Monterroza on 11/23/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import "HNSettingsViewController.h"

@interface HNSettingsViewController ()

@end

@implementation HNSettingsViewController

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

@end
