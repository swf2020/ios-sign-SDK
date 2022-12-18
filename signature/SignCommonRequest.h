/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import <Foundation/Foundation.h>
#import "SignCommonMessage.h"


static NSString* const SIGN_LF = @"\n";
static NSString* const SIGN_HEADER_APP_KEY = @"X-hw-id";
static NSString* const SIGN_HEADER_APP_SECRET = @"X-hw-key";
//请求Header Date
static NSString* const SIGN_HEADER_DATE = @"x-sdk-date";

// 签名认证头字段--可自定义
static NSString* const SIGN_AUTHORIZATION = @"Authorization";

//请求Header Host
static NSString* const SIGN_HEADER_HOST = @"Host";

static int SIGN_REQUEST_DEFAULT_TIMEOUT = 10;
static int SIGN_REQUEST_DEFAULT_CACHE_POLICY = 0;

static NSString* const X_SDK_CONTENT_SHA256 = @"x-sdk-content-sha256";
static NSString* const MESSAGEDIGESTALGORITHM = @"SDK-HMAC-SHA256";

@protocol HWSigner
- (NSString*) appKey;
- (NSString*) appSecret;
@end

@interface SignCommonRequest : SignCommonMessage {
    NSString* _protocol;
    NSString* _host;
    NSString* _path;
    NSString* _method;
    NSURLRequestCachePolicy _cachePolicy;

    int _timeout;
    NSMutableDictionary* _queryParameters;
    NSMutableDictionary* _pathParameters;
    NSMutableDictionary* _formParameters;
    NSString* _signatureHeaders;
    NSObject* _attachment;
}

@property (nonatomic) int timeout;
@property (nonatomic) NSString* protocol;
@property (nonatomic) NSString* host;
@property (nonatomic) NSString* path;
@property (nonatomic) NSString* method;
@property (nonatomic) NSMutableDictionary* queryParameters;
@property (nonatomic) NSMutableDictionary* formParameters;
@property (nonatomic) NSMutableDictionary* pathParameters;

- (instancetype) initWithPath: (NSString*)path
                   withMethod: (NSString*)method
                     withHost: (NSString*)host
                      isHttps: (BOOL)isHttps;

- (instancetype) initWithPath: (NSString*)path
                   withMethod: (NSString*)method;

- (void) addPathParameter: (NSString*)value forKey:(NSString*)key;
- (void) addQueryParameter: (NSString*)value forKey:(NSString*)key;
- (void) addFormParameter: (NSString*)value forKey:(NSString*)key;
// 构建request对象
- (NSURLRequest*) buildHttpRequest;
- (void) signWithSigner:(id<HWSigner>)signer;
// 对body取摘要
- (NSString*) calculateContentHash;
// 获得path
- (NSString *) getCanonicalizedResourcePath;
// 获得签名头字段数组
- (NSArray*) getSignedHeaders;
// 拼接统一签名头字符串
- (NSString *) getCanonicalizedHeaderString: (NSArray *) signatureHeaders;
// 创建CanonicalRequest字符串
- (NSString *) createCanonicalRequest: (NSArray *) signatureHeaders withDigestBody: (NSString *) messageDigestContent;
// 拼接签名头字符串
- (NSString *) getSignedHeadersString: (NSArray *) signatureHeaders;
// 拼接签名字符串
- (NSString *) createStringToSign: (NSString *) canonicalRequest forSignerDate: (NSString*) signerDate;
// 取签名字符串的摘要
- (NSString *) computeSignature: (NSString *) stringToSign;
// 把签名头字段添加到请求头中
- (NSString *) buildAuthorizationHeader: (NSArray*)signatureHeaders forSignatureHex: (NSString *) signatureHex;

@end
