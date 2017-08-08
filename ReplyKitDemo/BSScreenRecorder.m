//
//  BSRecorder.m
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/7/24.
//  Copyright © 2017年 czl. All rights reserved.
//

#import "BSScreenRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "BSAudioRecorder.h"
#import "BSRecorderUtil.h"

@interface BSScreenRecorder () <BSAudioRecorderDelegate, AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAssetWriter                         *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput                    *videoWriteInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor  *adaptor;
@property (nonatomic, strong) BSAudioRecorder                       *audioRecorder;

@property (nonatomic, assign) CGContextRef  context;
@property (nonatomic, strong) CALayer       *captureLayer;
@property (nonatomic, strong) NSDate        *startDate;     // 录制开始时间
@property (nonatomic, assign) float         spaceTime;      // 单位：秒

@property (nonatomic, assign) BOOL  writing;                // 是否在将帧写入文件
@property (nonatomic, assign) BOOL  shouldResume;

@property (nonatomic, strong) NSTimer                       *timer;
@property (nonatomic, assign) UIBackgroundTaskIdentifier    backgroudTaskId;

@end

@implementation BSScreenRecorder

- (void)dealloc
{
    [self _cleanup];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }

    return self;
}

+ (instancetype)shareRecorder
{
    static BSScreenRecorder *recorder = nil;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^{
        recorder = [[self alloc] init];
        recorder.frameRate = 10;
        recorder.audioRecorder = [[BSAudioRecorder alloc] init];
        recorder.audioRecorder.delegate = recorder;
        recorder.audioRecorder.recorder.delegate = recorder;
    });

    return recorder;
}

- (BOOL)start
{
    if (self.recording) {
        return NO;
    }

    BOOL success = [self _setupWriter];

    if (success) {
        self.startDate = [NSDate date];
        self.spaceTime = 0;
        _recording = YES;
        _writing = NO;

        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / self.frameRate target:self selector:@selector(_drawFrame) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self.timer fire];

        [self.audioRecorder startRecordWithFileName:@"audio"];
    }

    return success;
}

- (void)stop
{
    _isPause = NO;
    _recording = NO;

    [_timer invalidate];
    _timer = nil;

    __weak typeof(self) weakSelf = self;

    [_videoWriteInput markAsFinished];
    [_videoWriter finishWritingWithCompletionHandler:^{
        [weakSelf.audioRecorder stopRecord];
        [weakSelf _cleanup];
    }];
}

- (void)pause
{
    @synchronized(self) {
        if (_recording) {
            _isPause = YES;
            _recording = NO;

            [self.audioRecorder pause];
        }
    }
}

- (void)resume
{
    @synchronized(self) {
        _recording = YES;
        _isPause = NO;

        [self.audioRecorder resume];
    }
}

- (void)loadVideoListCompleted:(void (^)(NSArray *))completed
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *result = [NSMutableArray array];
        NSDirectoryEnumerator *enumator = [[NSFileManager defaultManager] enumeratorAtPath:self.fileDirectory];
        NSString *file = nil;

        while (file = [enumator nextObject]) {
            if (![file.pathExtension isEqualToString:@"mp4"]) {
                continue;
            }

            NSString *fileName = [file stringByDeletingPathExtension];

            if ([fileName rangeOfString:@"_temp"].location != NSNotFound) {
                continue;
            }

            [result addObject:[self.fileDirectory stringByAppendingPathComponent:file]];
        }

        completed(result);
    });
}

#pragma mark - getter
- (NSString *)fileDirectory
{
    if (!_fileDirectory) {
        _fileDirectory = [self _defaultFileDirectory];
    }

    return _fileDirectory;
}

#pragma mark - private
- (BOOL)_setupWriter
{
    NSString *filePath = [self _generateFilePath];

    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];

        if (!success) {
            NSLog(@"Could not delete old recording file at path: %@", filePath);
            return NO;
        }
    }

    CGSize  screenSize = [UIScreen mainScreen].bounds.size;
    float   scale = [UIScreen mainScreen].scale;
    CGSize  size = CGSizeMake(screenSize.width * scale, screenSize.height * scale);

    // setup writer
    {
        NSError *error = nil;
        NSURL   *fileUrl = [NSURL fileURLWithPath:filePath];
        self.videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeQuickTimeMovie error:&error];
    }

    // setup writer input
    {
        NSDictionary    *compression = @{AVVideoAverageBitRateKey : @(size.width * size.height)};
        NSDictionary    *settings = @{AVVideoCodecKey : AVVideoCodecH264,
                                      AVVideoWidthKey : @(size.width),
                                      AVVideoHeightKey: @(size.height),
                                      AVVideoCompressionPropertiesKey : compression};
        self.videoWriteInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
        self.videoWriteInput.expectsMediaDataInRealTime = YES;
    }

    // setup writer adaptor
    {
        NSDictionary *attribute = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                    (NSString *)kCVPixelBufferWidthKey : @(size.width),
                                    (NSString *)kCVPixelBufferHeightKey : @(size.height),
                                    (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES};
        self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriteInput sourcePixelBufferAttributes:attribute];
    }

    // create context
    {
        if (self.context == NULL) {
            UIGraphicsBeginImageContextWithOptions([[UIApplication sharedApplication].delegate window].bounds.size, YES, 0);
            self.context = UIGraphicsGetCurrentContext();
        }

        if (self.context == NULL) {
            NSLog(@"Context not created!");
            return NO;
        }
    }

    // add input
    [self.videoWriter addInput:self.videoWriteInput];
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];

    return YES;
}

- (void)_drawFrame
{
    if (self.isPause) {
        _spaceTime = _spaceTime + 1.0 / self.frameRate;
        return;
    }

    if (!_writing) {
        [self performSelectorInBackground:@selector(_getFrame) withObject:nil];
    }
}

- (void)_getFrame
{
    if (!_writing) {
        _writing = YES;

        size_t  width = CGBitmapContextGetWidth(_context);
        size_t  height = CGBitmapContextGetHeight(_context);

        @try {
            CGContextClearRect(_context, CGRectMake(0, 0, width, height));

            [[UIApplication sharedApplication].delegate.window.layer renderInContext:_context];
            [UIApplication sharedApplication].delegate.window.layer.contents = nil;

            CGImageRef image = CGBitmapContextCreateImage(_context);

            if (_recording) {
                float millisElapsed = [[NSDate date] timeIntervalSinceDate:_startDate] * 1000 - _spaceTime * 1000;
                [self _writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000) addImage:image];
            }

            CGImageRelease(image);
        } @catch(NSException *exception) {}

        _writing = NO;
    }
}

- (void)_writeVideoFrameAtTime:(CMTime)time addImage:(CGImageRef)image
{
    if (![_videoWriteInput isReadyForMoreMediaData]) {
        return;
    }

    @synchronized(self) {
        CVPixelBufferRef    pixelBuffer = NULL;
        CGImageRef          cgImage = CGImageCreateCopy(image);
        CFDataRef           imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
        int                 status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _adaptor.pixelBufferPool, &pixelBuffer);

        if (status != kCVReturnSuccess) {
            NSLog(@"Error creating pixel buffer:  status=%d", status);
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        UInt8 *destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
        CFDataGetBytes(imageData, CFRangeMake(0, CFDataGetLength(imageData)), destPixels);

        if (status == kCVReturnSuccess) {
            BOOL success = [_adaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];

            if (!success) {
                NSLog(@"Warning: Unable to write buffer to video");
            }
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
        CFRelease(imageData);
        CGImageRelease(cgImage);
    }
}

#pragma mark -  clean up
- (void)_cleanup
{
    _adaptor = nil;
    _videoWriteInput = nil;
    _videoWriter = nil;
    _startDate = nil;
}

#pragma mark -  file path
- (NSString *)_defaultFileDirectory
{
    NSString        *searchPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString        *recorderPath = [searchPath stringByAppendingPathComponent:@"recorder"];
    NSFileManager   *manager = [NSFileManager defaultManager];

    [manager createDirectoryAtPath:recorderPath withIntermediateDirectories:YES attributes:nil error:nil];

    return recorderPath;
}

- (NSString *)_generateFilePath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy年MM月dd日_HH:mm:ss";
    NSString *fileName = [formatter stringFromDate:[NSDate date]];
    fileName = [fileName stringByAppendingString:@"_temp.mp4"];
    
    return [self.fileDirectory stringByAppendingPathComponent:fileName];
}

#pragma mark - BSAudioRecorderDelegate
- (void)recorder:(BSAudioRecorder *)recorder recordFinished:(NSString *)filePath
{
    if ((_videoWriter.status == AVContentKeyRequestStatusFailed) || (_videoWriter.status == AVContentKeyRequestStatusCancelled)) {
        if ([self.delegate respondsToSelector:@selector(recorder:recordingFaild:)]) {
            [self.delegate recorder:self recordingFaild:_videoWriter.error];
        }
    } else {
        NSString    *videoPath = _videoWriter.outputURL.path;
        NSString    *audioPath = self.audioRecorder.filePath;
        NSString    *videoName = [videoPath.lastPathComponent componentsSeparatedByString:@"."].firstObject;
        videoName = [[videoName stringByReplacingOccurrencesOfString:@"_temp" withString:@""] stringByAppendingPathExtension:@"mp4"];
        NSString    *videoDir = [videoPath stringByDeletingLastPathComponent];
        NSString    *destionation = [videoDir stringByAppendingPathComponent:videoName];

        [BSRecorderUtil mergeVideo:videoPath andAudio:audioPath toPath:destionation completed:^{
            [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];

            if ([self.delegate respondsToSelector:@selector(recorder:recordingFinished:)]) {
                [self.delegate recorder:self recordingFinished:destionation];
            }
        }];
    }
}

#pragma mark - NSNotification
- (void)didEnterBackground:(NSNotification *)notification
{
    _backgroudTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
}

- (void)willEnterForeground:(NSNotification *)notification
{
    if (_backgroudTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroudTaskId];
        _backgroudTaskId = UIBackgroundTaskInvalid;
    }
}

@end
