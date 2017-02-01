//
//  ViewController.m
//  YLYVideoPlayer
//
//  Created by YLY on 16/11/11.
//  Copyright © 2016年 YLY. All rights reserved.
//

#import "ViewController.h"
#import "YLYPlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    YLYPlayerView *playerView = [[YLYPlayerView alloc] initWithFrame:CGRectMake(0, 90, 200, 300)];
    [self.view addSubview:playerView];
    //视频地址
    playerView.url = [NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2016/0215/56c1809735217_wpd.mp4"];
    //根据旋转自动支持全屏，默认不支持
    playerView.autoFullScreen = YES;
    
    //返回按钮点击事件回调
    [playerView backButton:^(UIButton *button) {
        NSLog(@"返回按钮被点击");
    }];
    //播放完成回调
    [playerView endPlay:^{
        NSLog(@"播放完成");
        //重新开始播放
       // [playerView resetPlay];
    }];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
