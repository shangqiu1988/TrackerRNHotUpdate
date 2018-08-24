//
//  TrackerNaviRoute.m
//  Tracker
//
//  Created by tanpeng on 2018/7/28.
//  Copyright © 2018年 Study. All rights reserved.
//

#import "TrackerNaviRoute.h"
#import <MAMapKit/MAMapKit.h>
#import "TrackerMapUtility.h"
#import "TrackerNaviPolyline.h"
#import "TrackerNaviAnnotation.h"
@implementation TrackerNaviRoute
- (void)addToMapView:(MAMapView *)mapView
{
    self.mapView = mapView;
    
    if ([self.routePolylines count] > 0)
    {
        [mapView addOverlays:self.routePolylines];
    }
    
    if (self.anntationVisible && [self.naviAnnotations count] > 0)
    {
        [mapView addAnnotations:self.naviAnnotations];
    }
}

- (void)removeFromMapView
{
    if (self.mapView == nil)
    {
        return;
    }
    
    if ([self.routePolylines count] > 0)
    {
        [self.mapView removeOverlays:self.routePolylines];
    }
    
    if (self.anntationVisible && [self.naviAnnotations count] > 0)
    {
        [self.mapView removeAnnotations:self.naviAnnotations];
    }
    
    self.mapView = nil;
}
+ (instancetype)naviRouteForPath:(AMapPath *)path withNaviType:(MANaviAnnotationType)type showTraffic:(BOOL)showTraffic startPoint:(AMapGeoPoint *)start endPoint:(AMapGeoPoint *)end
{
  
      return [[self alloc] initWithPath:path withNaviType:type showTraffic:showTraffic startPoint:start endPoint:end];
}
- (instancetype)initWithPath:(AMapPath *)path withNaviType:(MANaviAnnotationType)type showTraffic:(BOOL)showTraffic startPoint:(AMapGeoPoint *)start endPoint:(AMapGeoPoint *)end
{
    self = [super init];
    
    if(self){
    
        NSMutableArray *polines = [NSMutableArray array];
        
        NSMutableArray *naviAnnotations = [NSMutableArray array];
        
        
        if(showTraffic && (type == MANaviAnnotationTypeDrive || type == MANaviAnnotationTypeTruck)){
            
            NSArray *polinesColors = nil;
            
            MAPolyline *poline = [TrackerNaviRoute multiColoredPolylineWithDrivePath:path polylineColors:&polinesColors];
            if(poline){
                [polines addObject:poline];
                
            }
        }else{
            
            [path.steps enumerateObjectsUsingBlock:^(AMapStep * _Nonnull step, NSUInteger idx, BOOL * _Nonnull stop) {
                MAPolyline *stepPolyline = [TrackerNaviRoute polylineForStep:step];
                
                if (stepPolyline != nil)
                {
                    TrackerNaviPolyline *naviPolyline = [[TrackerNaviPolyline alloc] initWithPolyline:stepPolyline];
                    naviPolyline.type = type;
                    
                    [polines addObject:naviPolyline];
                    
                    if (idx > 0)
                    {
                        TrackerNaviAnnotation * annotation = [[TrackerNaviAnnotation alloc] init];
                        annotation.coordinate = MACoordinateForMapPoint(stepPolyline.points[0]);
                        annotation.type = type;
                        annotation.title = step.instruction;
                        [naviAnnotations addObject:annotation];
                    }
                    
                    if (idx > 0)
                    {
                        // 填充step和step之间的空隙
//                        [MANaviRoute replenishPolylinesForPathWith:stepPolyline
//                                                      lastPolyline:[MANaviRoute polylineForStep:[path.steps objectAtIndex:idx-1]]
//                                                         Polylines:polylines];
                    }
                }
            }];
           
        }
        self.routePolylines = polines;
    }
    return self;
}
+ (MAPolyline *)polylineForStep:(AMapStep *)step
{
    if (step == nil)
    {
        return nil;
    }
    
    return [TrackerMapUtility polylineForCoordinateString:step.polyline];
}

+ (NSArray *)coordinateArrayWithPolylineString:(NSString *)string
{
    return [string componentsSeparatedByString:@";"];
}
+ (double)calcDistanceBetweenCoor:(CLLocationCoordinate2D)coor1 andCoor:(CLLocationCoordinate2D)coor2
{
    MAMapPoint mapPointA = MAMapPointForCoordinate(coor1);
    MAMapPoint mapPointB = MAMapPointForCoordinate(coor2);
    return MAMetersBetweenMapPoints(mapPointA, mapPointB);
}
+ (CLLocationCoordinate2D)coordinateWithString:(NSString *)string
{
    NSArray *coorArray = [string componentsSeparatedByString:@","];
    if (coorArray.count != 2)
    {
        return kCLLocationCoordinate2DInvalid;
    }
    return CLLocationCoordinate2DMake([coorArray[1] doubleValue], [coorArray[0] doubleValue]);
}
+ (UIColor *)colorWithTrafficStatus:(NSString *)status
{
    if (status == nil)
    {
        status = @"未知";
    }
    
    static NSDictionary *colorMapping = nil;
    if (colorMapping == nil)
    {
        colorMapping = @{@"未知":[UIColor greenColor],
                         @"畅通":[UIColor greenColor],
                         @"缓行":[UIColor yellowColor],
                         @"拥堵":[UIColor redColor]};
    }
    
    return colorMapping[status] ?: [UIColor greenColor];
}
+ (NSString *)calcPointWithStartPoint:(NSString *)start endPoint:(NSString *)end rate:(double)rate
{
    if (rate > 1.0 || rate < 0)
    {
        return nil;
    }
    
    MAMapPoint from = MAMapPointForCoordinate([self coordinateWithString:start]);
    MAMapPoint to = MAMapPointForCoordinate([self coordinateWithString:end]);
    
    double latitudeDelta = (to.y - from.y) * rate;
    double longitudeDelta = (to.x - from.x) * rate;
    
    MAMapPoint newPoint = MAMapPointMake(from.x + longitudeDelta, from.y + latitudeDelta);
    
    CLLocationCoordinate2D coordinate = MACoordinateForMapPoint(newPoint);
    return [NSString stringWithFormat:@"%.6f,%.6f", coordinate.longitude, coordinate.latitude];
}

#pragma mark - colored route
+ (MAPolyline *)multiColoredPolylineWithDrivePath:(AMapPath *)path polylineColors:(NSArray **)polylineColors
{
    if(path == nil){
        return nil;
        
    }
    
    NSMutableArray *mutablePolylineColors = [NSMutableArray array];
    
    NSMutableArray *coordinates = [NSMutableArray array];
    NSMutableArray *indexes = [NSMutableArray array];
    
    NSMutableArray<AMapTMC *> *tmcs = [NSMutableArray array];
    
    
    NSMutableArray *coorArray = [NSMutableArray array];
    
    [path.steps enumerateObjectsUsingBlock:^(AMapStep * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [coorArray addObjectsFromArray:[self coordinateArrayWithPolylineString:obj.polyline]];
        
        
        [tmcs addObjectsFromArray:obj.tmcs];
    }];
    NSMutableArray *mergedTmcs = [NSMutableArray array];
    NSString *prevStatus = tmcs.firstObject.status;
    double sumDistance = 0;
    for(AMapTMC *tmc in tmcs)
    {
        
        if([prevStatus isEqualToString:tmc.status]){
            sumDistance += tmc.distance;
        }else{
            AMapTMC *temp = [[AMapTMC alloc] init];
            temp.status = prevStatus;
            temp.distance = sumDistance;
            [mergedTmcs addObject:temp];
            
            sumDistance = tmc.distance;
            prevStatus = tmc.status;
            
            
            
        }
    }
    AMapTMC *temp = [[AMapTMC alloc] init];
    temp.status = prevStatus;
    temp.distance = sumDistance;
    [mergedTmcs addObject:temp];
    
    tmcs = mergedTmcs;
    int i = 1;
    
    NSInteger sumLength = 0;
    NSInteger statusesIndex = 0;
    NSInteger curTrafficLength = tmcs.firstObject.distance;
    [mutablePolylineColors addObject:[self colorWithTrafficStatus:tmcs.firstObject.status]];
    [indexes addObject:@(0)];
    [coordinates addObject:[coorArray objectAtIndex:0]];
    for ( ;i < coorArray.count; ++i)
    {
        double oneDis = [self calcDistanceBetweenCoor:[self coordinateWithString:coorArray[i-1]] andCoor:[self coordinateWithString:coorArray[i]]];
        if (sumLength + oneDis >= curTrafficLength)
        {
            if (sumLength + oneDis == curTrafficLength)
            {
                [coordinates addObject:[coorArray objectAtIndex:i]];
                [indexes addObject:[NSNumber numberWithInteger:([coordinates count]-1)]];
            }
            else // 需要插入一个点
            {
                double rate = (oneDis == 0 ? 0 : ((curTrafficLength - sumLength) / oneDis));
                NSString *extrnPoint = [self calcPointWithStartPoint:[coorArray objectAtIndex:i-1] endPoint:[coorArray objectAtIndex:i] rate:MAX(MIN(rate, 1.0), 0)];
                if (extrnPoint)
                {
                    [coordinates addObject:extrnPoint];
                    [indexes addObject:[NSNumber numberWithInteger:([coordinates count]-1)]];
                    [coordinates addObject:[coorArray objectAtIndex:i]];
                }
                else
                {
                    [coordinates addObject:[coorArray objectAtIndex:i]];
                    [indexes addObject:[NSNumber numberWithInteger:([coordinates count]-1)]];
                }
                
            }
            
            sumLength = sumLength + oneDis - curTrafficLength;
            
            if (++statusesIndex >= [tmcs count])
            {
                break;
            }
            curTrafficLength = tmcs[statusesIndex].distance;
            [mutablePolylineColors addObject:[self colorWithTrafficStatus:tmcs[statusesIndex].status]];
        }
        else
        {
            [coordinates addObject:[coorArray objectAtIndex:i]];
            sumLength += oneDis;
        }
    } // end for
    
    //将最后一个点对齐到路径终点
    if (i < [coorArray count])
    {
        while (i < [coorArray count])
        {
            [coordinates addObject:[coorArray objectAtIndex:i]];
            i++;
        }
        
        [indexes removeLastObject];
        [indexes addObject:[NSNumber numberWithInteger:([coordinates count]-1)]];
    }
    
    //    NSArray *array2 = [indexes subarrayWithRange:NSMakeRange(0, 2000)];
    NSArray *array2 = indexes;
    // 添加overlay
    
    NSInteger count = coordinates.count;
    CLLocationCoordinate2D *runningCoords = (CLLocationCoordinate2D *)malloc(count * sizeof(CLLocationCoordinate2D));
    
    for (int j = 0; j < count; ++j)
    {
        NSString *oneCoor = coordinates[j];
        CLLocationCoordinate2D coor = [self coordinateWithString:oneCoor];
        runningCoords[j] = coor;
    }
    
    MAMultiPolyline *polyline = [MAMultiPolyline polylineWithCoordinates:runningCoords count:count drawStyleIndexes:array2];
    
    free(runningCoords);
    
    if (polylineColors)
    {
        *polylineColors = [mutablePolylineColors copy];
    }
    return polyline;
    
    
}

@end
