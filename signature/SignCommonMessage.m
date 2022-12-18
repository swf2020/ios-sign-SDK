/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import "SignCommonMessage.h"
#import "SignUtils.h"

@implementation SignatureHeader
@synthesize name = _name;
@synthesize value = _value;

- (instancetype) initWithValue: (NSString*)value forName:(NSString*)name {
    _name = name;
    _value = value;
    return self;
}

- (BOOL) hasMore {
    return _moreHeaders != nil;
}

- (void) addMore:(SignatureHeader*)header {
    if (_moreHeaders != nil) {
        _moreHeaders = [[NSMutableArray alloc] init];
    }
    [_moreHeaders addObject: header];
}

- (NSArray*) moreHeaders {
    return _moreHeaders;
}
@end

@implementation SignCommonMessage

- (instancetype) init {
    _headers = [[NSMutableDictionary alloc] init];
    return self;
}

- (NSDictionary*) toJsonDictionary {
    NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];
    for (NSString* key in _headers) {
        SignatureHeader* header = [_headers valueForKey: key];
        NSMutableArray* values = [[NSMutableArray alloc] init];
        [values addObject: header.value];
        if (header.hasMore) {
            for (SignatureHeader* mh in header.moreHeaders) {
                [values addObject: mh.value];
            }
        }
        [headers setValue: values forKey: header.name];
    }
    return headers;
}

- (NSString*) putHeader:(NSString *)value forName:(nonnull NSString *)name {
    if (value == nil) {
        @throw [NSString stringWithFormat: @"empty header value for %@", name];
    }
    NSString* key = [name lowercaseString];
    SignatureHeader* old = [_headers objectForKey: key];
    SignatureHeader* new = [[SignatureHeader alloc] initWithValue: value forName: name];
    if (old != nil) {
        [_headers setValue: new forKey: key];
        return old.value;
    } else {
        [_headers setValue: new forKey: key];
        return nil;
    }
}

- (void) addHeader: (NSString*)value forName:(NSString *)name {
    if (value == nil) {
        @throw [NSString stringWithFormat: @"empty header value for %@", name];
    }
    NSString* key = [name lowercaseString];
    SignatureHeader* header = [_headers objectForKey: key];
    if (header != nil) {
        [header addMore: [[SignatureHeader alloc] initWithValue: value forName: name]];
    } else {
        header = [[SignatureHeader alloc] initWithValue: value forName: name];
        [_headers setValue: header forKey: key];
    }
}

- (SignatureHeader*) headerByName: (NSString*)name {
    if ([NSString isStringEmpty:name]) {
        @throw [NSString stringWithFormat:@"headerByName input empty"];
    }
    return [_headers objectForKey: [name lowercaseString]];
}

- (NSString*) getHeaderValueByName: (NSString*)name {
    if ([NSString isStringEmpty:name]) {
        @throw [NSString stringWithFormat:@"headerValueByName input empty"];
    }
    SignatureHeader* header = [_headers objectForKey: [name lowercaseString]];
    if (header == nil) {
        return @"";
    }
    if (header.hasMore) {
        @throw [NSString stringWithFormat:@"ambigous header %@", name];
    }
    return header.value;
}

- (NSString*) contentType {
    return [self getHeaderValueByName: SIGN_HEADER_CONTENT_TYPE];
}

- (NSData*) body {
    return _body;
}

- (NSString*) bodyAsString {
    if (_body == nil) {
        return @"";
    } else {
        return [[NSString alloc] initWithData: _body encoding:NSUTF8StringEncoding];
    }
}

- (void) setBody:(NSData*)data withContentType:(NSString*)contentType {
    _body = data;
}

- (void) setBodyString:(NSString*)s withContentType:(NSString*)contentType {
    NSData* buf = [s dataUsingEncoding: NSUTF8StringEncoding];
    [self setBody: buf withContentType: contentType];
}
@end
