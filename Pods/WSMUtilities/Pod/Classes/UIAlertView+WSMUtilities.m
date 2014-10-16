//
//  UIAlertView+Blocks.m
//  UIKitCategoryAdditions
//

#import "UIAlertView+WSMUtilities.h"

static ConfirmBlock _confirmBlock;
static CancelBlock _cancelBlock;

@implementation UIAlertView (WSMUtilities)

+ (UIAlertView *)showAlertViewWithTitle:(NSString *)title
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                      otherButtonTitles:(NSArray *)otherButtons
                              onConfirm:(ConfirmBlock)confirmed
                               onCancel:(CancelBlock)cancelled {

    _cancelBlock  = [cancelled copy];
    _confirmBlock  = [confirmed copy];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:[self self]
                                          cancelButtonTitle:cancelButtonTitle
                                          otherButtonTitles:nil];
    for (NSString *buttonTitle in otherButtons) {
        [alert addButtonWithTitle:buttonTitle];
    }
    [alert show];
    return alert;
}

+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView cancelButtonIndex]) {
		_cancelBlock();
	} else {
        _confirmBlock(buttonIndex - 1); // dismiss button is button 0
    }  
}

@end
