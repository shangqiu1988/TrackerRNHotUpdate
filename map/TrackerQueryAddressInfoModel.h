//
//  TrackerQueryAddressInfoModel.h
//  Tracker
//
//  Created by tanpeng on 2018/5/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
typedef void (^ AddressHandler)(NSString *address);

@interface TrackerQueryAddressInfoModel : NSObject

@property(nonatomic,assign) CLLocationCoordinate2D coordinate;

@property(nonatomic,copy) AddressHandler handler;

-(void)startQueryAddressInfo;

@end
