//
//  TrackerMainBundleController.h
//  Tracker
//
//  Created by tanpeng on 2018/8/2.
//  Copyright © 2018年 Study. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrackerMainBundleController : UIViewController
@property(nonatomic,strong) NSURL *jsCodeLocation;
@property(nonatomic,copy) NSString *moduleName;
@property(nonatomic,strong) NSDictionary *properties;
- (instancetype)initWithJSBundleLocation:(NSURL *)jsBundlelocation moduleName:(NSString *)moduleName initialProperties:(NSDictionary *)properties;
@end
