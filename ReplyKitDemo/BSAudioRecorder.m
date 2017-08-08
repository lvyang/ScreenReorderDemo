//
//  BSAudioRecorder.m
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/8/4.
//  Copyright © 2017年 czl. All rights reserved.
//

#import "BSAudioRecorder.h"

@implementation BSAudioRecorder

- (void)startRecordWithFileName:(NSString *)fileName
{
    _fileName = fileName;
    _filePath = [[[self _fileDirectory] stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"wav"];

    NSURL *url = [NSURL fileURLWithPath:[_filePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:[self _audioRecorderSettings] error:nil];
    _recorder.meteringEnabled = YES;
    [_recorder prepareToRecord];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [_recorder record];
}

- (void)stopRecord
{
    [self.recorder stop];
    self.recorder = nil;

    if ([self.delegate respondsToSelector:@selector(recorder:recordFinished:)]) {
        [self.delegate recorder:self recordFinished:self.filePath];
    }
}

- (void)pause
{
    [self.recorder pause];
    _isPaused = YES;
}

- (void)resume
{
    _isPaused = NO;
    [self.recorder record];
}

#pragma mark -  file path
- (NSString *)_fileDirectory
{
    NSString        *searchPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString        *recorderPath = [searchPath stringByAppendingPathComponent:@"recorder"];
    NSFileManager   *manager = [NSFileManager defaultManager];

    [manager createDirectoryAtPath:recorderPath withIntermediateDirectories:YES attributes:nil error:nil];

    return recorderPath;
}

- (NSDictionary *)_audioRecorderSettings
{
    NSDictionary *settings = @{AVSampleRateKey : [NSNumber numberWithFloat:8000.0],
                               AVFormatIDKey   : [NSNumber numberWithInt:kAudioFormatLinearPCM],
                               AVLinearPCMBitDepthKey : [NSNumber numberWithInt:16],
                               AVNumberOfChannelsKey : [NSNumber numberWithInt:1]};

    return settings;
}

@end
