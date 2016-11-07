//
//  trackLoad.m
//  trackmap
//
//  Created by Goldwind on 16/7/27.
//  Copyright © 2016年 Goldwind. All rights reserved.
//

#import "trackLoad.h"
#import "TrackMapViewController.h"
#import "LeftTrackMapController.h"
#import "YRSideViewController.h"
#import "AppDelegate.h"

@implementation trackLoad

-(void)loadFrameworkView:(id)frameWorkView WithBundle:(NSBundle *)bundle{
    TrackMapViewController *trackMapView = [[TrackMapViewController alloc]init];
    LeftTrackMapController *leftTrackView = [[LeftTrackMapController alloc]init];
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:trackMapView];
    YRSideViewController *sideCon = [[YRSideViewController alloc]init];
    sideCon.rootViewController = nav;
    sideCon.leftViewController = leftTrackView;
    sideCon.leftViewShowWidth = 300;
    [sideCon setNeedSwipeShowMenu:false];
    
    [sideCon performSelector:@selector(setNeedSwipeShowMenu:) withObject:false];
    
    [sideCon setRootViewMoveBlock:^(UIView *rootView, CGRect orginFrame, CGFloat xoffset) {
        rootView.frame=CGRectMake(xoffset, orginFrame.origin.y, orginFrame.size.width, orginFrame.size.height);
    }];
    NSLog(@"11111");
    
    //if ([[UIApplication sharedApplication].keyWindow.rootViewController isKindOfClass:[YRSideViewController class]]) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        NSLog(@"222222");
        SEL sel = NSSelectorFromString(@"MapSideViewController");
        if ([appDelegate respondsToSelector:sel]) {
            NSLog(@"33333");
            [appDelegate setValue:sideCon forKey:@"MapSideViewController"];
        }
    //}
    NSLog(@"44444");
    UIViewController *viewCon = (UIViewController *)frameWorkView;
    NSLog(@"555555");
    [viewCon presentViewController:sideCon animated:YES completion:^{
        NSLog(@"跳转路径规划模块成功");
    }];
}

@end
