//
//  UXinHotUpdateDownloader.h
//  NewUXin
//
//  Created by tanpeng on 2017/10/25.
//  Copyright © 2017年 Study. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UXinHotUpdateDownloader : NSObject
- (void)download:(NSString *)downloadPath savePath:(NSString *)savePath
 progressHandler:(void (^)(long long, long long))progressHandler
completionHandler:(void (^)(NSString *path, NSError *error))completionHandler;
@end
