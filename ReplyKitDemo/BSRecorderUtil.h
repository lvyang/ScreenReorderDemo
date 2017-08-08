//
//  BSRecorderUtil.h
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/8/4.
//  Copyright © 2017年 czl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BSRecorderUtil : NSObject

/**
 *   音频与视频的合并. action的形式如下:
 */
+ (void)mergeVideo:(NSString *)videoPath andAudio:(NSString *)audioPath toPath:(NSString *)path completed:(void (^)())completed;

/**
 *  获取视频的缩略图方法
 *
 *  @param path 视频的本地路径
 *
 *  @return 视频截图
 */
+ (UIImage *)thumnailImageForVideo:(NSString *)path;

@end
