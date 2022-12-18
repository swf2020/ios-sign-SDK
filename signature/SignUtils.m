/*
 * Copyright (c) Huawei Technologies CO., Ltd. 2022-2022. All rights reserved.
 */
#import "SignUtils.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

@implementation SignUtils

+ (NSString *)hmacSHA256: (NSString *)content withSecret:(NSString*)secret {
    const char *cKey  = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [content cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMACData = [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
    const unsigned char *buffer = (const unsigned char *)[HMACData bytes];
    NSMutableString *HMAC = [NSMutableString stringWithCapacity:HMACData.length * 2];
    for (int i = 0; i < HMACData.length; ++i){
        [HMAC appendFormat:@"%02x", buffer[i]];
    }
    return HMAC;
}

+ (NSString*) doSHA256: (NSString*)input{
    const char* str = [input UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), result);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x",result[i]];
    }
    return output;
}

+(NSString*) buildPath: (NSString*)path withParams:(NSDictionary*)params {
    NSMutableString* r = [[NSMutableString alloc] initWithString: path];
    NSLog(@"\nr: %@\n", r);
    
    for (id key in params) {
        NSString* value = [params objectForKey:key];
        [r replaceCharactersInRange: [r rangeOfString:[NSString stringWithFormat:@"[%@]", key]]
                         withString: value];
    }
    return r;
}

+(NSString*) getPath: (NSString*)path {
    if ([path isEqualToString: @""])
        return @"/";
    
    NSMutableString* pathStr = [[NSMutableString alloc] initWithString: path];
    
    if (![path hasPrefix: @"/"])
        [pathStr insertString:@"/" atIndex:0];
        
    if (![path hasSuffix: @"/"])
        [pathStr appendString: @"/"];
    
    return (NSString*) pathStr;
}

+(NSString*) buildParams: (NSDictionary*)params {
    NSCharacterSet* charset = [[NSCharacterSet characterSetWithCharactersInString:@"+= \"#%/:<>?@[\\]^`{|}"] invertedSet];
    NSMutableString * r = [[NSMutableString alloc] init];
    if (nil == params || [params count] == 0) {
        return @"";
    }
    bool isFirst = true;
    for (id key in params) {
        if (!isFirst) {
            [r appendString:@"&"];
        } else {
            isFirst = false;
        }
        NSString* p = [params objectForKey: key];
        [r appendFormat:@"%@=%@", key , [p stringByAddingPercentEncodingWithAllowedCharacters: charset]];
    }
    return r;
}
@end

@implementation NSString(SignUtils)
+(BOOL)isStringEmpty: (NSString*)aString {
    if (!aString) {
        return YES;
    }
    return [aString isEqualToString:@""];
}

@end
