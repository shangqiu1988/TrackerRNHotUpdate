//
//  UXinHotUpdateVersionCheck.m
//  NewUXin
//
//  Created by tanpeng on 2017/11/6.
//  Copyright © 2017年 Study. All rights reserved.
//

#import "UXinHotUpdateVersionCheck.h"

@implementation UXinHotUpdateVersionCheck
-(void)dealloc
{
  _handler=nil;
}
-(instancetype)init
{
  self=[super init];
  if(self){
    
  }
  return self;
}
- (void)getVersionInfo:(NSURL *)url
     completionHandler:(completionhandler)completionHandler
{
 
    _handler = [completionHandler copy];
    [self sendCheckRequest:url];
    
}
-(void)sendCheckRequest:(NSURL *)url
{
  NSLog(@"%@---",url);
       __weak typeof(self) weakSelf = self;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task=[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
      if(data==nil){
        
        weakSelf.handler(nil, error);
        return ;
      }
        NSDictionary *dic =  [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
      NSLog(@"%@-----",dic);
        if([dic isKindOfClass:[NSDictionary class]]){
            weakSelf.handler(dic, nil);
        }else{
            weakSelf.handler(nil, error);
        }
    }];
    [task resume];
}
@end
