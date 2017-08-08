//
//  ViewController.m
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/7/24.
//  Copyright © 2017年 czl. All rights reserved.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>

@interface ViewController ()<RPPreviewViewControllerDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [RPScreenRecorder sharedRecorder].microphoneEnabled= YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.timer invalidate];
    self.timer = nil;
}

- (IBAction)start:(id)sender
{    
    if (![[RPScreenRecorder sharedRecorder] isAvailable]) {
        NSLog(@"!!不支持支持ReplayKit录制!!");
        return;
    }
    
    [self showLoadingProgress:@"整在准备录屏!"];
    [[RPScreenRecorder sharedRecorder] startRecordingWithHandler:^(NSError * _Nullable error) {
        [self hideLoadingProgress];
        if (error) {
            return ;
        }
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(progressChanged:) userInfo:nil repeats:YES];
        [self.timer fire];
    }];
}

- (IBAction)end:(id)sender
{
    [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@",error);
            return ;
        }
        [self.timer invalidate];
        previewViewController.previewControllerDelegate = self;
        [self presentViewController:previewViewController animated:YES completion:nil];
    }];
}

- (void)progressChanged:(id)sender
{
    self.progress.progress += 0.05;
}

#pragma mark - RPPreviewViewControllerDelegate
- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    [previewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet <NSString *> *)activityTypes {
    
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:@"保存成功" message:@"已经保存到系统相册"];
        });
    }
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.CopyToPasteboard"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:@"复制成功" message:@"已经复制到粘贴板"];
        });
    }
}

@end
