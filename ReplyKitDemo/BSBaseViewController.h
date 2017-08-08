//
//  BaseViewController.h
//  WuHan_GJJ
//
//  Created by chinda021 on 16/1/21.
//  Copyright © 2016年 chinda021. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface BSBaseViewController : UIViewController

@property (nonatomic, strong) MBProgressHUD *hud;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

- (void)showLoadingProgress:(NSString *)title;
- (void)showLoadingProgress:(NSString *)title inView:(UIView *)view;
- (void)showPrompt:(NSString *)title HideDelay:(NSInteger)delay withCompletionBlock:(MBProgressHUDCompletionBlock)block;
- (void)hideLoadingProgress;
- (void)showPrompt:(NSString *)title;
- (void)showPrompt:(NSString *)title inView:(UIView *)view;

@end
