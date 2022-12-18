/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AFNetworking/AFNetworking.h"
#import "SignClient.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    
    SignClient *apiClient = [[SignClient alloc] init];
    NSString *appKey = @"eed98714807f40059f9c18698bbda8b2"; // appKey
    NSString *appSerct = @"84268e16539a4bc89b357ce0a25c435d"; // appSecert
    NSString *host = @"cf77616ecc694c8da7584fd69e0dc6ac.apig.cn-north-4.huaweicloudapis.com"; // 域名
    bool isHttps = TRUE; // 是否https协议，如果服务端证书不可信，SignClient需要开启证书免校验verifyHttpsCert
    [apiClient setAppKeyAndAppSecret:appKey appSecret:appSerct];
    
    SignCommonRequest* request = [[SignCommonRequest alloc] initWithPath: @"/app/aksk/post" // api的path
                                                          withMethod: SIGN_METHOD_POST // api的请求方法
                                                            withHost: host
                                                             isHttps: isHttps];
    [request addQueryParameter:@"ff" forKey: @"gg"]; // query params
    [request addQueryParameter:@"bb" forKey: @"aa"]; // 暂不支持枚举
    NSString *body = @"demo"; // body
    [request setBodyString: body withContentType: @""];
    [apiClient invokeWithRequest: request];

    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
