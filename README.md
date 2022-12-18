# ios-sign-SDK

## 介绍
华为云API网关app认证ios-sign-SDK
客户端实现ak/sk签名，object-c语言，AFNetworking框架

## 环境要求

gcc

AFNetworking 版本: == 4.0.1

xcode 版本: >= 14.2

cocoapods == 最新版

## step1. 
主程序为 signature/signature/main.m
运行，查看效果
## step2.


```objectivec
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
```

如果服务端证书不可信，SignClient需要开启证书免校验verifyHttpsCert

