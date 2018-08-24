//
//  TrackerLineDashPolyline.h
//  Tracker
//
//  Created by tanpeng on 2018/7/28.
//  Copyright © 2018年 Study. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAPolyline.h>
#import <MAMapKit/MAOverlay.h>
@interface TrackerLineDashPolyline : NSObject<MAOverlay>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, readonly) MAMapRect boundingMapRect;

@property (nonatomic, retain)  MAPolyline *polyline;

- (id)initWithPolyline:(MAPolyline *)polyline;
@end
