//
//  TrackerMainBundleController.m
//  Tracker
//
//  Created by tanpeng on 2018/8/2.
//  Copyright © 2018年 Study. All rights reserved.
//

#import "TrackerMainBundleController.h"
#import <React/RCTRootView.h>
#import "TrackerJsConfig.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <AMapNaviKit/AMapNaviKit.h>
#import "TrackerJsConfig.h"
@interface TrackerMainBundleController ()<AMapNaviCompositeManagerDelegate>
@property (nonatomic, strong) AMapNaviCompositeManager *compositeManager;
@property(nonatomic,strong) MBProgressHUD *hud;
@end

@implementation TrackerMainBundleController
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithJSBundleLocation:(NSURL *)jsBundlelocation moduleName:(NSString *)moduleName initialProperties:(NSDictionary *)properties
{
    self = [super init];
    if(self){
        _jsCodeLocation  = jsBundlelocation;
        _moduleName = [moduleName copy];
        _properties = properties;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(daoHang:) name:TrackerShowDaoHang object:nil];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showToast:) name:TrackerShowToast object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)loadView
{
    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:_jsCodeLocation
                                                        moduleName:_moduleName
                                                 initialProperties:_properties
                                                     launchOptions:nil];
    
    rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
    self.view = rootView;
}
#pragma mark - notification
- (void)showToast:(NSNotification *)notification
{
    NSString * info= notification.object;
    if(info&&[info isKindOfClass:[NSString class]]&&info.length>0){
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(weakSelf.hud == nil){
                weakSelf. hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
                [[UIApplication sharedApplication].keyWindow addSubview:  weakSelf. hud];
            }
            [weakSelf.hud showAnimated:YES];
            weakSelf.hud.label.text = info;
            [weakSelf.hud setMode:MBProgressHUDModeText];
            [weakSelf.hud hideAnimated:NO afterDelay:2.0];
            
        });
        
        
    }
    
    
}
#pragma mark - 添加导航
- (void)daoHang:(NSNotification *)notification
{
    NSString * info= notification.object;
    if(info&&[info isKindOfClass:[NSString class]]&&info.length>0){
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSData *jsonData = [info dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err;
            NSArray *arr = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&err];
            
            if(arr.count>0 ){
                NSDictionary * positionValue = [arr objectAtIndex:0];
                CGFloat latitude = [[positionValue objectForKey:@"latitude"] floatValue];
                CGFloat longitude = [[positionValue objectForKey:@"longitude"] floatValue];
                [weakSelf toEndPoint:longitude lat:latitude];
            }else{
                return;
            }
        });
     
    }
 
}

// init
- (AMapNaviCompositeManager *)compositeManager {
    if (!_compositeManager) {
        _compositeManager = [[AMapNaviCompositeManager alloc] init];  // 初始化
        _compositeManager.delegate = self;  // 如果需要使用AMapNaviCompositeManagerDelegate的相关回调（如自定义语音、获取实时位置等），需要设置delegate
    }
    return _compositeManager;
    
    
}

-(void)toEndPoint:(CGFloat )lon lat:(CGFloat )lat{
    
    AMapNaviCompositeUserConfig *config = [[AMapNaviCompositeUserConfig alloc] init];
    [config setRoutePlanPOIType:AMapNaviRoutePlanPOITypeEnd location:[AMapNaviPoint locationWithLatitude:lat longitude:lon] name:@"车辆位置" POIId:nil];  //传入终点
    [self.compositeManager presentRoutePlanViewControllerWithOptions:config];
}

//// 传入终点
//- (void)routePlanWithEndPoint:(CGFloat)lat longitude:(CGFloat)lon{
//
//    AMapNaviCompositeUserConfig *config = [[AMapNaviCompositeUserConfig alloc] init];
//    [config setRoutePlanPOIType:AMapNaviRoutePlanPOITypeEnd location:[AMapNaviPoint locationWithLatitude:39.918058 longitude:116.397026] name:@"故宫" POIId:nil];  //传入终点
//    [self.compositeManager presentRoutePlanViewControllerWithOptions:config];
//}

#pragma mark - 导航回调方法

// 发生错误时,会调用代理的此方法
- (void)compositeManager:(AMapNaviCompositeManager *)compositeManager error:(NSError *)error {
    NSLog(@"error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

// 算路成功后的回调函数,路径规划页面的算路、导航页面的重算等成功后均会调用此方法
- (void)compositeManagerOnCalculateRouteSuccess:(AMapNaviCompositeManager *)compositeManager {
    NSLog(@"onCalculateRouteSuccess,%ld",(long)compositeManager.naviRouteID);
}

// 算路失败后的回调函数,路径规划页面的算路、导航页面的重算等失败后均会调用此方法
- (void)compositeManager:(AMapNaviCompositeManager *)compositeManager onCalculateRouteFailure:(NSError *)error {
    NSLog(@"onCalculateRouteFailure error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

// 开始导航的回调函数
- (void)compositeManager:(AMapNaviCompositeManager *)compositeManager didStartNavi:(AMapNaviMode)naviMode {
    NSLog(@"didStartNavi,%ld",(long)naviMode);
}

// 当前位置更新回调
- (void)compositeManager:(AMapNaviCompositeManager *)compositeManager updateNaviLocation:(AMapNaviLocation *)naviLocation {
    NSLog(@"updateNaviLocation,%@",naviLocation);
}

// 导航到达目的地后的回调函数
- (void)compositeManager:(AMapNaviCompositeManager *)compositeManager didArrivedDestination:(AMapNaviMode)naviMode {
    NSLog(@"didArrivedDestination,%ld",(long)naviMode);
}


@end
