//
//  TrackerNaviAnnotation.h
//  Tracker
//
//  Created by tanpeng on 2018/7/28.
//  Copyright © 2018年 Study. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
typedef NS_ENUM(NSInteger, MANaviAnnotationType)
{
    MANaviAnnotationTypeDrive = 0,
    MANaviAnnotationTypeWalking = 1,
    MANaviAnnotationTypeBus = 2,
    MANaviAnnotationTypeRailway = 3,
    MANaviAnnotationTypeRiding = 4,
    MANaviAnnotationTypeTruck = 5
};
@interface TrackerNaviAnnotation : MAPointAnnotation
@property (nonatomic,assign) MANaviAnnotationType type;
@end
