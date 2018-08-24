//
//  TrackerNaviPolyline.h
//  Tracker
//
//  Created by tanpeng on 2018/7/28.
//  Copyright © 2018年 Study. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAPolyline.h>
#import "TrackerNaviAnnotation.h"
@interface TrackerNaviPolyline : NSObject<MAOverlay>
@property (nonatomic, assign) MANaviAnnotationType type;
@property (nonatomic, strong) MAPolyline *polyline;

- (id)initWithPolyline:(MAPolyline *)polyline;
@end
