//
//  YLYVideoPlayer.h
//  YLYVideoPlayer
//
//  Created by YLY on 16/11/11.
//  Copyright © 2016年 YLY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Masonry.h"
@import MediaPlayer;
@import AVFoundation;
@import UIKit;

typedef NS_ENUM(NSInteger, YLYVideoPlayState) {
    YLYVideoPlayStateFailed,
    YLYVideoPlayStateBuffering,
    YLYVideoPlayStateReadyToPlay,
    YLYVideoPlayStatePlaying,
    YLYVideoPlayStateStopped,
    YLYVideoPlayStateFinished
};

typedef NS_ENUM(NSInteger, CloseBtnStyle) {
    CloseBtnStylePop,
    CloseBtnStyleClose
};

@class YLYVideoPlayer;

@protocol YLYVideoPlayerDelegate <NSObject>

@optional



@end

@interface YLYVideoPlayer : UIView

@end
