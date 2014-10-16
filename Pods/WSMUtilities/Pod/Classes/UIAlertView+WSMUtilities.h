//
//  UIAlertView+Blocks.h
//  UIKitCategoryAdditions
//

typedef void (^ConfirmBlock)(NSInteger buttonIndex);
typedef void (^CancelBlock)();

@interface UIAlertView (WSMUtilities) <UIAlertViewDelegate>

+ (UIAlertView *)showAlertViewWithTitle:(NSString *)title
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                      otherButtonTitles:(NSArray *)otherButtons
                              onConfirm:(ConfirmBlock)dismissed
                               onCancel:(CancelBlock)cancelled;

@end
