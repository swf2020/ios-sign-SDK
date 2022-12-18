/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import <Foundation/Foundation.h>
#import "SignCommonRequest.h"

/**
 * 签名客户端
 */
@interface SignClient : NSObject<HWSigner> {
    int _timeout;
    NSString* _appKey;
    NSString* _appSecret;
    BOOL (^_verifyHttpsCert)(NSURLAuthenticationChallenge *);
}

@property (nonatomic) int timeout;
@property (nonatomic) BOOL (^verifyHttpsCert)(NSURLAuthenticationChallenge *);
/**
 * 设置ak, sk
 */
-(void) setAppKeyAndAppSecret:(NSString*)appKey appSecret:(NSString*) appSecret;

/**
 * 初始化签名客户端
 */
- (SignClient*) init;

/**
 * 签名，并发起request请求
 */
- (void) invokeWithRequest: (SignCommonRequest*)request;
@end
