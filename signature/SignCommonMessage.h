/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import <Foundation/Foundation.h>

// 构造签名头的公共信息
@interface SignatureHeader: NSObject {
    NSString* _name;
    NSString* _value;
    NSMutableArray* _moreHeaders;
}
NS_ASSUME_NONNULL_BEGIN
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* value;

- (instancetype) initWithValue: (NSString*)value forName:(NSString*)name;
- (BOOL) hasMore;
- (void) addMore:(SignatureHeader*)header;
- (NSArray*) moreHeaders;
NS_ASSUME_NONNULL_END
@end

NS_ASSUME_NONNULL_BEGIN

// 请求方法
static NSString* const SIGN_METHOD_GET = @"GET";
static NSString* const SIGN_METHOD_POST = @"POST";
static NSString* const SIGN_METHOD_HEAD = @"HEAD";
static NSString* const SIGN_METHOD_PUT = @"PUT";
static NSString* const SIGN_METHOD_DELETE = @"DELETE";
static NSString* const SIGN_METHOD_PATCH = @"PATCH";
static NSString* const SIGN_METHOD_OPTIONS = @"OPTIONS";

// 请求Header Content-Type
static NSString* const SIGN_HEADER_CONTENT_TYPE = @"Content-Type";

//表单类型Content-Type
static NSString* const SIGN_CONTENT_TYPE_FORM = @"application/x-www-form-urlencoded; charset=UTF-8";

//流类型Content-Type
static NSString* const SIGN_CONTENT_TYPE_STREAM = @"application/octet-stream; charset=UTF-8";

//JSON类型Content-Type
static NSString* const SIGN_CONTENT_TYPE_JSON = @"application/json; charset=UTF-8";

//XML类型Content-Type
static NSString* const SIGN_CONTENT_TYPE_XML = @"application/xml; charset=UTF-8";

//文本类型Content-Type
static NSString* const SIGN_CONTENT_TYPE_TEXT = @"application/text; charset=UTF-8";
NS_ASSUME_NONNULL_END

@interface SignCommonMessage : NSObject {
    NSData* _body;
    NSMutableDictionary* _headers;
}

NS_ASSUME_NONNULL_BEGIN
- (instancetype) init;
// 获取特定头
- (SignatureHeader*) headerByName: (NSString*)name;
// 根据key获取value
- (NSString*) getHeaderValueByName: (NSString*)name;
// 更新SignatureHeader头信息，有就覆盖，没有就添加
- (NSString*) putHeader:(NSString *)value forName:(nonnull NSString *)name;
// 添加SignatureHeader，有就追加，没有就添加
- (void) addHeader: (NSString*)value forName:(NSString *)name;

- (NSDictionary*) toJsonDictionary;

- (NSString*) contentType;
// 获得body data类型
- (NSData*) body;
// 获得body 字符串类型
- (NSString*) bodyAsString;
// 添加body data类型
- (void) setBody:(NSData*)data withContentType:(NSString*)contentType;
// 添加body 字符串类型
- (void) setBodyString:(NSString*)s withContentType:(NSString*)contentType;

NS_ASSUME_NONNULL_END
@end
