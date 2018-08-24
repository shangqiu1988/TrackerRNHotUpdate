//
//  UXinHotUpdate.h
//  NewUXin
//
//  Created by tanpeng on 2017/10/24.
//  Copyright © 2017年 Study. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UXinHotUpdateManager.h"
#import "UXinHotUpdateDownloader.h"
#import "UXinHotUpdateVersionCheck.h"
//参数  vc package版本号 nv: 原生包版本号 module 业务模块名称
typedef NS_ENUM(NSInteger, HotUpdateType) {
    HotUpdateTypeFullDownload = 1,
    HotUpdateTypePatchFromPackage = 2,
    HotUpdateTypePatchFromPpk = 3,
};
typedef void (^FinishedUpdate)(NSDictionary *options,NSError * error) ;
typedef void (^CallBack)(NSString * info);

@interface UXinHotUpdate : NSObject
{
    
    UXinHotUpdateManager *_fileManager;
}
@property(nonatomic,copy) NSString *defaultModulenName;
@property(nonatomic,copy) FinishedUpdate finishedUpdateBlock;
@property(nonatomic,copy) CallBack callBack;
@property(nonatomic,strong) UXinHotUpdateVersionCheck *check;
@property(nonatomic,strong)   UXinHotUpdateDownloader *downloader ;
@property(nonatomic,copy) NSString *downloadUrl;
@property(nonatomic,strong) dispatch_queue_t methodQueue;
+(NSURL *)bundleForAppKey:(NSString*)appName;
-(instancetype)initWithDefaultModuleName:(NSString *)appName block:(FinishedUpdate)block callback:(CallBack)callback;
-(void)checkPackageVersion:(NSString *)packageName url:(NSString *)url;
+(void)clearHistoryVersion;
-(void)setMarkSuccess:(NSDictionary *)options;
@end
