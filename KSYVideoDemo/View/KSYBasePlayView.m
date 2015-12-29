//
//  KSYBasePlayView.m
//  KSYVideoDemo
//
//  Created by 崔崔 on 15/12/18.
//  Copyright © 2015年 kingsoft. All rights reserved.
//

#import "KSYBasePlayView.h"


@interface KSYBasePlayView ()<UIAlertViewDelegate>


@end

@implementation KSYBasePlayView

- (void)dealloc
{
    [self stopTimer];
    if (_player) {
        [_player stop];
        [_player.view removeFromSuperview];
        _player = nil;
    }
    [self releaseObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
//    [self unregisterApplicationObservers];
}

- (instancetype)initWithFrame:(CGRect)frame urlString:(NSString *)urlString
{
    self = [super initWithFrame:frame];
    if (self) {
        self.urlString = urlString;
        self.backgroundColor = [UIColor blackColor];
        if ([urlString hasPrefix:@"http"]) {
            self.isLivePlay = NO;
        }else if ([urlString hasPrefix:@"rtmp"]){
            self.isLivePlay = YES;
        }

        [self addSubview:self.player.view];
        [self addSubview:self.indicator];
        [self bringSubviewToFront:_indicator];
        [self setupObservers];
        
        [self registerApplicationObservers];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
        NSString *remoteHostName = @"www.baidu.com";
        
        self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
        [self.hostReachability startNotifier];
//        [self updateInterfaceWithReachability:self.hostReachability];
        



    }
    return self;
}

//- (void)setIsBackGroundReleasePlayer:(BOOL)isBackGroundReleasePlayer
//{
//    if (isBackGroundReleasePlayer == YES) {
//        [self registerApplicationObservers];
//        
//    }
//
//}

- (KSYMoviePlayerController *)player
{
    if (_player == nil) {
        _player = [[KSYMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:_urlString]];
        [_player.view setFrame:self.bounds];
        _player.controlStyle = MPMovieControlStyleNone;
        self.autoresizesSubviews = TRUE;
        _player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _player.shouldAutoplay = TRUE;
        _player.scalingMode = MPMovieScalingModeAspectFit;
        [self sendSubviewToBack:_player.view];
        if (_networkStatus != ReachableViaWWAN) {
            [_player prepareToPlay];
            [self.indicator startAnimating];

        }
    }
    return _player;
}
- (UIActivityIndicatorView *)indicator
{
    if (_indicator == nil) {
        _indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _indicator.backgroundColor = [UIColor clearColor];
        _indicator.layer.cornerRadius = 6;
        _indicator.layer.masksToBounds = YES;
        [_indicator setCenter:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0)];

    }
    
    return _indicator;
}
#pragma mark- playerControl

- (void)replay
{
    [self play];
    [self startTimer];

}
- (void)play
{
    if (self.player) {
        [self.player play];
    }
}

- (void)pause
{
    if (self.player) {
        [self.player pause];
    }

}

- (void)stop
{
    if (self.player) {
        [self.player stop];
    }

}

- (void)shutDown
{
    [self stopTimer];
    if (_player) {
        [_player stop];
        [_player.view removeFromSuperview];
        _player = nil;
    }
    [self releaseObservers];

}
- (NSTimeInterval)currentPlaybackTime
{
    if (self.player) {
        return self.player.currentPlaybackTime;
    }
    return 0;
}

- (NSTimeInterval)duration
{
    if (self.player) {
        return self.player.duration;
    }
    return 0;
}
#pragma mark- playerState

- (void)moviePlayerPlaybackState:(MPMoviePlaybackState)playbackState
{
    NSLog(@"player playback state: %ld", (long)playbackState);

}

- (void)moviePlayerLoadState:(MPMovieLoadState)loadState
{
    NSLog(@"player load state: %ld", (long)loadState);
    
    if (loadState == MPMovieLoadStateStalled) {
        [_indicator startAnimating];

    }else {
        [_indicator stopAnimating];
    }

}

- (void)moviePlayerReadSize:(double)readSize
{
    NSLog(@"player download flow size: %f MB", readSize);

}

- (void)moviePlayerFinishState:(MPMoviePlaybackState)finishState
{
    NSLog(@"player finish state: %ld", finishState);
    if (finishState == MPMoviePlaybackStateStopped) {
        [self stopTimer];
        if (!_isShowFinishAlert) {
            UIAlertView *finishAlertView = [[UIAlertView alloc] initWithTitle:nil message:@"播放完成，是否重新播放？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"播放", nil];
            finishAlertView.tag = 104;
            [finishAlertView show];
            _isShowFinishAlert = YES;

        }

    }

}

- (void)moviePlayerFinishReson:(MPMovieFinishReason)finishReson
{
    NSLog(@"player finish reson is %ld",finishReson);
    if (finishReson == MPMovieFinishReasonPlaybackError && _isShowErrorAlert == NO) {
        UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:nil message:@"播放错误，是否重试？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"重试", nil];
        errorAlertView.tag = 101;
        [errorAlertView show];
        _isShowErrorAlert = YES;

    }
}

- (void)moviePlayerSeekTo:(NSTimeInterval)position
{
    if (self.player) {
        self.player.currentPlaybackTime = position;
    }
}
- (void)startTimer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCurrentTime) userInfo:nil repeats:YES];

    }
}

- (void)stopTimer
{
    if (nil == _timer) {
        return;
    }
    [_timer invalidate];
    _timer = nil;
}

- (void)updateCurrentTime
{
    NSLog(@"currentTime is %f",self.currentPlaybackTime);

}

- (void)timerIsStop:(BOOL)isStop
{
    if (isStop) {
        [_timer setFireDate:[NSDate distantFuture]];
    }else {
         [_timer setFireDate:[NSDate date]];
    }
}

#pragma mark -alertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    
    
    if (alertView.tag == 101 ) {//错误提示弹框
        _isShowErrorAlert = NO;
        if (buttonIndex != alertView.cancelButtonIndex) {
            [self shutDown];
            [self addSubview:self.player.view];
            [self sendSubviewToBack:self.player.view];
            [self setupObservers];
            
        }else {
            [_indicator stopAnimating];
        }

    }else if (alertView.tag == 103 && buttonIndex != alertView.cancelButtonIndex){
        _isNetShowAlert=NO;
        if ([self.player isPreparedToPlay]) {
            [self play];
        }else {
            [self.player prepareToPlay];
        }
        
    }else if (alertView.tag == 104 && buttonIndex != alertView.cancelButtonIndex){//完成提示弹框
        _isShowFinishAlert = NO;
        [self replay];
    }
}

#pragma mark- notify
-(void)handlePlayerNotify:(NSNotification*)notify
{
    
    if (!_player) {
        return;
    }
    if (MPMediaPlaybackIsPreparedToPlayDidChangeNotification ==  notify.name) {
        [self.indicator stopAnimating];
        [self startTimer];
    }
    if (MPMoviePlayerPlaybackStateDidChangeNotification ==  notify.name) {
        
        [self moviePlayerPlaybackState:self.player.playbackState];
    }
    if (MPMoviePlayerLoadStateDidChangeNotification ==  notify.name) {
        
        [self moviePlayerLoadState:self.player.loadState];
        
    }
    if (MPMoviePlayerPlaybackDidFinishNotification ==  notify.name) {
        
        [self moviePlayerFinishState:self.player.playbackState];

//        [self moviePlayerReadSize:self.player.readSize];
        
        NSNumber *reason = [[notify userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
        [self moviePlayerFinishReson:[reason integerValue]];

    }
    
}

//播放器状态通知
- (void)setupObservers
{
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMediaPlaybackIsPreparedToPlayDidChangeNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerPlaybackStateDidChangeNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerPlaybackDidFinishNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerLoadStateDidChangeNotification)
                                              object:nil];
}

- (void)releaseObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerPlaybackDidFinishNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerLoadStateDidChangeNotification
                                                 object:nil];
}


- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}


- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:
        {
            if (_networkStatus != NotReachable && _isNetShowAlert == NO) {
                [self pause];
                UIAlertView *networkAlertView = [[UIAlertView alloc] initWithTitle:nil message:@"网络似乎已经断开，请检查网络" delegate:self cancelButtonTitle:nil otherButtonTitles:@"我知道了", nil];
                networkAlertView.tag = 102;
                [networkAlertView show];
                _isNetShowAlert = YES;

            }
            _networkStatus = NotReachable;
            break;
        }
            
        case ReachableViaWiFi:
        {
            if (_networkStatus != ReachableViaWiFi) {
                [self play];
            }
            _networkStatus = ReachableViaWiFi;

            NSLog(@"wifi");
            
            break;
        }
        case ReachableViaWWAN:
        {
            if (_networkStatus != ReachableViaWWAN && _isWifiShowAlert == NO) {

                if ([self.player isPreparedToPlay]) {
                    [self pause];

                }
                UIAlertView *wifiAlertView = [[UIAlertView alloc] initWithTitle:nil message:@"wifi已经断开，继续播放将产生流量费用，是否继续？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"继续", nil];
                wifiAlertView.tag = 103;
                [wifiAlertView show];
                _isWifiShowAlert = YES;

            }
            _networkStatus = ReachableViaWWAN;

            NSLog(@"3G");

            break;
        }
        default:
            break;
    }
    
    
    
}

//应用状态通知
- (void)registerApplicationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void)unregisterApplicationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)applicationWillEnterForeground
{
}

- (void)applicationDidBecomeActive
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isLivePlay) {
            [self addSubview:self.player.view];
            [self sendSubviewToBack:self.player.view];
            [self setupObservers];

        }else {
            [self play];
        }
        
    });
}

- (void)applicationWillResignActive
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (([self.player isPlaying] && self.isBackGroundReleasePlayer ) || self.isLivePlay) {
            [self shutDown];

        }else if ([self.player isPlaying] && !self.isLivePlay){
            [self pause];
        };
    });
    
}

- (void)applicationDidEnterBackground
{
    dispatch_async(dispatch_get_main_queue(), ^{

    });
}

- (void)applicationWillTerminate
{
    dispatch_async(dispatch_get_main_queue(), ^{

    });
}


@end
