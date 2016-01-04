//
//  KSYShortTabelViewCell.m
//  KSYVideoDemo
//
//  Created by 孙健 on 15/12/28.
//  Copyright © 2015年 kingsoft. All rights reserved.
//

#import "KSYShortTabelViewCell.h"

@interface KSYShortTabelViewCell ()

@end


@implementation KSYShortTabelViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier urlstr:(NSString *)urlstring frame:(CGRect)frame;
{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if (!self.ksyShortView) {
            self.ksyShortView=[[KSYBasePlayView alloc]initWithFrame:frame urlString:urlstring];
            [self addSubview:self.ksyShortView];
        }
    }
    return self;
}
//- (void)applicationDidBecomeActive
//{
//    
////    dispatch_async(dispatch_get_main_queue(), ^{
////        if (self.isLivePlay) {
////            [self addSubview:self.player.view];
////            [self sendSubviewToBack:self.player.view];
////            
////        }else if (self.isPuase){
////            [self play];
////        }
////        
////    });
//    [self.ksyShortView play];
//}
//
//- (void)applicationWillResignActive
//{
////    dispatch_async(dispatch_get_main_queue(), ^{
////        if (([self.player isPlaying] && self.isBackGroundReleasePlayer ) || self.isLivePlay) {
////            [self shutDown];
////        }else if ([self.player isPlaying] && !self.isLivePlay){
////            [self pause];
////        };
////    });
//    [self.ksyShortView pause];
//}

@end
