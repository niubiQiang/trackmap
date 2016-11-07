//
//  TrackMapViewController.h
//  trackmap
//
//  Created by Goldwind on 16/5/3.
//  Copyright © 2016年 Goldwind. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrackMapViewController : UIViewController

/**
 *  判断页面  1为查看轨迹  0为开始定位
 */
@property (nonatomic,strong)NSString *flag;


-(void)loadTrackViewWithFlag:(NSString *)flag;

@end
