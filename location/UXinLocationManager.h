//
//  UXinLocationManager.h
//  tracker
//
//  Created by tanpeng on 17/3/17.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface UXinLocationManager : NSObject<CLLocationManagerDelegate>
{
  CLLocationManager *_locationManager;
}
@property(nonatomic,strong) CLLocation* currentLoaction;
-(void)startLocationService:(CLLocationAccuracy)desiredAccuracy distanceFilter:(CLLocationDistance)distanceFilter;
@end
