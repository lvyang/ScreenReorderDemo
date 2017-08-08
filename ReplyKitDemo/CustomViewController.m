//
//  CustomViewController.m
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/7/24.
//  Copyright © 2017年 czl. All rights reserved.
//

#import "CustomViewController.h"
#import "BSScreenRecorder.h"
#import "BSRecorderUtil.h"

@interface CustomViewController ()

@property (nonatomic, strong) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation CustomViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"视频列表" style:UIBarButtonItemStylePlain target:self action:@selector(videoList)];
    self.navigationItem.rightBarButtonItem = right;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stop:nil];
}

- (IBAction)start:(id)sender
{
    if ([[BSScreenRecorder shareRecorder] recording]) {
        return;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(progressChanged:) userInfo:nil repeats:YES];
    [self.timer fire];

    [[BSScreenRecorder shareRecorder] start];
}
- (IBAction)stop:(id)sender
{
    [[BSScreenRecorder shareRecorder] stop];
    [self.timer invalidate];
    self.timer = nil;
    
    [self showPrompt:@"录屏成功，请在视频列表中查看"];
}

- (IBAction)pauseOrResume:(UIButton *)sender
{
    if (sender.selected) {
        [[BSScreenRecorder shareRecorder] resume];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(progressChanged:) userInfo:nil repeats:YES];
        [self.timer fire];
    } else {
        [[BSScreenRecorder shareRecorder] pause];
        [self.timer invalidate];
        self.timer = nil;
    }
    
    sender.selected = !sender.selected;
}

- (void)videoList
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoListViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)progressChanged:(id)sender
{
    self.progress.progress += 0.05;
    self.progressLabel.text = [NSString stringWithFormat:@"%.2f",self.progress.progress];
}

- (void)enterBackground:(NSNotification *)notification
{
    if ([BSScreenRecorder shareRecorder].recording) {
        [self pauseOrResume:self.pauseButton];
    }
}

@end
