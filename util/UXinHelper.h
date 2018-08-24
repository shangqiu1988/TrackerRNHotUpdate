//
//  UXinHelper.h
//  tracker
//
//  Created by tanpeng on 17/3/20.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UXinHelper : NSObject
+(void)setValueForKey:(NSString *)value key:(NSString *)key;
+(NSString *)getValueForKey:(NSString *)key;
@end
