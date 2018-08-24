//
//  TrackerNowLocationAnnotation.h
//  tracker
//
//  Created by tanpeng on 17/5/9.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

@interface TrackerNowLocationAnnotation : MAPointAnnotation
@property(nonatomic,assign) NSInteger mode; // 1 2 3 4 5
@end
