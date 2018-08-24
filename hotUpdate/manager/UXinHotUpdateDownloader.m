//
//  UXinHotUpdateDownloader.m
//  NewUXin
//
//  Created by tanpeng on 2017/10/25.
//  Copyright © 2017年 Study. All rights reserved.
//

#import "UXinHotUpdateDownloader.h"
@interface UXinHotUpdateDownloader()<NSURLSessionDownloadDelegate>
@property(copy) void (^progresshandler)(long long, long long);
@property(copy) void (^completionHandler)(NSString*, NSError*);
@property(copy) NSString *savePath;
@end
@implementation UXinHotUpdateDownloader
-(void)dealloc
{
  _progresshandler=nil;
  _completionHandler=nil;
  _savePath=nil;
}
-(instancetype)init
{
  self=[super init];
  if(self){
    
  }
  return self;
}
 -(void)download:(NSString *)downloadPath savePath:(NSString *)savePath
 progressHandler:(void (^)(long long, long long))progressHandler
completionHandler:(void (^)(NSString *path, NSError *error))completionHandler;
{
    NSAssert(downloadPath, @"no download path");
     NSAssert(savePath, @"no save path");
  
    self.progresshandler = [progressHandler copy];
    self.completionHandler = [completionHandler copy];
    self.savePath=[savePath copy];
  [self download:downloadPath];
}

- (void)download:(NSString *)path
{
    NSURL *url =[NSURL URLWithString:path];
    NSURLSessionConfiguration *sessionConfig =[NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session =[NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask *task =[session downloadTaskWithURL:url];
    [task resume];
}
#pragma mark - session delegate
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (self.progresshandler) {
        self.progresshandler(totalBytesWritten ,totalBytesExpectedToWrite);
    }
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSData *data = [NSData dataWithContentsOfURL:location];
    NSError *error;
    [data writeToFile:self.savePath options:NSDataWritingAtomic error:&error];

  
//        if(self.completionHandler){
//            self.completionHandler(nil, error);
//
//        }
  
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
   [session finishTasksAndInvalidate];
    if(self.completionHandler){
        self.completionHandler(self.savePath, error);
    }
  
}
@end
