//
//  AppDelegate.h
//  trackmap
//
//  Created by Goldwind on 16/4/28.
//  Copyright © 2016年 Goldwind. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import "YRSideViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,strong)YRSideViewController *MapSideViewController;

@end

