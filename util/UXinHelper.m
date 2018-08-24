//
//  UXinHelper.m
//  tracker
//
//  Created by tanpeng on 17/3/20.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "UXinHelper.h"

@implementation UXinHelper
+(void)setValueForKey:(NSString *)value key:(NSString *)key
{
  [[NSUserDefaults standardUserDefaults]setValue:value forKey:key];
  [[NSUserDefaults standardUserDefaults]synchronize];
}
+(NSString *)getValueForKey:(NSString *)key
{
  NSString *value=[[NSUserDefaults standardUserDefaults]valueForKey:key];
  return value;
}
@end
