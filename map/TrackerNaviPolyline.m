//
//  TrackerNaviPolyline.m
//  Tracker
//
//  Created by tanpeng on 2018/7/28.
//  Copyright © 2018年 Study. All rights reserved.
//

#import "TrackerNaviPolyline.h"

@implementation TrackerNaviPolyline
- (id)initWithPolyline:(MAPolyline *)polyline
{
    self = [super init];
    if (self)
    {
        self.polyline = polyline;
        self.type = MANaviAnnotationTypeDrive;
    }
    return self;
}

- (CLLocationCoordinate2D) coordinate
{
    return [_polyline coordinate];
}

- (MAMapRect) boundingMapRect
{
    return [_polyline boundingMapRect];
}
@end
