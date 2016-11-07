//
//  LeftTrackMapController.m
//  trackmap
//
//  Created by Goldwind on 16/5/11.
//  Copyright © 2016年 Goldwind. All rights reserved.
//

#import "LeftTrackMapController.h"
#import "LeftTrackMapCell.h"
#import "YRSideViewController.h"
#import "AppDelegate.h"
#import "TrackMapViewController.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"
#import "sys/utsname.h"
#import "FMDB.h"

@interface LeftTrackMapController ()<UITableViewDelegate,UITableViewDataSource>{
    UITableView *_leftTableView;
}

@property (nonatomic,strong) NSMutableArray *upLoadArray;

@end

@implementation LeftTrackMapController

-(NSMutableArray *)upLoadArray{
    if (!_upLoadArray) {
        _upLoadArray = [[NSMutableArray alloc]initWithCapacity:10];
    }
    return _upLoadArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createTableView];
    // Do any additional setup after loading the view.
}


-(void)createTableView{
    _leftTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _leftTableView.delegate = self;
    _leftTableView.dataSource = self;
    _leftTableView.backgroundColor = [UIColor clearColor];
    _leftTableView.separatorColor = [UIColor whiteColor];
    _leftTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    
    [self.view addSubview:_leftTableView];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *Identifier = @"TrackMapIdentifier";
    LeftTrackMapCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (!cell) {
        cell = [[LeftTrackMapCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        cell.label.text = @"用户";
        cell.leftImageView.image = [UIImage imageNamed:@"truckMap_user.png"];
    }else if (indexPath.row == 1){
        cell.label.text = @"记录轨迹";
        cell.leftImageView.image = [UIImage imageNamed:@"Map_recordtruck.png"];
        cell.arrowView.image = [UIImage imageNamed:@"Map_right_icon.png"];
    }else if (indexPath.row == 2){
        cell.label.text = @"历史轨迹";
        cell.leftImageView.image = [UIImage imageNamed:@"Map_histroytruck.png"];
        cell.arrowView.image = [UIImage imageNamed:@"Map_right_icon.png"];
    }else if (indexPath.row == 3){
        cell.label.text = @"上传数据";
        cell.leftImageView.image = [UIImage imageNamed:@"Map_histroytruck.png"];
        cell.arrowView.image = [UIImage imageNamed:@"Map_right_icon.png"];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return (self.view.frame.size.height/11.5);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    YRSideViewController *sideViewCroller = [appDelegate MapSideViewController];
    UINavigationController *nav = (UINavigationController *)sideViewCroller.rootViewController;
    TrackMapViewController *trackMapView = [nav.viewControllers firstObject];
    if (indexPath.row == 1) {
        trackMapView.flag = @"0";
        [trackMapView loadTrackViewWithFlag:trackMapView.flag];
         [sideViewCroller hideSideViewController:YES];
    }else if (indexPath.row == 2){
        trackMapView.flag = @"1";
        [trackMapView loadTrackViewWithFlag:trackMapView.flag];
         [sideViewCroller hideSideViewController:YES];
    }else if (indexPath.row == 3){
        [self upLoadUserMessage];
    }
    
}


-(void)upLoadUserMessage{
    if (self.upLoadArray.count >0) {
        [self.upLoadArray removeAllObjects];
    }
    
    //获取数据库路径
    NSString *str = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSString *dbPathStr = [str stringByAppendingPathComponent:@"trackmap.db"];
    FMDatabase *locationDb = [FMDatabase databaseWithPath:dbPathStr];
    [locationDb open];
    [SVProgressHUD showWithStatus:@"正在上传..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd hh:mm:ss"];
    NSDate *date = [NSDate date];
    NSString *currentTime = [dateFormatter stringFromDate:date];
    NSString *UUIDStr = [[[UIDevice currentDevice]identifierForVendor]UUIDString];
    NSString *deviceName = [self getDeviceName];
    
    NSDictionary *dictionary = @{@"id":@"1",@"name":@"appGwses22",@"security":@"G9hXNBbTng3G5rLIPTKRciMWZ8RZ0wn9",@"flag":@"1"};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:@"https://jfhnmobile.goldwind.com.cn/seswechat/goplus/get/accesstoken" parameters:dictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@",responseObject);
        NSDictionary *dict = responseObject;
        NSString *token  = [dict objectForKey:@"access_token"];
        
        //检查上传列表
        NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM t_upLoad"];
        FMResultSet *upLoadSet = [locationDb executeQuery:sqlStr];
        while ([upLoadSet next]) {
            NSString *latitude = [upLoadSet stringForColumn:@"latitude"];
            NSString *longitude = [upLoadSet stringForColumn:@"longitude"];
            latitude = [latitude stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"维度:"]];
            longitude = [longitude stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"经度:"]];
            NSString *name = [upLoadSet stringForColumn:@"name"];
            NSString *details = [NSString stringWithFormat:@"%@$%@$%@",name,longitude,latitude];
            
            NSDictionary *upLoadDict = @{@"logId":UUIDStr,@"toUserName":@"position",@"fromUserName":@"anonymous",@"createTime":currentTime,@"eventType":@"LOCATION",@"deviceId":UUIDStr,@"deviceModel":deviceName,@"platform":@"ios",@"details":details};
            
            [self.upLoadArray addObject:upLoadDict];
        }
        NSLog(@"%@",self.upLoadArray);
        
        //NSArray *upLoadDict = @[@{@"logId":UUIDStr,@"toUserName":@"position",@"fromUserName":@"anonymous",@"createTime":currentTime,@"eventType":@"LOCATION",@"deviceId":UUIDStr,@"deviceModel":deviceName,@"platform":@"ios",@"details":@"name:一号风机$Lng:1203'11$Lat:23'33"}];
        NSString *postUrlStr = [NSString stringWithFormat:@"https://jfhnmobile.goldwind.com.cn/seswechat/goplus/app/logreport/%@",token];
        NSLog(@"%@",postUrlStr);
        [manager POST:postUrlStr parameters:self.upLoadArray success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"%@",responseObject);
            [SVProgressHUD dismiss];
            [self setAlertForTimeInterval:@"上传成功" AndTime:1];
            NSString *deleteTable = @"DELETE FROM t_upLoad";
            BOOL success = [locationDb executeUpdate:deleteTable];
            if (success) {
                NSLog(@"上传数据删除成功");
            }else{
                NSLog(@"上传数据删除失败");
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@",error);
            [SVProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        [SVProgressHUD dismiss];
        [self setAlertForTimeInterval:@"上传失败！请检查网络设置" AndTime:1];
    }];

}

-(void)setAlertForTimeInterval:(NSString *)alertStr AndTime:(int)time{
    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:alertStr message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [self presentViewController:alertCon animated:YES completion:nil];
    [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(removePromptAlert:) userInfo:alertCon repeats:NO];
}

//移除提示框
-(void)removePromptAlert:(NSTimer *)timer{
    UIAlertController *alertCon = [timer userInfo];
    [alertCon dismissViewControllerAnimated:YES completion:nil];
    alertCon = nil;
}

// 获取设备型号然后手动转化为对应名称
- (NSString *)getDeviceName
{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,3"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    if ([deviceString isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    
    if ([deviceString isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPod5,1"])      return @"iPod Touch (5 Gen)";
    
    if ([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceString isEqualToString:@"iPad1,2"])      return @"iPad 3G";
    if ([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([deviceString isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,6"])      return @"iPad Mini";
    if ([deviceString isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([deviceString isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([deviceString isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([deviceString isEqualToString:@"iPad3,3"])      return @"iPad 3";
    if ([deviceString isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([deviceString isEqualToString:@"iPad3,5"])      return @"iPad 4";
    if ([deviceString isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([deviceString isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([deviceString isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([deviceString isEqualToString:@"iPad4,4"])      return @"iPad Mini 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad4,5"])      return @"iPad Mini 2 (Cellular)";
    if ([deviceString isEqualToString:@"iPad4,6"])      return @"iPad Mini 2";
    if ([deviceString isEqualToString:@"iPad4,7"])      return @"iPad Mini 3";
    if ([deviceString isEqualToString:@"iPad4,8"])      return @"iPad Mini 3";
    if ([deviceString isEqualToString:@"iPad4,9"])      return @"iPad Mini 3";
    if ([deviceString isEqualToString:@"iPad5,1"])      return @"iPad Mini 4 (WiFi)";
    if ([deviceString isEqualToString:@"iPad5,2"])      return @"iPad Mini 4 (LTE)";
    if ([deviceString isEqualToString:@"iPad5,3"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad6,3"])      return @"iPad Pro 9.7";
    if ([deviceString isEqualToString:@"iPad6,4"])      return @"iPad Pro 9.7";
    if ([deviceString isEqualToString:@"iPad6,7"])      return @"iPad Pro 12.9";
    if ([deviceString isEqualToString:@"iPad6,8"])      return @"iPad Pro 12.9";
    
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    return deviceString;
}


@end
