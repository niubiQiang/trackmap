//
//  TrackMapViewController.m
//  trackmap
//
//  Created by Goldwind on 16/5/3.
//  Copyright © 2016年 Goldwind. All rights reserved.
//

#import "TrackMapViewController.h"
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import "YRSideViewController.h"
#import "AFNetworking.h"
#import "FMDB.h"

#define K_VIEW_FRAME (self.view.frame.size)
#define K_RIGHTNOWURL @"http://54.222.205.103:7789/FuntionTool/ReceiveInfo"
#define K_DBURL @"http://54.222.205.103:7789/FuntionTool/ReceiveInfoList"

static NSString *currentTime;
static NSString *selectName;
static NSString *latitudeStr;
static NSString *longtitudeStr;
@interface TrackMapViewController ()<BMKLocationServiceDelegate,BMKMapViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate>{
    BMKLocationService *_locService;
    
    BMKMapView *_mapView;
    
    BMKPointAnnotation *_locAnnotation;
    
    UIImageView *_locaImageView;
    
    /**
     *  开始定位
     */
    UIButton *_locationButton;
    
    /**
     *  查询按钮
     */
    UIButton *_queryTruckButton;
    
    UIView *_backGroundView;
    
    UIView *_pickerBackGroundView;
    
    UIButton *_cancelButton;
    UIButton *_ensureButton;
    
}

/**
 *  上次定位点
 */
@property (nonatomic,strong) CLLocation *previousLocation;


/**
 *  定位点数据库
 */
@property (nonatomic,strong) FMDatabase *locationdb;

/**
 *  数据库路径
 */
@property (nonatomic,strong) NSString *dbPathStr;

/**
 *  轨迹选择器
 */
@property (nonatomic,strong) UIPickerView *trackPickerView;


/**
 *  定位点名称数组
 */
@property (nonatomic,strong) NSMutableArray *positionArray;

/**
 *  选中点数组
 */
@property (nonatomic,strong) NSMutableArray *PointMapArray;

/**
 *  定时器
 */
@property (nonatomic,strong) NSTimer *timeSearch;

/**
 维度
 */
@property (nonatomic,strong) UILabel *latitudeLabel;

/**
 经度
 */
@property (nonatomic,strong) UILabel *longtitudeLbel;


/**
 点击保存提示输入框
 */
@property (nonatomic,strong) UIAlertController  *saveAlertController;

@end


@implementation TrackMapViewController

-(NSMutableArray *)positionArray{
    if (!_positionArray) {
        _positionArray = [[NSMutableArray alloc]init];
    }
    return _positionArray;
}

-(NSMutableArray *)PointMapArray{
    if (!_PointMapArray) {
        _PointMapArray = [[NSMutableArray alloc]init];
    }
    return _PointMapArray;
}


//数据库路径
-(NSString *)dbPathStr{
    if (!_dbPathStr) {
        _dbPathStr = [[NSString alloc]init];
        NSString *str = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
        _dbPathStr = [str stringByAppendingPathComponent:@"trackmap.db"];
    }
    return _dbPathStr;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self createDB];
    
    [self setnavigationbar];
    
    
    _mapView = [[BMKMapView alloc]initWithFrame:CGRectMake(0, 64, K_VIEW_FRAME.width, K_VIEW_FRAME.height-64-80)];
    
    _locService = [[BMKLocationService alloc]init];
    
    [self setLocationService];
    [self setLocationButton];
    
    [self setDrawTrackButton];
    
    [self creaeteLatitudeAndLongtitude];
    
    [self createTrackPickerView];
    
}

-(void)creaeteLatitudeAndLongtitude{
    _latitudeLabel = [[UILabel alloc]init];
    _latitudeLabel.frame = CGRectMake((K_VIEW_FRAME.width-240)/3, 20, 120, 50);
    _latitudeLabel.numberOfLines = 1;
    _latitudeLabel.adjustsFontSizeToFitWidth = YES;
    _latitudeLabel.backgroundColor = [UIColor clearColor];
    [_mapView addSubview:_latitudeLabel];

    
    _longtitudeLbel = [[UILabel alloc]init];
    _longtitudeLbel.frame = CGRectMake((K_VIEW_FRAME.width-240)/3*2+100, 20, 120, 50);
    _longtitudeLbel.numberOfLines = 1;
    _longtitudeLbel.adjustsFontSizeToFitWidth = YES;
    _longtitudeLbel.backgroundColor = [UIColor clearColor];
    [_mapView addSubview:_longtitudeLbel];
    
}

//创建数据库
-(void)createDB{
    self.locationdb = [FMDatabase databaseWithPath:self.dbPathStr];
    if ([self.locationdb open]) {
        BOOL result = [self.locationdb executeUpdate:@"CREATE TABLE IF NOT EXISTS t_userLocal (id integer PRIMARY KEY AUTOINCREMENT,latitude text NOT NULL,longitude text NOT NULL,name text NOT NULL);"];
        if (result) {
            NSLog(@"定位点建表成功");
        }else{
            NSLog(@"定位点建表失败");
        }
        
        
        BOOL upLoadResult = [self.locationdb executeUpdate:@"CREATE TABLE IF NOT EXISTS t_upLoad (id integer PRIMARY KEY AUTOINCREMENT,latitude text NOT NULL,longitude text NOT NULL,name text NOT NULL);"];
        if (upLoadResult) {
            NSLog(@"上传数据建表成功");
        }else{
            NSLog(@"上传数据建表失败");
        }
        
    
    }
}


#pragma mark --导航栏
//设置导航栏
-(void)setnavigationbar{
    self.navigationController.navigationBar.barTintColor=[UIColor colorWithRed:41/255.0 green:147/255.0 blue:209/255.0 alpha:1.0];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:18]
                                                                      }];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 30, 30);
    [leftButton addTarget:self action:@selector(showLeftMapView) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setImage:[UIImage imageNamed:@"leftmap_nav_item.png"] forState:UIControlStateNormal];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc]initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    self.title = @"行进管理";
}


-(void)showLeftMapView{
    //移除原有绘图
//    if (self.MapPolyline) {
//        [_mapView removeOverlay:self.MapPolyline];
//    }
    //[_mapView removeOverlays:_mapView.overlays];
    [_mapView removeAnnotations:_mapView.annotations];
    if ([[UIApplication sharedApplication].keyWindow.rootViewController isKindOfClass:[YRSideViewController class]]) {
        YRSideViewController *sideViewController = (YRSideViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        [sideViewController setNeedSwipeShowMenu:false];
        [sideViewController showLeftViewController:YES];
    }
}

#pragma mark --代理
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //self.flag = [K_USER_DEAFULT objectForKey:K_MAP_FLAG];
    
    
    _locService.delegate = self;
    _mapView.delegate = self;
    [self setMapView];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    _locService.delegate = nil;
    _mapView.delegate = nil;
}

- (void)dealloc {
    if (_mapView) {
        _mapView = nil;
    }
}

//设置地图属性
-(void)setMapView{
    
    _mapView.userTrackingMode = BMKUserTrackingModeNone;
    _mapView.showsUserLocation = YES;
    _mapView.showMapScaleBar = YES;
    _mapView.zoomLevel = 18;
    _mapView.rotateEnabled = YES;
    [self setLocationAccuracyCircle];
    [self.view addSubview:_mapView];
    
    //    _locAnnotation = [[BMKPointAnnotation alloc]init];
    //
    _locaImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"mapapi.bundle/images/bnavi_icon_location_fixed@2x.png"]];
    _locaImageView.frame = CGRectMake(0, 0, _locaImageView.frame.size.width-7, _locaImageView.frame.size.height-7);
    //[_mapView addSubview:_locaImageView];
    
}

//精度圈处理
-(void)setLocationAccuracyCircle{
    BMKLocationViewDisplayParam *param = [[BMKLocationViewDisplayParam alloc] init];
    param.isAccuracyCircleShow = NO;
    param.locationViewOffsetX = 0;
    param.locationViewOffsetY = 0;
    [_mapView updateLocationViewWithParam:param];
}

//设置定位属性
-(void)setLocationService{
    _locService.distanceFilter = 1.0;
    
    _locService.desiredAccuracy = kCLLocationAccuracyBest;
    
    [_locService startUserLocationService];
    NSLog(@"定位服务开启成功！！！");
}



#pragma mark --BMKLocationServiceDelegate

/**
 *  定位失败会调用该方法
 */
- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"定位失败,error: %@",[error localizedDescription]);
    UIAlertView *gpsWeaknessWarning = [[UIAlertView alloc]initWithTitle:@"定位失败" message:@"请允许使用定位功能 设置->隐私->定位服务" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [gpsWeaknessWarning show];
}


//用户位置更新后，会调用此函数
-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    _mapView.centerCoordinate = userLocation.location.coordinate;
    
//    CGFloat dir = userLocation.heading.magneticHeading * M_PI;
    
    //NSLog(@"ffffffffff %f",dir);
    
//    _locAnnotation.coordinate = userLocation.location.coordinate;
    _locaImageView.center = [_mapView convertCoordinate:userLocation.location.coordinate toPointToView:_locaImageView];
    
    [_mapView updateLocationData:userLocation];
    
    if (userLocation.location.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters && userLocation.location.horizontalAccuracy == -1) {
        NSLog(@"当前定位精度有误差 %f",userLocation.location.horizontalAccuracy);
        UIAlertView *gpsSignal = [[UIAlertView alloc]initWithTitle:@"GPS 定位误差" message:@"GPS 定位信号出现误差，请移动更新数据..." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [gpsSignal show];
        return;
    }
    
    if (self.previousLocation) {
        //上次定位点与用户本次定位点时间间隔
        NSTimeInterval time = [userLocation.location.timestamp timeIntervalSinceDate:self.previousLocation.timestamp];
        
        //上次定位点与用户本次定位距离间隔
        CGFloat distance = [userLocation.location distanceFromLocation:self.previousLocation];
        
        //移动速度
        CGFloat speed = distance/time;
        if (speed > 20) {
            NSLog(@"速度大于20m/s return");
            return;
        }
    }
    
    if ([self.title isEqualToString:@"行进管理"]) {
        _latitudeLabel.text = [NSString stringWithFormat:@"维度:%f",userLocation.location.coordinate.latitude];
        _longtitudeLbel.text = [NSString stringWithFormat:@"经度:%f",userLocation.location.coordinate.longitude];
        latitudeStr = _latitudeLabel.text;
        longtitudeStr = _longtitudeLbel.text;
    }
    
     NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
}

//用户方向更新后，会调用此函数
-(void)didUpdateUserHeading:(BMKUserLocation *)userLocation{
    
    [_mapView updateLocationData:userLocation];
    CGFloat angle = userLocation.heading.magneticHeading * M_PI/180;
    //NSLog(@"%f",angle);
    _locaImageView.transform = CGAffineTransformMakeRotation(angle);
    
}

-(void)mapView:(BMKMapView *)mapView onDrawMapFrame:(BMKMapStatus *)status{
    //mapView.userTrackingMode = BMKUserTrackingModeFollow;
    //    BMKLocationViewDisplayParam *param = [[BMKLocationViewDisplayParam alloc] init];
    //    param.isRotateAngleValid = NO;
    //    [_mapView updateLocationViewWithParam:param];
}


#pragma mark --Button
//点击保存按钮
-(void)setLocationButton{
    _backGroundView= [[UIView alloc]initWithFrame:CGRectMake(0, _mapView.frame.origin.y+_mapView.frame.size.height, K_VIEW_FRAME.width, 80)];
    _backGroundView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_backGroundView];
    
    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.frame = CGRectMake(20, (_backGroundView.frame.size.height-50)/2, (K_VIEW_FRAME.width-40), 50);
    [_locationButton setTitle:@"点击保存" forState:UIControlStateNormal];
    _locationButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [_locationButton addTarget:self action:@selector(startLocation) forControlEvents:UIControlEventTouchUpInside];
    _locationButton.backgroundColor = [UIColor colorWithRed:41/255.0 green:147/255.0 blue:209/255.0 alpha:1.0];
    [_backGroundView addSubview:_locationButton];
}

//点击保存按钮点击事件
-(void)startLocation{
    NSString *message = [NSString stringWithFormat:@"维度:%@\r\n经度:%@",_latitudeLabel.text,_longtitudeLbel.text];
    _saveAlertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        BOOL BlankStr = [self isBlankString:_saveAlertController.textFields.firstObject.text];
        if (BlankStr) {
            [self setAlertForTimeInterval:@"输入名称不能为空" AndTime:2];
        }else{
            NSLog(@"%@",_saveAlertController.textFields.firstObject.text);
            BOOL insertResult = [self.locationdb executeUpdate:@"INSERT INTO t_userLocal (latitude, longitude, name) VALUES (?,?,?);",_latitudeLabel.text,_longtitudeLbel.text,_saveAlertController.textFields.firstObject.text];
            if (insertResult == YES) {
                NSLog(@"定位点数据插入成功");
                [self setAlertForTimeInterval:@"保存成功" AndTime:1];
            }else{
                [self setAlertForTimeInterval:@"保存失败" AndTime:1];
            }
            
            BOOL insertToUpLoad = [self.locationdb executeUpdate:@"INSERT INTO t_upLoad (latitude, longitude, name) VALUES (?,?,?);",_latitudeLabel.text,_longtitudeLbel.text,_saveAlertController.textFields.firstObject.text];
            if (insertToUpLoad == YES) {
                NSLog(@"插入上传数据成功");
            }else{
                NSLog(@"插入上传数据失败");
            }
        }
    }];;
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [_saveAlertController addAction:sure];
    [_saveAlertController addAction:cancel];
    [_saveAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
       textField.placeholder = @"请输入保存地点名称";
    }];
    
    [self presentViewController:_saveAlertController animated:YES completion:^{
        
    }];
}


-(void)setAlertForTimeInterval:(NSString *)alertStr AndTime:(int)time{
    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:alertStr message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [self presentViewController:alertCon animated:YES completion:nil];
    [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(removePromptAlert:) userInfo:alertCon repeats:NO];
}

//是否为空字符串
- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}


//移除提示框
-(void)removePromptAlert:(NSTimer *)timer{
    UIAlertController *alertCon = [timer userInfo];
    [alertCon dismissViewControllerAnimated:YES completion:nil];
    alertCon = nil;
}


//查看轨迹按钮
-(void)setDrawTrackButton{
    
    _queryTruckButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _queryTruckButton.frame = CGRectMake(20, (_backGroundView.frame.size.height-50)/2, (K_VIEW_FRAME.width-40), 50);
    [_queryTruckButton setTitle:@"查看轨迹" forState:UIControlStateNormal];
    _queryTruckButton.titleLabel.font = [UIFont systemFontOfSize:20];
    _queryTruckButton.backgroundColor = [UIColor colorWithRed:41/255.0 green:147/255.0 blue:209/255.0 alpha:1.0];
    [_queryTruckButton addTarget:self action:@selector(queryMapTrack) forControlEvents:UIControlEventTouchUpInside];
    [_backGroundView addSubview:_queryTruckButton];
    _queryTruckButton.hidden = YES;
}


-(void)createTrackPickerView{
    _pickerBackGroundView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    _pickerBackGroundView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
    
    self.trackPickerView = [[UIPickerView alloc]initWithFrame:CGRectMake((K_VIEW_FRAME.width-300)/2, 180, 300, 160)];
    self.trackPickerView.backgroundColor = [UIColor whiteColor];
    self.trackPickerView.delegate = self;
    self.trackPickerView.dataSource = self;
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelButton.frame = CGRectMake((K_VIEW_FRAME.width-300)/2, self.trackPickerView.frame.origin.y+self.trackPickerView.frame.size.height, self.trackPickerView.frame.size.width/2, 40);
    _cancelButton.backgroundColor = [UIColor whiteColor];
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelPickerView) forControlEvents:UIControlEventTouchUpInside];
    
    _ensureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _ensureButton.frame = CGRectMake((K_VIEW_FRAME.width-300)/2+_cancelButton.frame.size.width, self.trackPickerView.frame.origin.y+self.trackPickerView.frame.size.height, self.trackPickerView.frame.size.width/2, 40);
    _ensureButton.backgroundColor = [UIColor whiteColor];
    [_ensureButton setTitle:@"确定" forState:UIControlStateNormal];
    [_ensureButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_ensureButton addTarget:self action:@selector(ensurePickerView) forControlEvents:UIControlEventTouchUpInside];
    
    [_pickerBackGroundView addSubview:_ensureButton];
    [_pickerBackGroundView addSubview:_cancelButton];
    [_pickerBackGroundView addSubview:self.trackPickerView];
}

//取消按钮点击事件
-(void)cancelPickerView{
    [_pickerBackGroundView removeFromSuperview];
}

//确定按钮点击事件
-(void)ensurePickerView{
    static NSString *latitude;
    static NSString *longitude;
    
    if (self.PointMapArray.count >0) {
        [self.PointMapArray removeAllObjects];
    }
    
    [_pickerBackGroundView removeFromSuperview];
    
    NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM t_userLocal WHERE name = '%@'",selectName];
    FMResultSet *trackMapSet = [self.locationdb executeQuery:sqlStr];
    
    while ([trackMapSet next]) {
        latitude = [trackMapSet stringForColumn:@"latitude"];
        longitude = [trackMapSet stringForColumn:@"longitude"];
        latitude = [latitude stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"维度:"]];
        longitude = [longitude stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"经度:"]];
        BMKPointAnnotation *item = [[BMKPointAnnotation alloc]init];
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake([latitude floatValue],[longitude floatValue]);//纬度，经度
        item.coordinate = coords;
        item.title = selectName;
        [_mapView addAnnotation:item];
    }
    
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    NSString *AnnotationViewID = @"renameMark";
    BMKPinAnnotationView *annotationView = (BMKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewID];
    annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    // 设置颜色
    annotationView.pinColor = BMKPinAnnotationColorPurple;
    // 从天上掉下效果
    annotationView.animatesDrop = YES;
    // 设置可拖拽
    annotationView.draggable = YES;
    return annotationView;
}


- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view
{
    _latitudeLabel.text = [NSString stringWithFormat:@"纬度:%f",view.annotation.coordinate.latitude];
    _longtitudeLbel.text = [NSString stringWithFormat:@"经度:%f",view.annotation.coordinate.longitude];
}



-(BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor clearColor] colorWithAlphaComponent:0.7];
        polylineView.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:0.7];
        polylineView.lineWidth = 3.0;
        return polylineView;
    }
    return nil;
}



#pragma mark - 提示框
-(void)setAlertWithString:(NSString *)alertString{
    UIAlertController *noneAlert = [UIAlertController alertControllerWithTitle:nil message:alertString preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [noneAlert addAction:cancel];
    [self presentViewController:noneAlert animated:YES completion:nil];
}


//查看轨迹按钮点击事件
-(void)queryMapTrack{
    [self queryPositionData];
    [[UIApplication sharedApplication].keyWindow addSubview:_pickerBackGroundView];
}

#pragma mark --UIPickerView--
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return self.positionArray.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return self.positionArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    //NSLog(@"%ld",row);
    selectName = self.positionArray[row];
    NSLog(@"%@",selectName);
}

/**
 获取定位数据
 */
-(void)queryPositionData{
    if (self.positionArray.count > 0) {
        [self.positionArray removeAllObjects];
    }
    FMResultSet *timeSet = [self.locationdb executeQuery:@"SELECT * FROM t_userLocal"];
    while ([timeSet next]) {
        NSString *timeStr = [timeSet stringForColumn:@"name"];
        [self.positionArray addObject:timeStr];
    }
}


-(void)loadTrackViewWithFlag:(NSString *)flag{
    NSLog(@"FFFFFFFF %@",self.flag);
    if ([self.flag isEqualToString: @"1"]) {
        _locationButton.hidden = YES;
        _queryTruckButton.hidden = NO;
        _latitudeLabel.text = @"纬度:";
        _longtitudeLbel.text = @"经度:";
        self.title = @"查看轨迹";
    }else{
        _locationButton.hidden = NO;
        _queryTruckButton.hidden = YES;
        _latitudeLabel.text = latitudeStr;
        _longtitudeLbel.text = longtitudeStr;
        self.title = @"行进管理";
    }
}


@end
