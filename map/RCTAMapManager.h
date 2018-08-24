#import <React/RCTViewManager.h>
#import "TrackerNowLocationAnnotation.h"
@interface RCTAMapManager : RCTViewManager
{
   
}
@property(nonatomic,strong) NSMutableArray *lineArray;
@property(nonatomic,strong) TrackerNowLocationAnnotation *centerAnnotation;
@property(nonatomic,strong) NSMutableArray *centerAnnotations;
@end

