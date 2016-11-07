//
//  AppDelegate.m
//  trackmap
//
//  Created by Goldwind on 16/4/28.
//  Copyright © 2016年 Goldwind. All rights reserved.
//

#import "AppDelegate.h"
#import "TrackMapViewController.h"
#import "LeftTrackMapController.h"
#define k_SCREEN_FRAME ([[UIScreen mainScreen]bounds].size)

@interface AppDelegate (){
    BMKMapManager* _mapManager;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:@"CujWBm4IMaqFebA0GzH6DllpxFu3AHtY" generalDelegate:nil];
    if (!ret) {
        NSLog(@"BMKManager start failed");
    }
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self setTrackMapConstruction];
    
    self.window.rootViewController = _MapSideViewController;
    
    [self.window makeKeyAndVisible];
    // Override point for customization after application launch.
    return YES;
}

-(void)setTrackMapConstruction{
    TrackMapViewController *trackView = [[TrackMapViewController alloc]initWithNibName:nil bundle:nil];
    LeftTrackMapController *leftMapView = [[LeftTrackMapController alloc]initWithNibName:nil bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:trackView];
    _MapSideViewController = [[YRSideViewController alloc]initWithNibName:nil bundle:nil];
    _MapSideViewController.rootViewController = nav;
    _MapSideViewController.leftViewController = leftMapView;
    //_MapSideViewController.leftViewShowWidth = (k_SCREEN_FRAME.width-50);
    _MapSideViewController.leftViewShowWidth = 300;
    [_MapSideViewController setNeedSwipeShowMenu:false];
    [_MapSideViewController setRootViewMoveBlock:^(UIView *rootView, CGRect orginFrame, CGFloat xoffset) {
        rootView.frame=CGRectMake(xoffset, orginFrame.origin.y, orginFrame.size.width, orginFrame.size.height);
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
