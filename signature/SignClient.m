/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import "SignClient.h"
#import "SignUtils.h"
#import "SignCommonRequest.h"
#import <AFNetworking/AFNetworking.h>

@implementation SignClient

@synthesize timeout = _timeout;
@synthesize verifyHttpsCert = _verifyHttpsCert;

-(SignClient*) init {
    _timeout = SIGN_REQUEST_DEFAULT_TIMEOUT;
    return self;
}

-(void) setAppKeyAndAppSecret:(NSString*)appKey appSecret:(NSString*) appSecret{
    _appKey = appKey;
    _appSecret = appSecret;
}

-(NSString*) appKey {
    return _appKey;
}

-(NSString*) appSecret {
    return _appSecret;
}

- (void) invokeWithRequest: (SignCommonRequest*)request {
    if (request.timeout < 0) {
        request.timeout = self.timeout;
    }
    [request signWithSigner: self];
    NSURLRequest *newRequest = [request buildHttpRequest];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.securityPolicy.allowInvalidCertificates = YES; // 不校验服务端证书
    [manager.securityPolicy setValidatesDomainName:NO];

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:newRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id _Nullable responseObject, NSError * _Nullable error){
        if(error) {
            NSLog(@"Error: %@\n", error);
            NSLog(@"respose:\n%@\n", response);
            NSString *result = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSLog(@"result:\n%@\n", result);
        } else {
            NSLog(@"respose:\n%@\n", response);
            NSString *result = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSLog(@"result:\n%@\n", result);
        }
    }];

    [dataTask resume];
    
}

@end
