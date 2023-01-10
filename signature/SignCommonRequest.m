/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import "SignCommonRequest.h"
#import "SignUtils.h"

@implementation SignCommonRequest

@synthesize host = _host;
@synthesize path = _path;
@synthesize method = _method;
@synthesize timeout = _timeout;
@synthesize queryParameters = _queryParameters;
@synthesize pathParameters = _pathParameters;
@synthesize formParameters = _formParameters;
/**
 * 初始化request
 */
- (instancetype) initWithPath: (NSString*)path
                   withMethod: (NSString*)method
                     withHost: (NSString*)host
                      isHttps: (BOOL)isHttps
{
    self = [super init];
    _host = host;
    _method = method;
    _path = path;
    _protocol = isHttps ? @"https://" : @"http://";
    _timeout = -1;
    _cachePolicy = SIGN_REQUEST_DEFAULT_CACHE_POLICY;

    _headers = [[NSMutableDictionary alloc] init];
    _formParameters = [[NSMutableDictionary alloc] init];
    _pathParameters = [[NSMutableDictionary alloc] init];
    _queryParameters = [[NSMutableDictionary alloc] init];
    
    [self addHeader: _host forName: SIGN_HEADER_HOST];
    return self;
}

- (instancetype) initWithPath: (NSString*)path
                   withMethod: (NSString*)method
{
    self = [self initWithPath: path
                   withMethod: method
                     withHost: @""
                      isHttps: false];
    return self;
}

- (void) addPathParameter: (NSString*)value forKey:(NSString *)key {
    [self.pathParameters setValue: value forKey: key];
}
    
- (void) addQueryParameter: (NSArray*)value forKey:(NSString *)key {
    [self.queryParameters setObject: value forKey: key];
}
    
- (void) addFormParameter: (NSString*)value forKey:(NSString *)key {
    [self.formParameters setValue: value forKey: key];
    [self putHeader: SIGN_CONTENT_TYPE_FORM forName: SIGN_HEADER_CONTENT_TYPE];
}

- (NSURLRequest*) buildHttpRequest {
    NSString* path = [SignUtils buildPath: _path withParams: _pathParameters];
    NSString* queryString = [SignUtils buildParams: _queryParameters];
    
    /**
     *  拼接URL
     *  HTTP + HOST + PATH(With pathparameter) + Query Parameter
     */
    NSMutableString *url = [[NSMutableString alloc] initWithFormat:@"%@%@%@", _protocol, _host, path];
    if ([queryString length] > 0){
        [url appendFormat:@"?%@" , queryString];
    }
    /**
     *  使用URL初始化一个NSMutableURLRequest类
     */
    NSMutableURLRequest *result = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: url]
                                                          cachePolicy: _cachePolicy
                                                      timeoutInterval: _timeout];

    result.HTTPMethod = _method;
    for (id key in _headers) {
        SignatureHeader *header = [_headers objectForKey: key];
        NSString* v = [[NSString alloc] initWithData:[header.value dataUsingEncoding:NSUTF8StringEncoding] encoding:NSISOLatin1StringEncoding];
        [result setValue: v forHTTPHeaderField: header.name];
        if (header.hasMore) {
            for (SignatureHeader *h2 in header.moreHeaders) {
                NSString* v2 = [[NSString alloc] initWithData:[h2.value dataUsingEncoding:NSUTF8StringEncoding] encoding:NSISOLatin1StringEncoding];
                [result setValue: v2 forHTTPHeaderField: h2.name];
            }
        }
    }
    
    if ([_formParameters count] > 0) {
        /**
         *  如果formParams不为空
         *  将Form中的内容拼接成字符串后使用UTF8编码序列化成Byte数组后加入到Request中去
         */
        NSString *body = [SignUtils buildParams: _formParameters];
        [result setHTTPBody: [body dataUsingEncoding: NSUTF8StringEncoding]];
    } else if (nil != self.body) {
        /**
         *  如果类型为byte数组的body不为空
         *  将body中的内容MD5算法加密后再采用BASE64方法Encode成字符串，放入HTTP头中
         *  做内容校验，避免内容在网络中被篡改
         */
        [result setHTTPBody: self.body];
    }
    return result;
}

-(void) signWithSigner:(id<HWSigner>)signer {
    NSString *signerDate = [self getHeaderValueByName: SIGN_HEADER_DATE];
    NSDate* now = [NSDate date];
    NSDateFormatter* df = [[NSDateFormatter alloc] init ];
    if ([signerDate isEqualToString: @""]) {
        // add current time to `Date` Header
        df.locale = [NSLocale currentLocale];
        df.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [df setDateFormat:@"yyyyMMdd'T'HHmmss'Z'"];
        signerDate = [df stringFromDate: now];
        [self addHeader: signerDate forName: SIGN_HEADER_DATE];
    }
    
    [self putHeader: [signer appKey] forName: SIGN_HEADER_APP_KEY];
    [self putHeader: [signer appSecret] forName: SIGN_HEADER_APP_SECRET];
    // 计算body的hash值
    NSString *messageDigestContent = [self calculateContentHash];
    // 获得签名头数组
    NSArray *signatureHeaders = [self getSignedHeaders];
    // 拼接 canonicalRequestStr
    NSString * canonicalRequestStr = [self createCanonicalRequest: signatureHeaders withDigestBody: messageDigestContent];
    NSLog(@"canonicalRequestStr: \n %@ ", canonicalRequestStr);
    // 创建签名字符串
    NSString *stringToSign = [self createStringToSign: canonicalRequestStr forSignerDate: signerDate];
    NSLog(@"stringToSign: \n %@", stringToSign);
    // 创建十六进制签名字符串
    NSString *signatureHex = [self computeSignature: stringToSign];
    NSLog(@"signatureHex: \n %@", signatureHex);

    // 创建authorizationHeader
    NSString * authorizationHeader = [self buildAuthorizationHeader: signatureHeaders forSignatureHex:signatureHex];
    NSLog(@"authorizationHeader: \n %@", authorizationHeader);

    [self addHeader: authorizationHeader forName: SIGN_AUTHORIZATION];
}

- (NSString*) calculateContentHash {
    NSString *contentSha256 = [self getHeaderValueByName: X_SDK_CONTENT_SHA256];
    if (![NSString isStringEmpty: contentSha256]) {
        return contentSha256;
    }
    NSString *sha256 = [SignUtils doSHA256: [self bodyAsString] ];
    return sha256;
}

- (NSString *) getCanonicalizedResourcePath {
    NSMutableString* s = [[NSMutableString alloc] init];
    [s appendString: [SignUtils getPath: _path]];
    return s;
}

- (NSString *) getCanonicalizedQueryString {
    NSMutableDictionary * parameters = [[NSMutableDictionary alloc] init];
//    if ([self.formParameters count] > 0){
//        [parameters addEntriesFromDictionary: self.formParameters];
//    }
    if([self.queryParameters count] > 0){
        [parameters addEntriesFromDictionary: self.queryParameters];
    }
    if ([parameters count] == 0) {
        return @"";
    }

    NSArray * sortedKeys = [[parameters allKeys] sortedArrayUsingComparator:^NSComparisonResult(__strong id obj1,__strong id obj2) {
        NSString *str1=(NSString *)obj1;
        NSString *str2=(NSString *)obj2;
        return [str1 compare:str2];
    }];
    
    NSMutableString* s = [[NSMutableString alloc] init];
    NSCharacterSet *URLCombinedCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@" \"#%/:,<>?@[\\]^`{|}"] invertedSet];
    for(int i = 0 ; i < sortedKeys.count ; i++){
        id key = [sortedKeys objectAtIndex:i];
        
        NSArray* value = [parameters objectForKey:key];
        NSArray *sortArr4 = [value sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
                     return [obj1 compare:obj2];}];
        for (int j = 0; j < sortArr4.count; j++) {
            [s appendString:[key stringByAddingPercentEncodingWithAllowedCharacters: URLCombinedCharacterSet]];
            [s appendFormat:@"=%@" , [sortArr4[j] stringByAddingPercentEncodingWithAllowedCharacters: URLCombinedCharacterSet]];
            if ((i != sortedKeys.count - 1) || (j != sortArr4.count - 1)) {
                [s appendString:@"&"];
            }
        }

    }
    return s;
}

- (NSArray*) getSignedHeaders {
    NSMutableArray* headers = [[NSMutableArray alloc] init];
    for (NSString* key in _headers) {
        if ([key caseInsensitiveCompare: SIGN_AUTHORIZATION] == NSOrderedSame) {
            continue;
        }
        if ([key caseInsensitiveCompare: SIGN_HEADER_APP_KEY] == NSOrderedSame) {
            continue;
        }
        if ([key caseInsensitiveCompare:SIGN_HEADER_APP_SECRET] == NSOrderedSame) {
            continue;
        }
        
        NSString* h = key;
        [headers addObject: h];
    }
    if ([headers count] == 0) {
        return headers;
    }
    return [headers sortedArrayUsingComparator:^NSComparisonResult(__strong id obj1,__strong id obj2) {
        NSString *str1=(NSString *)obj1;
        NSString *str2=(NSString *)obj2;
        return [str1 compare:str2];
    }];
}

- (NSString *) getCanonicalizedHeaderString: (NSArray *) signatureHeaders{
    NSMutableString* headerString = [[NSMutableString alloc] init];
    for(int i = 0; i < signatureHeaders.count; i++){
        NSString *key = [signatureHeaders objectAtIndex:i];
        NSString *lowKey = [key lowercaseString];
        
        SignatureHeader* header = [_headers objectForKey:key];
        NSString *terValue = [header.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSLog(@"key: %@, value: %@", lowKey, terValue);
        [headerString appendString: lowKey];
        [headerString appendString: @":"];
        [headerString appendString: terValue];
        [headerString appendString: @"\n"];
    }
    return headerString;
}

- (NSString *) createCanonicalRequest: (NSArray *) signatureHeaders withDigestBody: (NSString *) messageDigestContent{
    NSMutableString* canonicalRequestString = [[NSMutableString alloc] init];
    NSString *canonicalizedResource = [self getCanonicalizedResourcePath];
    NSString *canonicalizedQueryString = [self getCanonicalizedQueryString];
    NSString *canonicalizedHeaderString = [self getCanonicalizedHeaderString: signatureHeaders];
    NSString *signedHeadersString = [self getSignedHeadersString: signatureHeaders];
    NSLog(@"canonicalizedHeaderString: %@", canonicalizedHeaderString);
    
    [canonicalRequestString appendString: _method];
    [canonicalRequestString appendString: @"\n"];
    [canonicalRequestString appendString: canonicalizedResource];
    [canonicalRequestString appendString: @"\n"];
    [canonicalRequestString appendString: canonicalizedQueryString];
    [canonicalRequestString appendString: @"\n"];
    [canonicalRequestString appendString: canonicalizedHeaderString];
    [canonicalRequestString appendString: @"\n"];
    [canonicalRequestString appendString: signedHeadersString];
    [canonicalRequestString appendString: @"\n"];
    [canonicalRequestString appendString: messageDigestContent];
    return canonicalRequestString;
}

- (NSString *) getSignedHeadersString: (NSArray *) signatureHeaders{
    NSMutableString* signedHeadersString = [[NSMutableString alloc] init];
    for(int i = 0; i < signatureHeaders.count; i++){
        NSString *key = [signatureHeaders objectAtIndex:i];
        NSString *lowKey = [key lowercaseString];
        [signedHeadersString appendString: lowKey];
        [signedHeadersString appendString:@";"];
    }
    [signedHeadersString deleteCharactersInRange:NSMakeRange([signedHeadersString length]-1, 1)];

    return signedHeadersString;
}

- (NSString *) createStringToSign: (NSString *) canonicalRequest forSignerDate: (NSString*) signerDate {
    NSMutableString* stringToSignString = [[NSMutableString alloc] init];
    [stringToSignString appendString: MESSAGEDIGESTALGORITHM];
    [stringToSignString appendString: @"\n"];
    [stringToSignString appendString: signerDate];
    [stringToSignString appendString: @"\n"];
    [stringToSignString appendString: [SignUtils doSHA256: canonicalRequest]];
    return stringToSignString;
}

- (NSString *) computeSignature: (NSString *) stringToSign {
    NSString * secret = [self getHeaderValueByName:SIGN_HEADER_APP_SECRET];
    NSString *signature = [SignUtils hmacSHA256: stringToSign withSecret:secret];
    return signature;
}

- (NSString *) buildAuthorizationHeader: (NSArray*)signatureHeaders forSignatureHex: (NSString *) signatureHex {
    NSMutableString* signatureResult = [[NSMutableString alloc] init];
    [signatureResult appendString: MESSAGEDIGESTALGORITHM];
    [signatureResult appendString: @" "];
    NSString * accessKey = [self getHeaderValueByName:SIGN_HEADER_APP_KEY];
    
    [signatureResult appendString: @"Access="];
    [signatureResult appendString: accessKey];
    [signatureResult appendString: @", "];
    [signatureResult appendString: @"SignedHeaders="];
    [signatureResult appendString: [self getSignedHeadersString: signatureHeaders]];
    [signatureResult appendString: @", "];
    [signatureResult appendString: @"Signature="];
    [signatureResult appendString: signatureHex];
    
    return signatureResult;
}

@end
