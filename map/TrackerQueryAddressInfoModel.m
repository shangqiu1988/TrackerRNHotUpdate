//
//  TrackerQueryAddressInfoModel.m
//  Tracker
//
//  Created by tanpeng on 2018/5/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "TrackerQueryAddressInfoModel.h"

#import <AMapSearchKit/AMapSearchKit.h>

@interface TrackerQueryAddressInfoModel () <AMapSearchDelegate>


@property(nonatomic,strong) AMapSearchAPI *search;

@end

@implementation TrackerQueryAddressInfoModel

-(void)dealloc
{
  _handler = nil;
  _search.delegate = nil;
}

- (void)setHandler:(AddressHandler)handler
{
  
  _handler = [handler copy];
}

-(AMapSearchAPI *)search
{
  if(_search == nil){
    
    
    _search = [[AMapSearchAPI alloc] init];
    
    _search.delegate = self;
    
  }
  return _search;
}

-(void)startQueryAddressInfo
{
   AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
  
  regeo.location = [AMapGeoPoint locationWithLatitude:_coordinate.latitude longitude:_coordinate .longitude];
  
  regeo.requireExtension = YES;
  regeo.radius = 20;
  
  [self.search AMapReGoecodeSearch:regeo];
  
}

#pragma mark - AMapSearchDelegate
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
  if(_handler){
    
    _handler(nil);
  }
}

/* 逆地理编码回调. */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
  if(response.regeocode){
    
    AMapReGeocode *GeoCode = response.regeocode;
    
    NSString *address = [NSString stringWithFormat:@"%@%@%@%@%@",GeoCode.addressComponent.city ?: @"",
                         GeoCode.addressComponent.district?: @"",
                         GeoCode.addressComponent.township?: @"",
                         GeoCode.addressComponent.neighborhood?: @"",
                         GeoCode.addressComponent.building?: @""
                         ];
    if(_handler){
      
      _handler(address);
      
    }
    
  }else{
    
    if(_handler){
      
      _handler(nil);
    }
  }
}

@end
