//
//  BSAudioRecorder.h
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/8/4.
//  Copyright © 2017年 czl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioToolbox/AudioToolbox.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@class BSAudioRecorder;

@protocol BSAudioRecorderDelegate <NSObject>

- (void)recorder:(BSAudioRecorder *)recorder recordFinished:(NSString *)filePath;

@end

/**
 * 声音录制
 */
@interface BSAudioRecorder : NSObject

@property (nonatomic, strong) AVAudioRecorder       *recorder;
@property (nonatomic, strong, readonly) NSString    *fileName;              // 文件名称
@property (nonatomic, strong, readonly) NSString    *filePath;              // 文件路径

@property (nonatomic, assign) BOOL                          isPaused;
@property (nonatomic, weak)   id <BSAudioRecorderDelegate>  delegate;

- (void)startRecordWithFileName:(NSString *)fileName;
- (void)stopRecord;

- (void)pause;
- (void)resume;

@end
