

//#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
//#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width

#import "RCTAMapManager.h"
#import "RCTAMap.h"
#import <React/RCTUIManager.h>
#import <React/RCTBridge.h>
#import "TrackerAddressAnnotation.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#if __has_include( <JSONKit/JSONKit.h>)
#import <JSONKit/JSONKit.h>
#else
#import "JSONKit.h"
#endif

#import "TrackerCustomAnnotationView.h"
#import "TrackerTimeHelper.h"
#import "TrackerPointAnnotation.h"
#import "TrackerNaviRoute.h"
#import "TrackerMapUtility.h"
#import "TrackerNaviAnnotation.h"
const NSInteger timeCheck=60*20*1; //时间判断,20分钟
const NSInteger distanceCheck=4000; //距离判断，汽车120km/h
@interface RCTAMapManager ()<MAMapViewDelegate,AMapSearchDelegate>
{
     CLLocationCoordinate2D * _runningCoords;
    
    
    NSString *currentDeviceTime;
}
@property (nonatomic, strong) AMapSearchAPI *search;
@property(nonatomic,strong) NSMutableArray *pointArray; //存储点
@property (nonatomic, strong) NSMutableArray *origOverlays; //划线
@property(nonatomic,weak) RCTAMap *currentMapView; //存储运动轨迹
@property(nonatomic,strong) MAAnimatedAnnotation *animatedAnnitation;
@property(nonatomic,strong) NSMutableArray *currentPosions;
@property(nonatomic,assign) NSInteger mode; //1 线 0点
@property(nonatomic,strong) TrackerNaviRoute *naviRoute;
@property(nonatomic,assign)  CLLocationCoordinate2D *moveCoordinates;
@property(nonatomic,strong)  MAMultiPolyline * polyline;
@end

@implementation RCTAMapManager
-(void)dealloc
{
    if(_moveCoordinates){
        free(_moveCoordinates);
    }
    if(_runningCoords){
        free(_runningCoords);
    }
}
RCT_EXPORT_MODULE(RCTAMap)

- (UIView *)view
{
//    RCTAMap *mapView = [[RCTAMap alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT)];
    RCTAMap *mapView = [[RCTAMap alloc] initWithManager:self];
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mapView.delegate = self;
    mapView.showsCompass=YES;
    mapView.showsUserLocation=NO;
    [mapView setShowsScale:NO];
  [mapView setZoomLevel:16.1];
    _currentMapView=mapView;
  _mode=1;
    return mapView;
}
#pragma mark-private method
-(AMapSearchAPI *)search
{
    if(_search == nil){
        _search = [[AMapSearchAPI alloc] init];
        _search.delegate = self;
    }
    return _search;
}
-(NSMutableArray *)currentPosions
{
  if(_currentPosions==nil){
    _currentPosions=[[NSMutableArray alloc] init];
  }
  return _currentPosions;
}
-(NSMutableArray *)pointArray
{
    if(_pointArray==nil){
        _pointArray=[NSMutableArray array];
    }
    return _pointArray;
}
-(NSMutableArray *)origOverlays
{
    if(_origOverlays==nil){
        _origOverlays=[NSMutableArray array];
    }
    return _origOverlays;
}
-(NSMutableArray *)centerAnnotations
{
  if(_centerAnnotations==nil){
    _centerAnnotations=[[NSMutableArray alloc] init];
  }
  return _centerAnnotations;
}
-(void)operateOrgPoints:(NSMutableArray *)points
{
  
    float  newLat = 0;//新的经纬度
    float  newLon = 0;
  
    
  
    NSMutableArray *arrForLocation5Min = [[NSMutableArray alloc] initWithCapacity:0];//5分钟时间的小段
  
  if(_moveCoordinates){
    free(_moveCoordinates);
  }
     _moveCoordinates = calloc(points.count, sizeof(CLLocationCoordinate2D));
      NSMutableArray *mArr = [NSMutableArray array];
    for(NSInteger i=0;i<points.count;i++)
    {
        
        NSDictionary *dic=[points objectAtIndex:i];
 
        newLat=[[dic objectForKey:@"lat"] floatValue];
        newLon=[[dic objectForKey:@"lng"] floatValue];
        if(newLat==0.0||newLon==0.0){
            continue;
        }
        CLLocationCoordinate2D coordata;
        coordata.latitude=newLat;
        coordata.longitude=newLon;
        TrackerPointAnnotation *anntation=[[TrackerPointAnnotation alloc]init];
        anntation.coordinate=[self covertCoordinateFromGPSToBaidu:newLat lon:newLon];
       _moveCoordinates[i] = anntation.coordinate;
        anntation.title=[dic objectForKey:@"eventTime"];
        anntation.tagNumber=i;
        [arrForLocation5Min addObject:anntation];
        MATracePoint *p = [[MATracePoint alloc] init];
        p.latitude = anntation.coordinate.latitude;
        p.longitude = anntation.coordinate.longitude;
        [mArr addObject:p];
      
    }
    if(mArr.count>0){
        MAMultiPolyline *polyline = [self makePolyLineWith:mArr];
        [self.origOverlays addObject:polyline];
    }
    [self.pointArray addObjectsFromArray:arrForLocation5Min];
}
-(void)addLineAndAnntation:(NSMutableArray *)arrForRecord
{
    NSInteger pointNum=0;
    if ([arrForRecord count]==0){
        return;
    }
    CLLocationCoordinate2D commuterLotCoords[[arrForRecord count]];
    float  rightLat= 0;//右侧的点的经纬度
    float  rightLon =0;
    NSMutableArray *arryForAnnotation=[NSMutableArray array];
        NSMutableArray *mArr = [NSMutableArray array];
    for(NSInteger i=0;i<arrForRecord.count;i++)
    {
        NSDictionary *dic=[arrForRecord objectAtIndex:i];
        rightLat=[[dic objectForKey:@"latitude"] floatValue];
        rightLon=[[dic objectForKey:@"longitude"] floatValue];
        CLLocationCoordinate2D coorData ;
        //CLLocationCoordinate2DMake(lat, lon);
        
        coorData =   [self covertCoordinateFromGPSToBaidu:rightLat lon:rightLon];
       
     
           MATracePoint *p = [[MATracePoint alloc] init];
        p.latitude = coorData.latitude;
        p.longitude = coorData.longitude;
        [mArr addObject:p];
        
        commuterLotCoords[i]=coorData;
        TrackerPointAnnotation *anntation=[[TrackerPointAnnotation alloc]init];
        anntation.coordinate=coorData;
        anntation.title=[dic objectForKey:@"eventTime"];
        anntation.tagNumber=pointNum;
        pointNum++;
        [arryForAnnotation addObject:anntation];
        
    }
    if(mArr.count>0){
      MAMultiPolyline *polyline = [self makePolyLineWith:mArr];
       [self.origOverlays addObject:polyline];
    }
    CLLocationCoordinate2D coor;
    coor.latitude=commuterLotCoords[0].latitude;
    coor.longitude=commuterLotCoords[0].longitude;
    //    if(self->map){
    //        self->map.centerCoordinate=coor;
    //    }
    [self.pointArray addObject:arryForAnnotation];
    
}
- (MAMultiPolyline *)makePolyLineWith:(NSArray<MATracePoint*> *)tracePoints
{
    CLLocationCoordinate2D *pCoords = malloc(sizeof(CLLocationCoordinate2D) * tracePoints.count);
    if(!pCoords) {
        return nil;
    }
    
    for(int i = 0; i < tracePoints.count; ++i) {
        MATracePoint *p = [tracePoints objectAtIndex:i];
        CLLocationCoordinate2D *pCur = pCoords + i;
        pCur->latitude = p.latitude;
        pCur->longitude = p.longitude;
    }
    
    MAMultiPolyline *polyline = [MAMultiPolyline polylineWithCoordinates:pCoords count:tracePoints.count drawStyleIndexes:@[@10, @60]];
    
    if(pCoords) {
        free(pCoords);
    }
    
    return polyline;
}
//坐标转换
-(CLLocationCoordinate2D )covertCoordinateFromToCOMMON:(float)lat lon:(float)lon {
    
    //NSLog(@"lat:%f---lon:%f",lat,lon);
    CLLocationCoordinate2D  gpsCoordinate= CLLocationCoordinate2DMake(lat, lon);
    return gpsCoordinate;
}

-(CLLocationCoordinate2D )covertCoordinateFromGPSToBaidu:(float)lat lon:(float)lon
{
    CLLocationCoordinate2D gpsCoordinate=CLLocationCoordinate2DMake(lat, lon);
    CLLocationCoordinate2D  baiduCoordinate=AMapCoordinateConvert(gpsCoordinate, AMapCoordinateTypeGPS);
    return baiduCoordinate;
}

RCT_EXPORT_VIEW_PROPERTY(onDidMoveByUser, RCTBubblingEventBlock)

RCT_CUSTOM_VIEW_PROPERTY(options, NSDictionary, RCTAMap) {
    NSDictionary *options = [RCTConvert NSDictionary:json];
    [self setMapViewOptions:view :options];
}

-(void)setMapViewOptions:(RCTAMap *)view :(nonnull NSDictionary *)options
{
    NSArray *keys = [options allKeys];
    
    //地图宽高设置
    if([keys containsObject:@"frame"]) {
        NSDictionary *frame = [options objectForKey:@"frame"];
        CGFloat width = [[frame objectForKey:@"width"] floatValue];
        CGFloat height = [[frame objectForKey:@"height"] floatValue];
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, width, height);
    }
    //地图类型，0为标准，1为卫星，默认为标准
    if([keys containsObject:@"mapType"]) {
        int mapType = [[options objectForKey:@"mapType"] intValue];
        view.mapType = mapType;
    }
//    是否显示路况，默认不显示
    if([keys containsObject:@"showTraffic"]) {
        BOOL showTraffic = [[options objectForKey:@"showTraffic"] boolValue];
        view.showTraffic = showTraffic;
    }
    //是否显示用户位置，默认显示
    if([keys containsObject:@"showsUserLocation"]) {
//        BOOL showsUserLocation = [[options objectForKey:@"showsUserLocation"] boolValue];
//        view.showsUserLocation = showsUserLocation;
    }
    //设置追踪用户位置更新的模式，默认不追踪
    if([keys containsObject:@"userTrackingMode"]) {
        int userTrackingMode = [[options objectForKey:@"userTrackingMode"] intValue];
        [view setUserTrackingMode:userTrackingMode animated:YES];
    }

    //指定缩放级别
    if([keys containsObject:@"zoomLevel"]) {
//        double zoomLevel = [[options objectForKey:@"zoomLevel"] doubleValue];
//        [view setZoomLevel:zoomLevel animated:NO];
    }

//    根据经纬度指定地图的中心点，并根据情况创建定位标记
    if([keys containsObject:@"centerCoordinate"]) {
//        NSDictionary *centerCoordinate = [options objectForKey:@"centerCoordinate"];
//        CGFloat latitude = [[centerCoordinate objectForKey:@"latitude"] floatValue];
//        CGFloat longitude = [[centerCoordinate objectForKey:@"longitude"] floatValue];
      
//        NSLog(@"latitude = %f, longitude = %f, ", latitude, longitude);
        
        //view.centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
//        [view setCenterCoordinate:CLLocationCoordinate2DMake(latitude, longitude) animated:YES];
        //    [view setZoomLevel:15 animated:true];
        
//        if(!view.hasUserLocationPointAnnotaiton) {
////            NSLog(@"draw userLocation annoation...");
//
//            view.hasUserLocationPointAnnotaiton = YES;
//            MAPointAnnotation *pointAnnotaiton = [[MAPointAnnotation alloc] init];
//            [pointAnnotaiton setCoordinate:view.centerCoordinate];
//            pointAnnotaiton.lockedToScreen = YES;
////            CGPoint screenPoint = [view convertCoordinate:view.centerCoordinate toPointToView:view];
//
////            if([keys containsObject:@"centerMarker"]) {
////                view.centerMarker = [options objectForKey:@"centerMarker"];
////
////                UIImage *image = [UIImage imageNamed:view.centerMarker];
////
////                //NSLog(@"screenPoint.x = %f, screenPoint.y = %f", screenPoint.x, screenPoint.y);
////
////                pointAnnotaiton.lockedScreenPoint = CGPointMake(screenPoint.x, screenPoint.y - image.size.height / 2);
////
////                //screenPoint.x = 183.129769, screenPoint.y = 126.198228
////
////                [view addAnnotation:pointAnnotaiton];
////            }
//        }
    }
}
RCT_EXPORT_METHOD(changeDianXianMod:(nonnull NSNumber *)reactTag mode:(nonnull NSNumber *)mode)
{
  self.mode=[mode integerValue];
}
RCT_EXPORT_METHOD(setHuiFangSpeed:(nonnull NSNumber *)reactTag duration:(nonnull NSNumber *)duration)
{
    __weak typeof(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
    
    
    if(weakSelf.animatedAnnitation){
        
      for(MAAnnotationMoveAnimation *animation in [weakSelf.animatedAnnitation allMoveAnimations]) {
        [animation cancel];
      }
        if(duration.floatValue>0){
      weakSelf.animatedAnnitation.movingDirection = 0;
      weakSelf.animatedAnnitation.coordinate = weakSelf.moveCoordinates[0];
       
      [weakSelf.animatedAnnitation addMoveAnimationWithKeyCoordinates:weakSelf.moveCoordinates count:weakSelf.pointArray.count withDuration:duration.floatValue withName:nil completeCallback:^(BOOL isFinished) {
        
      }];
        }
    }
  }];
 
}
RCT_EXPORT_METHOD(moveMarker:(nonnull NSNumber *)reactTag mode:(nonnull NSNumber *)mode)
{
    __weak typeof(self) weakSelf = self;
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        if([mode integerValue]<=0){
            
            if(weakSelf.animatedAnnitation){
                
                for(MAAnnotationMoveAnimation *animation in [weakSelf.animatedAnnitation allMoveAnimations]) {
                    [animation cancel];
                }
               
            
        }
        }
        
     
    }];
}

RCT_EXPORT_METHOD(fitMap:(nonnull NSNumber *)reactTag points:(NSString *)points fitType:(nonnull NSNumber *)fitType)
{
     __weak typeof(self) weakSelf = self;
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        
   
        id view = viewRegistry[reactTag];
        RCTAMap *mapView = (RCTAMap *)view;
        NSArray *pointAry = [points objectFromJSONString];
        
        if(pointAry&&[pointAry isKindOfClass:[NSArray class]]&&pointAry.count>0){
            
            NSDictionary *pointDic1 = [pointAry objectAtIndex:0];
            NSNumber *latNum  = [pointDic1 objectForKey:@"latitude"];
            NSNumber *lngNum = [pointDic1 objectForKey:@"longitude"];
            if([latNum respondsToSelector:@selector(doubleValue)]&&[lngNum respondsToSelector:@selector(doubleValue)]){
                
                if(pointAry.count == 1){
                    
                    CLLocationCoordinate2D centerPosition = [weakSelf covertCoordinateFromToCOMMON:[latNum doubleValue] lon:[lngNum doubleValue]];
                    [mapView setCenterCoordinate:centerPosition animated:YES];
                }else{
                    
                  
                      TrackerNowLocationAnnotation *nowLocation=[[TrackerNowLocationAnnotation alloc]init];
                      nowLocation.coordinate = CLLocationCoordinate2DMake([latNum doubleValue], [lngNum doubleValue]);
                

                    NSDictionary *pointDic2 = [pointAry objectAtIndex:1];
                    latNum  = [pointDic2 objectForKey:@"latitude"];
                    lngNum = [pointDic2 objectForKey:@"longitude"];
                    TrackerNowLocationAnnotation *devicePosition=[[TrackerNowLocationAnnotation alloc]init];
                    devicePosition.coordinate = [weakSelf covertCoordinateFromToCOMMON:[latNum doubleValue] lon:[lngNum doubleValue]];;
                    NSLog(@"%@fitMap1------%@fitMap2",pointDic1,pointDic2);
                 
                    MAMapPoint point[2];
                  point[0]= MAMapPointForCoordinate(nowLocation.coordinate);
                  
                    point[1]= MAMapPointForCoordinate(devicePosition.coordinate);
                    MAPolyline *line = [MAPolyline polylineWithPoints:point count:2];
//                    MAMapRect mapRect = [TrackerMapUtility minMapRectForAnnotations:[NSArray arrayWithObjects:devicePosition,nowLocation, nil]];
                    MAMapRect mapRect = [TrackerMapUtility mapRectForOverlays:[NSArray arrayWithObject:line]];
                    [mapView setVisibleMapRect:mapRect edgePadding:UIEdgeInsetsMake(50, 50, 50, 100) animated:YES];
                    
                }
                
                
                
            }
        
           
            
            
        }
        
    }];
    
    
}

RCT_EXPORT_METHOD(guiJiHuiFang:(nonnull NSNumber *)reactTag points:(NSString *)points duration:(nonnull NSNumber *)duration)
{
     __weak typeof(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
    id view = viewRegistry[reactTag];
    RCTAMap *mapView = (RCTAMap *)view;
    NSArray *lines=[points objectFromJSONString];
    
    if(lines&&[lines isKindOfClass:[NSArray class]]&&lines.count>0){
      NSMutableArray *mutableLine=[NSMutableArray arrayWithArray:lines];
       [mapView removeOverlays:weakSelf.origOverlays];
        [mapView removeAnnotations:weakSelf.pointArray];
      [weakSelf.pointArray removeAllObjects];
      [weakSelf.origOverlays removeAllObjects];
      [weakSelf operateOrgPoints:mutableLine];
      
      if(weakSelf.pointArray.count>0){
        //                    NSArray *arrPoint=[self.pointArray objectAtIndex:0];
        
        
        
        if(weakSelf.mode==0){
         
          [mapView addAnnotations:weakSelf.pointArray];
            MAMapRect   mapRect  =    [TrackerMapUtility minMapRectForAnnotations:weakSelf.pointArray];
            [mapView setVisibleMapRect:mapRect edgePadding:UIEdgeInsetsMake(50, 50, 50, 50) animated:NO];
          //                        [mapView showAnnotations:self.pointArray animated:NO];
          
        }else{
        MAMapRect   mapRect  =    [TrackerMapUtility mapRectForOverlays:weakSelf.origOverlays];
          [mapView addOverlays:weakSelf.origOverlays];
           [mapView setVisibleMapRect:mapRect edgePadding:UIEdgeInsetsMake(50, 50, 50, 50) animated:NO];
          if(weakSelf.animatedAnnitation == nil){
            
            weakSelf.animatedAnnitation = [[MAAnimatedAnnotation alloc] init];
            
            
          }else{
            
            [mapView removeAnnotation:weakSelf.animatedAnnitation];
            for(MAAnnotationMoveAnimation *animation in [weakSelf.animatedAnnitation allMoveAnimations]) {
              [animation cancel];
            }
            
           
          }
          ;
          
          weakSelf.animatedAnnitation.coordinate = weakSelf.moveCoordinates[0];
          [mapView addAnnotation:weakSelf.animatedAnnitation];
          
          [weakSelf.animatedAnnitation addMoveAnimationWithKeyCoordinates:weakSelf.moveCoordinates count:weakSelf.pointArray.count withDuration:duration.floatValue withName:nil completeCallback:^(BOOL isFinished) {
            
          }];
          
         
        }
        
        
        
      
        
        
        
        
      }
    }
    
  }];
}


RCT_EXPORT_METHOD(addGpsMarker:(nonnull NSNumber *)reactTag mark:(nonnull NSDictionary*)coordinate)
{
    __weak typeof(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
    id view = viewRegistry[reactTag];
    RCTAMap *mapView = (RCTAMap *)view;
    NSLog(@"%@----GPSMarker",coordinate);
    double latitude = [[coordinate objectForKey:@"latitude"] doubleValue];
    double longitude = [[coordinate objectForKey:@"longitude"] doubleValue];
    NSNumber *modeNum=[coordinate objectForKey:@"markerPicId"];
    NSString *eventTime=[coordinate objectForKey:@"eventTime"];
    

    CLLocationCoordinate2D location = [weakSelf covertCoordinateFromToCOMMON:latitude lon:longitude];;
//    location.latitude = latitude;
//    location.longitude = longitude;
    
    TrackerNowLocationAnnotation *nowLocation=[[TrackerNowLocationAnnotation alloc]init];
    //            nowLocation.title=@"设备当前位置";
    if(eventTime){
      nowLocation.title=eventTime;
    }
    if(modeNum){
      nowLocation.mode=[modeNum integerValue];
    }
    nowLocation.coordinate=location;
    [weakSelf.centerAnnotations addObject:nowLocation];
    [mapView addAnnotation:nowLocation];
    [mapView setCenterCoordinate:location animated:NO];
      [mapView selectAnnotation:nowLocation animated:YES];
  
  }];
}
RCT_EXPORT_METHOD(setOptions:(nonnull NSNumber *)reactTag :(nonnull NSDictionary *)options)
{
    __weak typeof(self) weakSelf = self;
//    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            RCTAMap *mapView = (RCTAMap *)view;
            [weakSelf setMapViewOptions:mapView :options];
        }];
//    });

    
    
}

RCT_EXPORT_METHOD(destoryMap:(nonnull NSNumber *)reactTag)
{
   
//    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            RCTAMap *mapView = (RCTAMap *)view;
            mapView.delegate=nil;
            //            [mapView removeAnnotations:map.annotations];
            //            [mapView removeOverlays:map.overlays];
            mapView=nil;
        }];
//    });
  
}




RCT_EXPORT_METHOD(setCenterCoordinate:(nonnull NSNumber *)reactTag centerCoordinate:(nonnull NSDictionary *)coordinate)
{
    __weak typeof(self) weakSelf = self;
//    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            RCTAMap *mapView = (RCTAMap *)view;
            double latitude = [[coordinate objectForKey:@"latitude"] doubleValue];
            double longitude = [[coordinate objectForKey:@"longitude"] doubleValue];
            CLLocationCoordinate2D location=[weakSelf covertCoordinateFromGPSToBaidu:latitude lon:longitude ];
            
            
            
            [mapView setCenterCoordinate:location animated:NO];
            
        }];
//    });
  
}

-(NSMutableArray *)lineArray
{
    if(_lineArray==nil){
        _lineArray=[NSMutableArray array];
    }
    return _lineArray;
}
RCT_EXPORT_METHOD(addDetailMarker:(nonnull NSNumber *)reactTag mark:(nonnull NSDictionary*)coordinate)

{
    __weak typeof(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
    id view = viewRegistry[reactTag];
    RCTAMap *mapView = (RCTAMap *)view;
    
      NSNumber *latiNum = [coordinate objectForKey:@"latitude"];
      NSNumber *longNum = [coordinate objectForKey:@"longitude"];
      if([latiNum respondsToSelector:@selector(doubleValue)]&&[longNum respondsToSelector:@selector(doubleValue)]){
 
          double latitude = [latiNum doubleValue];
          double longitude = [longNum doubleValue];
//          NSNumber *modeNum=[coordinate objectForKey:@"markerPicId"];
          NSString *eventTime=[coordinate objectForKey:@"eventTime"];
          NSString *tip = [coordinate objectForKey:@"tip"];
          
          CLLocationCoordinate2D location=[weakSelf covertCoordinateFromGPSToBaidu:latitude lon:longitude ];
//
//          TrackerAddressAnnotation *nowLocation=[[TrackerAddressAnnotation alloc]init];
//
//          if(eventTime){
//              nowLocation.title=eventTime;
//          }
//
//          nowLocation.coordinate=location;
//          [weakSelf.centerAnnotations addObject:nowLocation];
//          [mapView addAnnotation:nowLocation];
//           [mapView selectAnnotation:nowLocation animated:YES];
//          [mapView setCenterCoordinate:location animated:NO];
          TrackerNowLocationAnnotation *nowLocation=[[TrackerNowLocationAnnotation alloc]init];
          
          if(eventTime){
              
              nowLocation.title=eventTime;
          }
          if(tip){
              nowLocation.title = tip;
              
          }
          nowLocation.coordinate=location;
          [weakSelf.centerAnnotations addObject:nowLocation];
          [mapView addAnnotation:nowLocation];
          [mapView selectAnnotation:nowLocation animated:YES];
          [mapView setCenterCoordinate:location animated:NO];
         
          
      }
    
    
    
  }];
}
RCT_EXPORT_METHOD(addMarker:(nonnull NSNumber *)reactTag mark:(nonnull NSDictionary*)coordinate)
{
__weak typeof(self) weakSelf = self;
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            RCTAMap *mapView = (RCTAMap *)view;
      
            double latitude = [[coordinate objectForKey:@"latitude"] doubleValue];
            double longitude = [[coordinate objectForKey:@"longitude"] doubleValue];
          NSNumber *modeNum=[coordinate objectForKey:@"markerPicId"];
          NSString *eventTime=[coordinate objectForKey:@"eventTime"];
          

            CLLocationCoordinate2D location=[weakSelf covertCoordinateFromGPSToBaidu:latitude lon:longitude ];
          
            TrackerNowLocationAnnotation *nowLocation=[[TrackerNowLocationAnnotation alloc]init];

          if(eventTime){
            
            nowLocation.title=eventTime;
          }
          if(modeNum){
            nowLocation.mode=[modeNum integerValue];
              if([modeNum integerValue] == 4){
                  nowLocation.title = @"当前所处位置";
              }
          }
            nowLocation.coordinate=location;
          [weakSelf.centerAnnotations addObject:nowLocation];
            [mapView addAnnotation:nowLocation];
            [mapView selectAnnotation:nowLocation animated:YES];
            [mapView setCenterCoordinate:location animated:NO];
          
 
        }];

  
}
/*规划驾车路线*/
RCT_EXPORT_METHOD(daoHang:(nonnull NSNumber *)reactTag points:(NSString *)points)
{
    __weak typeof(self) weakSelf = self;
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
//        id view = viewRegistry[reactTag];
//        RCTAMap *mapView = (RCTAMap *)view;
    
        NSArray *pointAry = [points objectFromJSONString];
        if([pointAry isKindOfClass:[NSArray class]]&&pointAry.count==2){
            
            
            NSDictionary *beginCoor = pointAry[0];
            NSDictionary *desCoor = pointAry[1];
            double latitude = [[beginCoor objectForKey:@"latitude"] doubleValue];
            double longitude = [[beginCoor objectForKey:@"longitude"] doubleValue];
            AMapDrivingRouteSearchRequest * navi = [[AMapDrivingRouteSearchRequest alloc] init];
            navi.requireExtension = YES;
            navi.origin = [AMapGeoPoint locationWithLatitude:latitude longitude:longitude];
            
             latitude = [[desCoor objectForKey:@"latitude"] doubleValue];
             longitude = [[desCoor objectForKey:@"longitude"] doubleValue];
            navi.destination = [AMapGeoPoint locationWithLatitude:latitude longitude:longitude];
            
            [weakSelf.search AMapDrivingRouteSearch:navi];
        }
       
        
        
    }];
}
/* 根据坐标画折线. */
RCT_EXPORT_METHOD(showGuiJi:(nonnull NSNumber *)reactTag points:(NSString *)points)
{
__weak typeof(self) weakSelf = self;
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        RCTAMap *mapView = (RCTAMap *)view;
        NSArray *lines=[points objectFromJSONString];
        if(lines&&[lines isKindOfClass:[NSArray class]]&&lines.count>0){
            NSMutableArray *mutableLine=[NSMutableArray arrayWithArray:lines];
            [weakSelf.pointArray removeAllObjects];
            [weakSelf.origOverlays removeAllObjects];
            [mapView removeOverlays:self.origOverlays];
            [mapView removeAnnotations:self.pointArray];
            
            [weakSelf operateOrgPoints:mutableLine];
            
            if(self.pointArray.count>0){
                
                if(weakSelf.mode==0){
                    
                    [mapView addAnnotations:weakSelf.pointArray];
                    
                    MAMapRect rect = [TrackerMapUtility minMapRectForAnnotations:weakSelf.pointArray];
                    
                    [mapView setVisibleMapRect:rect animated:YES];
                    
                }else{
                    
                    
                    MAPolyline *polyline = [weakSelf.origOverlays objectAtIndex:0];
                    
                    [mapView addOverlay:polyline];
                    
                    
                    
                    
                    
                    [mapView setVisibleMapRect:polyline.boundingMapRect animated:YES];
                    
                    
                }
                
                
                
            }
        }
        
    }];

    
}
RCT_EXPORT_METHOD(getMapViewRange:(nonnull NSNumber *)reactTag coordinate:(nonnull NSDictionary*)coordinate callback:(nonnull RCTResponseSenderBlock)callback)
{
//  dispatch_async(self.bridge.uiManager.methodQueue,^{
    __weak typeof(self) weakSelf = self;
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
      id view = viewRegistry[reactTag];
      RCTAMap *mapView = (RCTAMap *)view;
      MAMapRect mapRect= mapView.visibleMapRect;
      double northeastlat=mapRect.origin.x;
      double northeastlon=mapRect.origin.y;
      double southwestlat=mapRect.origin.x+mapRect.size.width;
      double southwestlon=mapRect.origin.y+mapRect.size.height;
      NSMutableDictionary *rectDic=[NSMutableDictionary dictionary];
      [rectDic setObject:[NSString stringWithFormat:@"%f",northeastlat] forKey:@"northeastlat"];
      [rectDic setObject:[NSString stringWithFormat:@"%f",northeastlon] forKey:@"northeastlon"];
      [rectDic setObject:[NSString stringWithFormat:@"%f",southwestlat] forKey:@"southwestlat"];
      [rectDic setObject:[NSString stringWithFormat:@"%f",southwestlon] forKey:@"southwestlon"];
     
      double latitude = [[coordinate objectForKey:@"latitude"] doubleValue];
      double longitude = [[coordinate objectForKey:@"longitude"] doubleValue];
      CLLocationCoordinate2D location=[weakSelf covertCoordinateFromGPSToBaidu:latitude lon:longitude ];
      double resultLat=location.latitude;
      double resultLon=location.longitude;
      NSMutableDictionary *resultDic=[NSMutableDictionary dictionary];
      [resultDic setObject:[NSString stringWithFormat:@"%f",resultLat] forKey:@"latitude"];
        [resultDic setObject:[NSString stringWithFormat:@"%f",resultLon] forKey:@"longitude"];
      NSMutableArray *resultAry=[NSMutableArray array];
      [resultAry addObject:resultDic];
      [resultAry addObject:rectDic];
      NSString *rectJson=[resultAry JSONString];
      if(rectJson){
        callback(@[rectJson,[NSNull null]]);
      }else{
        callback(@[[NSNull null],@"未获取到可视区域"]);
      }
    }];
//  });
}
RCT_EXPORT_METHOD(removeMarker:(nonnull NSNumber *)reactTag coordinate:(nonnull NSDictionary*)coordinate)
{
    __weak typeof(self) weakSelf = self;
//  dispatch_async(self.bridge.uiManager.methodQueue,^{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
      id view = viewRegistry[reactTag];
      RCTAMap *mapView = (RCTAMap *)view;
      for(TrackerNowLocationAnnotation *nowAnnotation in weakSelf.centerAnnotations){
        CLLocationCoordinate2D position=nowAnnotation.coordinate;
        if([coordinate isKindOfClass:[NSDictionary class]]){
          double lati=[[coordinate objectForKey:@"latitude"] doubleValue];
          double longti=[[coordinate objectForKey:@"longitude"] doubleValue];
          if((position.latitude==lati)&&(position.longitude==longti)){
            [mapView removeAnnotation:nowAnnotation];
            break;
          }
        }
        
      }
    }];
//  });
}
RCT_EXPORT_METHOD(pureDrawLine:(nonnull NSNumber *)reactTag points:(NSString *)points)
{
    __weak typeof(self) weakSelf = self;
//  dispatch_async(self.bridge.uiManager.methodQueue,^{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
      id view = viewRegistry[reactTag];
      RCTAMap *mapView = (RCTAMap *)view;
      NSArray *ary=[points objectFromJSONString];
      if(ary&&[ary isKindOfClass:[NSArray class]]&&ary.count==2){
        NSDictionary *beginPoint=[ary objectAtIndex:0];
        NSDictionary *endPoint=[ary objectAtIndex:1];
        CLLocationCoordinate2D coords[2];
      float  rightLat=[[beginPoint objectForKey:@"latitude"] floatValue];
       float rightLon=[[beginPoint objectForKey:@"longitude"] floatValue];
        CLLocationCoordinate2D beginPosition=[weakSelf covertCoordinateFromToCOMMON:rightLat lon:rightLon];
        coords[0]=beginPosition;
          rightLat=[[endPoint objectForKey:@"latitude"] floatValue];
         rightLon=[[endPoint objectForKey:@"longitude"] floatValue];
        CLLocationCoordinate2D endPosition=[weakSelf covertCoordinateFromToCOMMON:rightLat lon:rightLon];
        coords[1]=endPosition;
          MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coords count:sizeof(coords) / sizeof(coords[0])];
        
        [weakSelf.currentPosions addObject: polyline];
        [mapView addOverlay:polyline];
      }
      
    }];
//  });
}
RCT_EXPORT_METHOD(moveToCoordinate:(nonnull NSNumber *)reactTag coordinate:(nonnull NSDictionary*)coordinate)
{
  
}
RCT_EXPORT_METHOD(cleanGuiJi:(nonnull NSNumber *)reactTag){
    __weak typeof(self) weakSelf = self;
//    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            RCTAMap *mapView = (RCTAMap *)view;
            [mapView removeAnnotations:mapView.annotations];
        
            [mapView removeOverlays:weakSelf.origOverlays];
            [mapView removeOverlays:weakSelf.currentPosions];
            [weakSelf.origOverlays removeAllObjects];
            [weakSelf.pointArray removeAllObjects];
           [weakSelf.currentPosions removeAllObjects];
          [weakSelf.centerAnnotations removeAllObjects];
        }];
//    });
  
}
RCT_EXPORT_METHOD(changeMapMode:(nonnull NSNumber *)reactTag mode:(NSNumber *)mode){
//    dispatch_async(self.bridge.uiManager.methodQueue,^{
   
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            RCTAMap *mapView = (RCTAMap *)view;
            NSInteger modeType=[mode integerValue];
            mapView.mapType = modeType ==1 ? 1 : 0;
        }];
//    });
}

- (NSDictionary *)constantsToExport
{
    return @{
             @"userTrackingMode": @{
                     @"none": @(MAUserTrackingModeNone),
                     @"follow": @(MAUserTrackingModeFollow),
                     @"followWithHeading": @(MAUserTrackingModeFollowWithHeading)
                     }
             };
}


#pragma mark - Map Delegate


#pragma mark - Map Delegate

- (void)mapView:(RCTAMap *)mapView mapDidMoveByUser:(BOOL)wasUserAction {
    if(mapView.onDidMoveByUser) {
        mapView.onDidMoveByUser(@{
                                  @"data": @{
                                          @"centerCoordinate": @{
                                                  @"latitude": @(mapView.centerCoordinate.latitude),
                                                  @"longitude": @(mapView.centerCoordinate.longitude),
                                                  }
                                          },
                                  });
    }
}
- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    
}


- (MAAnnotationView*)mapView:(RCTAMap *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
    
    
    if([annotation isKindOfClass:[TrackerPointAnnotation class]]){
        static NSString *identifier1=@"MKAnnotationView";
        TrackerPointAnnotation *trackerannotation=(TrackerPointAnnotation *)annotation;
        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier1];
        if(annotationView==nil){
            annotationView =[[MAPinAnnotationView alloc]initWithAnnotation:trackerannotation reuseIdentifier:identifier1];
        }
        
        if( trackerannotation.tagNumber+1==(self.pointArray.count)){
            
            annotationView.image = [UIImage imageNamed:@"guiji_3"];
            
            
        } else if (trackerannotation.tagNumber==0){
            annotationView.image = [UIImage imageNamed:@"guiji_1"];
        }
        else{
            annotationView.image = [UIImage imageNamed:@"guiji_2"];
            
        }
        annotationView.annotation=(TrackerPointAnnotation *)annotation;
        annotationView.draggable=NO;
        annotationView.canShowCallout=YES;
        
        return annotationView;
        
    }
    if([annotation isKindOfClass:[TrackerNowLocationAnnotation class]]){
        TrackerNowLocationAnnotation *nowLocation=(TrackerNowLocationAnnotation *)annotation;
        static NSString *identifier2=@"nowlocationAnno";
        MAPinAnnotationView *annotionView=(MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier2];
        if(annotionView==nil){
            annotionView=[[MAPinAnnotationView alloc]initWithAnnotation:nowLocation reuseIdentifier:identifier2];
        }
     
      if(nowLocation.mode==1){
        annotionView.image=[UIImage imageNamed:@"curpos.png"];
      }else if (nowLocation.mode==2){
         annotionView.image=[UIImage imageNamed:@"guiji_1.png"];
      }else if (nowLocation.mode==3){
            annotionView.image=[UIImage imageNamed:@"guiji_3.png"];
      }else if (nowLocation.mode==4){
              annotionView.image=[UIImage imageNamed:@"userPosition.png"];
      }else if (nowLocation.mode==5){
         annotionView.image=[UIImage imageNamed:@"huisetubiao.png"];
      }else if(nowLocation.mode == 7){
           annotionView.image=[UIImage imageNamed:@"position_now.png"];
      }
      
        annotionView.draggable=NO;
      
        annotionView.canShowCallout=YES;
        return annotionView;
    }
  
  if([annotation isKindOfClass:[TrackerAddressAnnotation class]]){
    
    
    TrackerAddressAnnotation *addressAnnotation = (TrackerAddressAnnotation *)annotation;
     static NSString *identifier3=@"addressAnno";
    
    TrackerCustomAnnotationView *addressAnnoView = (TrackerCustomAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier3];
    
    if(addressAnnoView == nil){
      
      addressAnnoView =  [[TrackerCustomAnnotationView alloc] initWithAnnotation:addressAnnotation reuseIdentifier:identifier3];
    }
    
    addressAnnoView.draggable = NO;
    addressAnnoView.canShowCallout = YES;
       addressAnnoView.image=[UIImage imageNamed:@"curpos.png"];
    return addressAnnoView;
  }
  
  
  
  
  if([annotation isKindOfClass:[MAAnimatedAnnotation class]]){
    NSString *pointReuseIndetifier = @"myReuseIndetifier";
    MAAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
    if (annotationView == nil)
    {
      annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                    reuseIdentifier:pointReuseIndetifier];
      
      UIImage *imge  =  [UIImage imageNamed:@"electrombile.png"];
      annotationView.image =  imge;
    }
    
    annotationView.canShowCallout               = YES;
    annotationView.draggable                    = NO;
    annotationView.rightCalloutAccessoryView    = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    return annotationView;
  }
    return nil;
}
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
  
//    if ([overlay isKindOfClass:[MAMultiPolyline class]]){
//      MAPolylineRenderer *polylineView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
//        polylineView.lineWidth=8.f;
//        polylineView.strokeColor= [UIColor blueColor];
//         return polylineView;
//    }
  if([overlay isKindOfClass:[MAPolyline class]]){
    MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
    polylineRenderer.lineWidth    = 8.f;
    polylineRenderer.strokeImage=[UIImage imageNamed:@"arrowTexture.png"];
    return polylineRenderer;
  }
    return nil;
}


- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view didChangeDragState:(MAAnnotationViewDragState)newState fromOldState:(MAAnnotationViewDragState)oldState{
    
}
#pragma mark - AMapSearchDelegate
/* 搜索失败回调. */
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
//    NSLog(@"Error: %@", error);
    NSDictionary *result;
    result = @{
               @"error": @{
                            @"code": @(error.code),
                            @"localizedDescription": error.localizedDescription
                          }
               };
//    [self.bridge.eventDispatcher sendAppEventWithName:@"amap.onPOISearchFailed"
//                                                 body:result];
    [self.bridge.eventDispatcher sendAppEventWithName:@"amap.onPOISearchDone"
                                                 body:result];
}


/* 逆地理编码回调. */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(request.location.latitude, request.location.longitude);
       NSString *title=currentDeviceTime;
    NSString *subTitle=  [NSString stringWithFormat:@"%@%@%@%@%@",
                          response.regeocode.addressComponent.city?: @"",
                          response.regeocode.addressComponent.district?: @"",
                          response.regeocode.addressComponent.township?: @"",
                          response.regeocode.addressComponent.neighborhood?: @"",
                          response.regeocode.addressComponent.building?: @""];
   
    
        
   
                TrackerNowLocationAnnotation *nowLocation=[[TrackerNowLocationAnnotation alloc]init];
                nowLocation.title=title;
    nowLocation.subtitle=subTitle;
                nowLocation.coordinate=coordinate;
                [_currentMapView addAnnotation:nowLocation];
    
                [_currentMapView setCenterCoordinate:coordinate animated:NO];
}

/* POI 搜索回调. */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
//    NSLog(@"ios onPOISearchDone...");
    
    NSDictionary *result;
    NSMutableArray *resultList;
    resultList = [NSMutableArray arrayWithCapacity:response.pois.count];
    if (response.pois.count > 0)
    {
        [response.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
            
            [resultList addObject:@{
                                    @"uid": obj.uid,
                                    @"name": obj.name,
                                    @"type": obj.type,
                                    @"typecode": obj.typecode,
                                    @"latitude": @(obj.location.latitude),
                                    @"longitude": @(obj.location.longitude),
                                    @"address": obj.address,
                                    @"tel": obj.tel,
                                    @"distance": @(obj.distance)
                                    }];
            
        }];
    }
    result = @{
                 @"searchResultList": resultList
                 };
    [self.bridge.eventDispatcher sendAppEventWithName:@"amap.onPOISearchDone"
                                                 body:result];
}
-(void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
{
    if(response.route == nil){
        return;
    }
    if(response.count>0){
        AMapRoute *route = response.route;
        AMapGeoPoint *beginPoint = route.origin;
        AMapGeoPoint *desPoint = route.destination;
        TrackerNowLocationAnnotation * beginAnno = [[TrackerNowLocationAnnotation alloc] init];
        beginAnno.mode = 2;
        CLLocationCoordinate2D beginCoor;
        beginCoor.latitude = beginPoint.latitude;
        beginCoor.longitude = beginPoint.longitude;
        beginAnno.coordinate = beginCoor;
        TrackerNowLocationAnnotation * desAnno = [[TrackerNowLocationAnnotation alloc] init];
        desAnno.mode = 3;
        CLLocationCoordinate2D desCoor;
        desCoor.latitude = desPoint.latitude;
        desCoor.longitude = desPoint.longitude;
        desAnno.coordinate = desCoor;
        [_currentMapView addAnnotation:beginAnno];
        [_currentMapView addAnnotation:desAnno];
        AMapPath *path = route.paths[0];
        self.naviRoute = [TrackerNaviRoute naviRouteForPath:path withNaviType:MANaviAnnotationTypeDrive showTraffic:YES startPoint:beginPoint endPoint:desPoint];
        [self.naviRoute addToMapView:_currentMapView];
        [_currentMapView setVisibleMapRect:[TrackerMapUtility mapRectForOverlays:self.naviRoute.routePolylines] edgePadding:UIEdgeInsetsMake(20, 20, 20, 20) animated:YES];
       
        
    }
    
    
}

@end
