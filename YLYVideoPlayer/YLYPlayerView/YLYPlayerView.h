//
//  YLYPlayerView.h
//  model
//
//  Created by YLY on 16/11/14.
//  Copyright © 2016年 YLY. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^backButtonBlock)(UIButton *button);
typedef void(^endBlock)();

@interface YLYPlayerView : UIView

@property (strong, nonatomic) NSURL *url;
@property (assign, nonatomic) BOOL autoFullScreen;

- (void)backButton:(backButtonBlock) backBlock;
- (void)endPlay:(endBlock)endBlock;
- (void)playVideo;
- (void)pausePlay;
- (void)resetPlay;

@end
