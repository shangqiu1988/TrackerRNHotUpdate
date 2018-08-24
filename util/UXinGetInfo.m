//
//  UXinGetInfo.m
//  tracker
//
//  Created by tanpeng on 17/3/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "UXinGetInfo.h"
#import <CloudPushSDK/CloudPushSDK.h>
#if __has_include( <JSONKit/JSONKit.h>)
#import <JSONKit/JSONKit.h>
#else
#import "JSONKit.h"
#endif
#import "TrackerJsConfig.h"
#define KUserId @"KUserId"
#define KMobile @"KMobile"
#define KDeviceId @"KDeviceId"
#import "TrackerJsConfig.h"
@implementation UXinGetInfo
RCT_EXPORT_MODULE();
@synthesize bridge=_bridge;
-(instancetype)init
{
  self=[super init];
  if(self){
    
  }
  return self;
}
RCT_EXPORT_METHOD(getDeviceId:(nonnull RCTResponseSenderBlock)callback)
{
  NSString *deviceId= [CloudPushSDK getDeviceId];
  if(deviceId){
  callback(@[deviceId,[NSNull null]]);
  }else{
    NSString *err=[NSString stringWithFormat:@"未获取到deviceId"];
    callback(@[[NSNull null],err]);
  }
}
RCT_EXPORT_METHOD(getTenFromHex:(NSString *)ten callback:(nonnull RCTResponseSenderBlock)callback)
{
  unsigned long long result=0;
  NSScanner *scanner=[NSScanner scannerWithString:ten];
  [scanner scanHexLongLong:&result];
  NSString *resultString=[NSString stringWithFormat:@"%llu",result];
  if([resultString isKindOfClass:[NSString class]]&&resultString.length>0){
    callback(@[resultString,[NSNull null]]);
  }else{
    NSString *err=[NSString stringWithFormat:@"未获取到Emei"];
    callback(@[[NSNull null],err]);
  }
}
RCT_EXPORT_METHOD(setUserInfo:(NSString *)userInfo callback:(nonnull RCTResponseSenderBlock)callback)
{
 
  if(userInfo&&[userInfo isKindOfClass:[NSString class]]){
    NSDictionary *userInfoDic=[userInfo objectFromJSONString];
    if(userInfoDic){
      NSString *userId=[NSString stringWithFormat:@"%@",[userInfoDic objectForKey:@"userId"]];
      NSString *mobile=[userInfoDic objectForKey:@"mobile"];
      NSString *deviceId=[userInfoDic objectForKey:@"deviceId"];
      [UXinHelper setValueForKey:userId key:KUserId];
      [UXinHelper setValueForKey:mobile key:KMobile];
      [UXinHelper setValueForKey:deviceId key:KDeviceId];
    
      
    }
  }
}


RCT_EXPORT_METHOD(daoHang:(NSString *)coordinate callback:(nonnull RCTResponseSenderBlock)callback)
{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackerShowDaoHang object:coordinate];


}
RCT_EXPORT_METHOD(showToast:(NSString*)info)
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TrackerShowToast object:info];
}

@end
