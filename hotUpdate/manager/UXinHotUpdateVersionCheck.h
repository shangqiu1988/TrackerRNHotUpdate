//
//  UXinHotUpdateVersionCheck.h
//  NewUXin
//
//  Created by tanpeng on 2017/11/6.
//  Copyright © 2017年 Study. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^completionhandler)(NSDictionary *info, NSError *error);
@interface UXinHotUpdateVersionCheck : NSObject
@property(nonatomic,copy) completionhandler handler;
- (void)getVersionInfo:(NSURL *)url 
completionHandler:(completionhandler)completionHandler;
-(void)sendCheckRequest:(NSURL *)url;
@end
