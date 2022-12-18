/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import <Foundation/Foundation.h>

@interface SignUtils : NSObject
// 计算hmacsh256值
+(NSString*) hmacSHA256:(NSString *)data withSecret:(NSString*)key;
// 计算sha256摘要值
+(NSString*) doSHA256:(NSString*)input;
// 拼接path: /aksk/path?username=swf&password=1234
+(NSString*) buildPath: (NSString*)path withParams:(NSDictionary*)params;
// 获得path
+(NSString*) getPath: (NSString*)path;
// 拼接查询、路径、form参数
+(NSString*) buildParams: (NSDictionary*)params;
@end

@interface  NSString(SignUtils)
+(BOOL)isStringEmpty: (NSString*)aString;
@end
