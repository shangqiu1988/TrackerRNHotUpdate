//
//  TrackerCustomCalloutView.m
//  Tracker
//
//  Created by tanpeng on 2018/5/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "TrackerCustomCalloutView.h"
#import <QuartzCore/QuartzCore.h>

#define kArrorHeight    10
@implementation TrackerCustomCalloutView
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
  }
  return self;
}

#pragma mark - draw rect

- (void)drawRect:(CGRect)rect
{
  
  [self drawInContext:UIGraphicsGetCurrentContext()];
  
  self.layer.shadowColor = [[UIColor blackColor] CGColor];
  self.layer.shadowOpacity = 1.0;
  self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  
}

- (void)drawInContext:(CGContextRef)context
{
  
  CGContextSetLineWidth(context, 2.0);
  CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8].CGColor);
  
  [self getDrawPath:context];
  CGContextFillPath(context);
  
}

- (void)getDrawPath:(CGContextRef)context
{
  CGRect rrect = self.bounds;
  CGFloat radius = 6.0;
  CGFloat minx = CGRectGetMinX(rrect),
  midx = CGRectGetMidX(rrect),
  maxx = CGRectGetMaxX(rrect);
  CGFloat miny = CGRectGetMinY(rrect),
  maxy = CGRectGetMaxY(rrect)-kArrorHeight;
  
  CGContextMoveToPoint(context, midx+kArrorHeight, maxy);
  CGContextAddLineToPoint(context,midx, maxy+kArrorHeight);
  CGContextAddLineToPoint(context,midx-kArrorHeight, maxy);
  
  CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
  CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
  CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
  CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
  CGContextClosePath(context);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
