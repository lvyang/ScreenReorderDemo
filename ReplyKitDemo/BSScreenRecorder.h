//
//  BSRecorder.h
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/7/24.
//  Copyright © 2017年 czl. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BSScreenRecorder;

@protocol BSRecorderDelegate <NSObject>

- (void)recorder:(BSScreenRecorder *)recorder recordingFinished:(NSString *)outputPath;
- (void)recorder:(BSScreenRecorder *)recorder recordingFaild:(NSError *)error;

@end

/**
 * 屏幕录制
 */
@interface BSScreenRecorder : NSObject

@property (nonatomic, assign) NSUInteger        frameRate;
@property (nonatomic, assign) BOOL              isPause;
@property (nonatomic, assign, readonly) BOOL    recording;            // 是否在正在录制

@property(nonatomic, weak) id <BSRecorderDelegate> delegate;

// 录制文件路径
@property (nonatomic, strong) NSString *fileDirectory;

+ (instancetype)shareRecorder;

- (BOOL)start;
- (void)stop;

- (void)pause;
- (void)resume;

// 获取视频列表
- (void)loadVideoListCompleted:(void (^)(NSArray *))completed;

@end
