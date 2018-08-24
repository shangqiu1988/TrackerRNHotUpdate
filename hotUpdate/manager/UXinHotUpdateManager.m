//
//  UXinHotUpdateManager.m
//  NewUXin
//
//  Created by tanpeng on 2017/10/25.
//  Copyright © 2017年 Study. All rights reserved.
//

#import "UXinHotUpdateManager.h"
#import "SSZipArchive.h"
#import "BSDiff.h"
#import "bspatch.h"
@implementation UXinHotUpdateManager
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _opQueue = dispatch_queue_create("cn.reactnative.hotupdatefileManager", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (BOOL)createDir:(NSString *)dir
{
    __block BOOL success = YES;
    
    dispatch_sync(_opQueue, ^{
        BOOL isDir;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:dir isDirectory:&isDir]) {
            if (isDir) {
                success = true;
                return;
            }
        }
        
        NSError *error;
        [fileManager createDirectoryAtPath:dir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (!error) {
            success = true;
            return;
        }
    });
    return  success;
}

- (void)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
        progressHandler:(void (^)(NSString *entry, long entryNumber, long total))progressHandler
      completionHandler:(void (^)(NSString *path, BOOL succeeded, NSError *error))completionHandler

{
    dispatch_async(_opQueue, ^{
       
        [SSZipArchive unzipFileAtPath:path toDestination:destination progressHandler:^(NSString *entry, unz_file_info zipInfo, long entryNumber, long total) {
            if(progressHandler){
                progressHandler(entry,entryNumber,total);
            }
        } completionHandler:^(NSString *path, BOOL succeeded, NSError *error) {
            if(completionHandler){
                completionHandler(path,succeeded,error);
            }
            
        }];
        
    });
}
- (void)bsdiffFileAtPath:(NSString *)path
              fromOrigin:(NSString *)origin
           toDestination:(NSString *)destination
       completionHandler:(void (^)(BOOL success))completionHandler
{
  if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NULL]){
    NSLog(@"patch exist");
  }
  if([[NSFileManager defaultManager] fileExistsAtPath:origin isDirectory:NULL]){
    NSLog(@"origin exist");
  }
  [self removeFile:destination completionHandler:nil];
 
    dispatch_async(_opQueue, ^{
        BOOL success=[BSDiff bsdiffPatch:path origin:origin toDestination:destination];
        if(completionHandler){
            completionHandler(success);
        }
    });
}
- (void)removeFile:(NSString *)filePath
 completionHandler:(void (^)(NSError *error))completionHandler
{
    dispatch_async(_opQueue, ^{
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (completionHandler) {
            completionHandler(error);
        }
    });
}


@end
