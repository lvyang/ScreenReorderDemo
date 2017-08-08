//
//  VideoModel.m
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/8/7.
//  Copyright © 2017年 czl. All rights reserved.
//

#import "VideoModel.h"
#import "BSRecorderUtil.h"

@implementation VideoModel

- (UIImage *)thumnailImage
{
    if (!_thumnailImage) {
        _thumnailImage = [BSRecorderUtil thumnailImageForVideo:self.filePath];
    }
    
    return _thumnailImage;
}

- (NSString *)fileName
{
    if (!_fileName) {
        _fileName = self.filePath.lastPathComponent;
    }
    
    return _fileName;
}

@end
