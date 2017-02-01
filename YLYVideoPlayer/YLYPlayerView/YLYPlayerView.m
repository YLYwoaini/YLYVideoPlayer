//
//  YLYPlayerView.m
//  model
//
//  Created by YLY on 16/11/14.
//  Copyright © 2016年 YLY. All rights reserved.
//

#import "YLYPlayerView.h"
#import "UIImage+TintColor.h"
#import "UIImage+ScaleToSize.h"
#import "Slider.h"

@import AVFoundation;

typedef NS_ENUM(NSInteger, Direction) {
    Left,
    right
};

#define ScreenWidth [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height

#define PADDING 10
#define DISAPPEAR_TIME 6
#define VIEW_HEIGHT 40
#define BUTTON_HEIGHT 30
#define SLIDER_HEIGHT 20
#define PROGRESS_COLOR [UIColor colorWithRed:1.00000f green:1.00000f blue:1.00000f alpha:0.40000f]
#define PROGRESS_TINTCOLOR [UIColor colorWithRed:1.00000f green:1.00000f blue:1.00000f alpha:1.00000f]
#define FINISH_PLAY_COLOR [UIColor cyanColor]
#define SLIDER_COLOR [UIColor cyanColor]

@interface YLYPlayerView ()

@property (assign, nonatomic) CGRect customFrame;
@property (strong, nonatomic) UIView *fatherView;
@property (assign, nonatomic) BOOL isFullScreen;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *playItem;
@property (strong, nonatomic) Slider *slider;
@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIActivityIndicatorView *activity;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIButton *playButton;
@property (strong, nonatomic) NSTimer *timer;
@property (copy, nonatomic) void(^backBlock)(UIButton *backButton);
@property (copy, nonatomic) void(^endBlock)();

@end

@implementation YLYPlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _customFrame = frame;
        _isFullScreen = NO;
        _autoFullScreen = NO;
        self.backgroundColor = [UIColor blackColor];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChange:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)setUrl:(NSURL *)url {
    self.frame = _customFrame;
    _url = url;
    _playItem = [AVPlayerItem playerItemWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:_playItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = CGRectMake(0, 0, _customFrame.size.width, _customFrame.size.height);
    _playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer addSublayer:_playerLayer];
    [self originalScreen];
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activity.center = _backgroundView.center;
    [_activity startAnimating];
    [self addSubview:_activity];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

#pragma mark - 基本UI

- (void)creatUI {
    _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, _playerLayer.frame.origin.y, CGRectGetWidth(_playerLayer.frame), CGRectGetHeight(_playerLayer.frame))];
    _backgroundView.backgroundColor = [UIColor clearColor];
    [self addSubview:_backgroundView];
    
    _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_backgroundView.frame) - VIEW_HEIGHT, CGRectGetWidth(_backgroundView.frame), VIEW_HEIGHT)];
    _bottomView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [_backgroundView addSubview:_bottomView];
    
    [_playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self createPlayButton];
    [self createProgressView];
    [self createSilder];
    [self createTimeLabel];
    [self createFullScreenButton];
    [self addGesture];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeStack) userInfo:nil repeats:YES];
    _timer = [NSTimer scheduledTimerWithTimeInterval:DISAPPEAR_TIME target:self selector:@selector(disappear) userInfo:nil repeats:NO];
}

- (void)disappear {
    [UIView animateWithDuration:0.5 animations:^{
        _backgroundView.alpha = 0;
    }];
}

- (void)createPlayButton {
    _playButton = [[UIButton alloc] initWithFrame:CGRectMake(PADDING, 0, BUTTON_HEIGHT, BUTTON_HEIGHT)];
    CGPoint center = _playButton.center;
    center.y = CGRectGetHeight(_bottomView.bounds)*0.5;
    _playButton.center = center;
    [_bottomView addSubview:_playButton];
    if (_player.rate == 1.0) {
        _playButton.selected = YES;
        [_playButton setBackgroundImage:[[UIImage imageNamed:@"pauseBtn"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    } else {
        _playButton.selected = NO;
        [_playButton setBackgroundImage:[[UIImage imageNamed:@"playBtn"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    }
    [_playButton addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)startAction:(UIButton *)sender {
    if (sender.selected) {
        [self pausePlay];
    } else {
        [self playVideo];
    }
}

#pragma mark - KVC的方式隐藏状态栏

- (void)setStatusBarHidden:(BOOL)hidden
{
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    statusBar.hidden  = hidden;
}

#pragma mark - progressView部分

- (void)createProgressView {
    CGFloat width;
    if (_isFullScreen) {
        width = self.frame.size.height;
    } else {
        width = self.frame.size.width;
    }
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_playButton.frame) + PADDING, 0, width - CGRectGetMaxX(_playButton.frame) - PADDING - PADDING - 80 - PADDING - BUTTON_HEIGHT - PADDING, PADDING)];
    CGPoint center = _progressView.center;
    center.y = CGRectGetHeight(_bottomView.frame)*0.5;
    _progressView.center = center;
    _progressView.trackTintColor = PROGRESS_COLOR;
    NSTimeInterval timeInterval = [self availableDuration];
    CMTime duration = _playItem.duration;
    CGFloat totalDuration = CMTimeGetSeconds(duration);
    [_progressView setProgress:timeInterval / totalDuration animated:NO];
    CGFloat time = round(timeInterval);
    CGFloat total = round(totalDuration);
    if (isnan(time) == 0 && isnan(total) == 0) {
        if (time == total) {
            _progressView.progressTintColor = PROGRESS_TINTCOLOR;
        } else {
            _progressView.progressTintColor = [UIColor clearColor];
        }
    } else {
        _progressView.progressTintColor = [UIColor clearColor];
    }
    [_bottomView addSubview:_progressView];
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    return CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration             = _playItem.duration;
        CGFloat totalDuration       = CMTimeGetSeconds(duration);
        [_progressView setProgress:timeInterval / totalDuration animated:NO];
        _progressView.progressTintColor = PROGRESS_TINTCOLOR;
    }
}

#pragma mark - slider相关

- (void)createSilder {
    _slider = [[Slider alloc] initWithFrame:CGRectMake(CGRectGetMinX(_progressView.frame), 0, CGRectGetWidth(_progressView.frame), VIEW_HEIGHT)];
    CGPoint center = _slider.center;
    center.y = CGRectGetHeight(_bottomView.frame) * 0.5;
    _slider.center = center;
    [_bottomView addSubview:_slider];
    UIImage *image = [UIImage imageNamed:@"round"];
    UIImage *tempImage = [image OriginImage:image scaleToSize:CGSizeMake(SLIDER_HEIGHT, SLIDER_HEIGHT)];
    UIImage *newImage = [tempImage imageWithTintColor:SLIDER_COLOR];
    [_slider setThumbImage:newImage forState:UIControlStateNormal];
    [_slider addTarget:self
                action:@selector(processSliderStartDragAction:)
      forControlEvents:UIControlEventTouchDown];
    [_slider addTarget:self
                action:@selector(sliderValueChangedAction:)
      forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self
                action:@selector(processSliderEndDragAction:)
      forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    _slider.minimumTrackTintColor = FINISH_PLAY_COLOR;
    _slider.maximumTrackTintColor = [UIColor clearColor];
}

- (void)processSliderStartDragAction:(UISlider *)slider {
    [self pausePlay];
    [_timer invalidate];
}

- (void)sliderValueChangedAction:(UISlider *)slider {
    CGFloat total = (CGFloat)_playItem.duration.value / _playItem.duration.timescale;
    NSInteger dragedSeconds = floorf(total * slider.value);
    CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
    [_player seekToTime:dragedCMTime];
}

- (void)processSliderEndDragAction:(UISlider *)slider {
    [self playVideo];
    _timer = [NSTimer scheduledTimerWithTimeInterval:DISAPPEAR_TIME target:self selector:@selector(disappear) userInfo:nil repeats:NO];
}

#pragma mark - timeLabel

- (void)createTimeLabel {
    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_progressView.frame) + PADDING, 0, 80, PADDING)];
    CGPoint center = _timeLabel.center;
    center.y = _progressView.center.y;
    _timeLabel.center = center;
    _timeLabel.font = [UIFont systemFontOfSize:12];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.text = @"00:00/00:00";
    [_bottomView addSubview:_timeLabel];
}

- (void)timeStack {
    if (_playItem.duration.timescale != 0) {
        _slider.maximumValue = 1;
        _slider.value = CMTimeGetSeconds([_playItem currentTime]) / (_playItem.duration.value / _playItem.duration.timescale);
        NSInteger proMin = (NSInteger)CMTimeGetSeconds([_player currentTime]) / 60;
        NSInteger proSec = (NSInteger)CMTimeGetSeconds([_player currentTime]) % 60;
        NSInteger durMin = (NSInteger)_playItem.duration.value / _playItem.duration.timescale / 60;
        NSInteger durSec = (NSInteger)_playItem.duration.value / _playItem.duration.timescale % 60;
        _timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld / %02ld:%02ld", (long)proMin, (long)proSec, (long)durMin, (long)durSec];
    }
    if (_player.status == AVPlayerStatusReadyToPlay) {
        [_activity stopAnimating];
    } else {
        [_activity startAnimating];
    }
}

#pragma mark - 全屏OR部分

- (void)createFullScreenButton {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_timeLabel.frame) + PADDING, 0, BUTTON_HEIGHT, BUTTON_HEIGHT)];
    CGPoint center = button.center;
    center.y = CGRectGetHeight(_bottomView.bounds)*0.5;
    button.center = center;
    [_bottomView addSubview:button];
    if (_isFullScreen) {
        [button setBackgroundImage:[[UIImage imageNamed:@"minBtn"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    } else {
        [button setBackgroundImage:[[UIImage imageNamed:@"maxBtn"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    }
    [button addTarget:self action:@selector(maxAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)maxAction:(UIButton *)sender {
    if (_isFullScreen) {
        [self originalScreen];
    } else {
        [self fullScreenWithDirection:Left];
    }
}

- (void)originalScreen {
    _isFullScreen = NO;
    [_timer invalidate];
    [self setStatusBarHidden:NO];
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeRotation(0);
    }];
    self.frame = _customFrame;
    _playerLayer.frame = CGRectMake(0, 0, _customFrame.size.width, _customFrame.size.height);
    [_fatherView addSubview:self];
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self creatUI];
}

- (void)fullScreenWithDirection:(Direction)direction {
    _fatherView = self.superview;
    _isFullScreen = YES;
    [_timer invalidate];
    [self setStatusBarHidden:YES];
    [self.window addSubview:self];
    if (direction == Left) {
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeRotation(- M_PI_2);
        }];
    }
    self.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    _playerLayer.frame = CGRectMake(0, 0, ScreenHeight, ScreenWidth);
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self creatUI];
}

#pragma mark - 点击手势

- (void)addGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
}

- (void)tapAction:(id)sender {
    [_timer invalidate];
    if (_backgroundView.alpha == 1) {
        [UIView animateWithDuration:0.5 animations:^{
            _backgroundView.alpha = 0;
        }];
    } else if (_backgroundView.alpha == 0) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:DISAPPEAR_TIME target:self selector:@selector(disappear) userInfo:nil repeats:NO];
        [UIView animateWithDuration:0.5 animations:^{
            _backgroundView.alpha = 1;
        }];
    }
}

#pragma mark - 播放完毕回调

- (void)videoPlayDidEnd:(id)sender {
    [self pausePlay];
    self.endBlock();
}

- (void)endPlay:(endBlock)endBlock {
    self.endBlock = endBlock;
}

#pragma mark - 返回按钮回调

- (void)backButtonAction:(UIButton *)sender {
    self.backBlock(sender);
}

- (void)backButton:(backButtonBlock)backBlock {
    self.backBlock = backBlock;
}

#pragma mark - 播放暂停

- (void)playVideo {
    _playButton.selected = YES;
    [_player play];
    [_playButton setBackgroundImage:[[UIImage imageNamed:@"pauseBtn"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
}

- (void)pausePlay {
    _playButton.selected = NO;
    [_player pause];
    [_playButton setBackgroundImage:[[UIImage imageNamed:@"playBtn"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
}

- (void)resetPlay {
    [_player seekToTime:CMTimeMake(0, 1)];
    [self playVideo];
}

#pragma mark - 屏幕旋转通知

- (void)statusBarOrientationChange:(NSNotification *)notification {
    if (!_autoFullScreen) {
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        [self fullScreenWithDirection:Left];
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        [self fullScreenWithDirection:right];
    } else if (orientation == UIDeviceOrientationPortrait) {
        [self originalScreen];
    }
}

#pragma mark - APP活动通知

- (void)appWillResignActive:(NSNotification *)notification {
    [self pausePlay];
}

-(void)dealloc {
    [_playItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

@end
