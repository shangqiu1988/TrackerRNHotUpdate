//
//  TrackerNaviRoute.h
//  Tracker
//
//  Created by tanpeng on 2018/7/28.
//  Copyright © 2018年 Study. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "TrackerNaviPolyline.h"
#import "TrackerNaviAnnotation.h"
@interface TrackerNaviRoute : NSObject
/// 是否显示annotation, 显示路况的情况下无效。
@property (nonatomic, assign) BOOL anntationVisible;

@property (nonatomic, strong) NSArray *routePolylines;
@property (nonatomic, strong) NSArray *naviAnnotations;

/// 普通路线颜色
@property (nonatomic, strong) UIColor *routeColor;
/// 步行路线颜色
@property (nonatomic, strong) UIColor *walkingColor;
/// 铁路路线颜色
@property (nonatomic, strong) UIColor *railwayColor;
/// 多彩线颜色
@property (nonatomic, strong) NSArray<UIColor *> *multiPolylineColors;
@property (nonatomic,weak) MAMapView *mapView;
- (void)addToMapView:(MAMapView *)mapView;

- (void)removeFromMapView;

+ (instancetype)naviRouteForPath:(AMapPath *)path withNaviType:(MANaviAnnotationType)type showTraffic:(BOOL)showTraffic startPoint:(AMapGeoPoint *)start endPoint:(AMapGeoPoint *)end;
@end
