//
//  TrackerCustomAnnotationView.m
//  Tracker
//
//  Created by tanpeng on 2018/5/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "TrackerCustomAnnotationView.h"
#import "TrackerCustomCalloutView.h"
#import "TrackerQueryAddressInfoModel.h"

#define kCalloutWidth   200.0
#define kCalloutHeight  70.0

@interface TrackerCustomAnnotationView ()

@property(nonatomic,strong) TrackerQueryAddressInfoModel *addreessModel;

@property(nonatomic,copy) NSString *addressInfo;
@end


@implementation TrackerCustomAnnotationView

- (void)dealloc
{
  _addressInfo = nil;
  _addreessModel = nil;
}

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
  
  self = [super initWithAnnotation: annotation reuseIdentifier:reuseIdentifier];
  
  
  if(self){
   
        __weak typeof(self) weakSelf = self;
    _addreessModel = [[TrackerQueryAddressInfoModel alloc] init];
    _addreessModel.coordinate = annotation.coordinate;
    [_addreessModel setHandler:^(NSString *address) {
      
      [weakSelf operateAddress:address];
    }];
    [_addreessModel startQueryAddressInfo];
    
  }
  return self;
}

- (void)operateAddress:(NSString *)address
{
  if(address != nil){
    _addressInfo = [address copy];
  self.canShowCallout = NO;
    self.calloutOffset = CGPointMake(0, -5);
  }
}

-(void)setSelected:(BOOL)selected
{
  [self setSelected:selected animated:NO];
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  if(self.selected == selected){
    
    return;
  }
  if(self.canShowCallout == NO){
  
  if(selected){
   
    if(self.calloutView == nil){
      
      /* Construct custom callout. */
      self.calloutView = [[TrackerCustomCalloutView alloc] initWithFrame:CGRectMake(0, 0, kCalloutWidth, kCalloutHeight)];
      self.calloutView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x,
                                            -CGRectGetHeight(self.calloutView.bounds) / 2.f + self.calloutOffset.y);
      
     
      
      UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, kCalloutWidth-4, kCalloutHeight-4)];
      name.backgroundColor = [UIColor clearColor];
      name.textColor = [UIColor whiteColor];
      name.numberOfLines = 0;
      name.textAlignment = NSTextAlignmentCenter;
      name.text = _addressInfo;
      [self.calloutView addSubview:name];
    }
    [self addSubview:self.calloutView];
  }else{
    
    [self.calloutView removeFromSuperview];
  }
  }
  [super setSelected:selected animated:animated];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
