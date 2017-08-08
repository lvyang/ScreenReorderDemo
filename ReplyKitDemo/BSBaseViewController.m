//
//  BaseViewController.m
//  WuHan_GJJ
//
//  Created by chinda021 on 16/1/21.
//  Copyright © 2016年 chinda021. All rights reserved.
//

#import "BSBaseViewController.h"

@interface BSBaseViewController ()

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end



@implementation BSBaseViewController

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 加载等待view
- (void)showLoadingProgress:(NSString *)title
{
    [self showLoadingProgress:title inView:self.view];
}

- (void)showLoadingProgress:(NSString *)title inView:(UIView *)view
{
    [MBProgressHUD hideHUDForView:view animated:YES];
    _hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    
    if (title) {
        _hud.labelText = title;
    }
    
    [_hud show:YES];
}

- (void)hideLoadingProgress
{
    [_hud hide:YES];
}

- (void)showPrompt:(NSString *)title
{
    [self showPrompt:title inView:self.view];
}

- (void)showPrompt:(NSString *)title inView:(UIView *)view
{
    [MBProgressHUD hideHUDForView:view animated:YES];
    _hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    _hud.mode = MBProgressHUDModeText;
    _hud.detailsLabelText = title;
    _hud.detailsLabelFont = [UIFont systemFontOfSize:16];
    [_hud hide:YES afterDelay:2];
}

-(void)showPrompt:(NSString *)title HideDelay:(NSInteger)delay withCompletionBlock:(MBProgressHUDCompletionBlock)block
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeText;
    _hud.detailsLabelText = title;
    _hud.detailsLabelFont = [UIFont systemFontOfSize:16];
    _hud.completionBlock = block;
    [_hud hide:YES afterDelay:delay];
}

#pragma mark - UIInterfaceOrientation
// 横屏时不隐藏status bar
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return   UIInterfaceOrientationPortrait;
}

@end
