//
//  AESCryptor.h
//  CryptorExample
//
//  Created by White on 2017/8/4.
//  Copyright © 2017年 White. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AESCryptorCodeProvider) {
    AESCryptorCodeProviderApple,
    AESCryptorCodeProviderOpenSSL,
};

@interface AESCryptor : NSObject

+ (NSURL * _Nullable)AES_CBC_WithSourceFileURL: (NSURL* _Nonnull)sourceFileURL
                                            iv: (NSData * _Nonnull)iv
                                           key: (NSString * _Nonnull)key
                                     isEncrypt: (BOOL)isEncrypt
                                   userService: (AESCryptorCodeProvider)service
                                         error: (NSError * _Nullable __autoreleasing *_Nullable)error;

//+ (NSData *)beginAESWithData: (NSData *)data
//                      ivData: (NSData *)ivData
//                  ivDataNext: (NSData **)ivDataNext
//                   isEncrypt: (BOOL)isEncrypt
//                         key: (NSString *)key;

+ (NSData * _Nonnull)AES_CBC_OpenSSLWith: (NSData * _Nonnull)data
                                      iv: (NSData * _Nonnull)iv
                                   ivOut: (NSData * _Nullable * _Nullable)ivOut
                                     key: (NSString * _Nonnull)key
                               isEncrypt: (BOOL)isEncrypt
                          needsUnpadding: (BOOL)needsUnpadding;

@end
