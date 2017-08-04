//
//  AESCryptor.m
//  CryptorExample
//
//  Created by White on 2017/8/4.
//  Copyright © 2017年 White. All rights reserved.
//

#import "AESCryptor.h"
#include <openssl/aes.h>
#import <CommonCrypto/CommonCrypto.h>

const static NSErrorDomain kCryptErrorDomain = @"kCryptorErrorDomain";
const static NSUInteger kAESLoopBlockSize = 256;

@implementation AESCryptor

+ (NSURL * _Nullable)AES_CBC_WithSourceFileURL: (NSURL* _Nonnull)sourceFileURL
                                            iv: (NSData * _Nonnull)iv
                                           key: (NSString * _Nonnull)key
                                     isEncrypt: (BOOL)isEncrypt
                                   userService: (AESCryptorCodeProvider)service
                                         error: (NSError * _Nullable __autoreleasing *_Nullable)error {
    BOOL isSourceFileDir = YES;
    if (![NSFileManager.defaultManager fileExistsAtPath:sourceFileURL.path isDirectory:&isSourceFileDir]) {
        if (error) {
            *error = [NSError errorWithDomain:kCryptErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: @"Source file doesn't exist."}];
        }
        return nil;
    }
    
    if (isSourceFileDir) {
        if (error) {
            *error = [NSError errorWithDomain:kCryptErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"sourFileURL is a folder URL."}];
        }
        return nil;
    }

    NSURL *tempURLAfterAES = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:[sourceFileURL lastPathComponent]]];
    [NSFileManager.defaultManager removeItemAtURL:tempURLAfterAES error:nil];
    
    
    //Source File Size
    NSNumber *fileSizeNum = [NSFileManager.defaultManager attributesOfItemAtPath:sourceFileURL.path error:nil][NSFileSize];
    NSUInteger fileSize = fileSizeNum.unsignedIntegerValue;
    
    //Create Streams
    NSInputStream *inputS = [[NSInputStream alloc] initWithURL:sourceFileURL];
    NSOutputStream *outputS = [[NSOutputStream alloc] initWithURL:sourceFileURL append:YES];
    [inputS open];
    [outputS open];
    
    switch (service) {
        case AESCryptorCodeProviderApple: {
            [self p_AES_CBC_AppleWithInput:inputS
                                    output:outputS
                                        iv:iv
                                       key:key
                                 isEncrypt:isEncrypt
                                     error:error];
            break;
        }
        case AESCryptorCodeProviderOpenSSL: {
            [self p_AES_CBC_OpenSSLWithInput:inputS
                                      output:outputS
                                          iv:iv
                                         key:key
                              sourceFileSize:fileSize
                                   isEncrypt:isEncrypt];
            break;
        }
    }
    
    [inputS close];
    [outputS close];
    
    if (error && *error) {
        return nil;
    }
    
    return tempURLAfterAES;
}

#pragma mark - OpenSSL

+ (void)p_AES_CBC_OpenSSLWithInput: (NSInputStream * _Nonnull)inputStream
                            output: (NSOutputStream * _Nonnull) outputStream
                                iv: (NSData * _Nonnull)iv
                               key: (NSString * _Nonnull)key
                    sourceFileSize: (NSUInteger)sourceFileSize
                         isEncrypt: (BOOL)isEncrypt {
    
    unsigned char * ivOutBuffer = (unsigned char *)malloc(AES_BLOCK_SIZE);
    
    NSUInteger bytesRead = 0;
    while ([inputStream hasBytesAvailable]) {
        
        uint8_t readBuffer[kAESLoopBlockSize * 8] = {0};
        NSUInteger lenRead = [inputStream read:readBuffer maxLength:kAESLoopBlockSize * 8];
        
        if (lenRead == 0) {
            break;
        }
        
        bytesRead += lenRead;
        
        size_t dataOutLen;
        unsigned char * dataOut = NULL;
        
        [self p_AES_CBC_OpenSSLWith:readBuffer
                       dataInLength:(size_t)lenRead
                            dataOut:&dataOut
                      dataOutLength:&dataOutLen
                                 iv:(unsigned char *)iv.bytes
                              ivOut:&ivOutBuffer
                                key:(unsigned char *)key.UTF8String
                             keyLen:(int)key.length
                          isEncrypt:isEncrypt
                      needUnpadding:(bytesRead == sourceFileSize) && !isEncrypt];
        
        [outputStream write:readBuffer maxLength:lenRead];
        
    }
    
    free(ivOutBuffer);
    
}

+ (NSData * _Nonnull)AES_CBC_OpenSSLWith: (NSData * _Nonnull)data
                                      iv: (NSData * _Nonnull)iv
                                   ivOut: (NSData * _Nullable * _Nullable)ivOut
                                     key: (NSString * _Nonnull)key
                               isEncrypt: (BOOL)isEncrypt
                          needsUnpadding: (BOOL)needsUnpadding {
    
    unsigned char * dataIn = (unsigned char *)data.bytes;
    size_t dataInLength = (size_t)data.length;
    
    size_t dataOutLen;
    unsigned char * dataOut = NULL;
    unsigned char * ivOutBuffer = (unsigned char *)malloc(AES_BLOCK_SIZE);

    [self p_AES_CBC_OpenSSLWith:dataIn
                   dataInLength:dataInLength
                        dataOut:&dataOut
                  dataOutLength:&dataOutLen
                             iv:(unsigned char *)iv.bytes
                          ivOut:&ivOutBuffer
                            key:(unsigned char *)key.UTF8String
                         keyLen:(int)key.length
                      isEncrypt:isEncrypt
                  needUnpadding:needsUnpadding];
    
    NSData *finaldata = [NSData dataWithBytes:dataOut length:dataOutLen];
    free(dataOut);
    
    if(ivOut) {
        *ivOut = [NSData dataWithBytes:ivOutBuffer length:AES_BLOCK_SIZE];
    }
    free(ivOutBuffer);
    
    return finaldata;
}

+ (void)p_AES_CBC_OpenSSLWith: (unsigned char *)dataIn
                 dataInLength: (size_t)dataInLength
                      dataOut: (unsigned char **)dataOut //Needs to be released by caller
                dataOutLength: (size_t *)dataOutLength
                           iv: (unsigned char *)iv
                        ivOut: (unsigned char **)ivOut //Needs to be released by caller
                          key: (unsigned char *)key
                       keyLen: (int)keyLen
                    isEncrypt: (bool)isEncrypt
                needUnpadding: (bool)needUnpadding {
    
    //CustomIV to change while loop
    unsigned char customIV[AES_BLOCK_SIZE];
    memcpy(customIV, iv, AES_BLOCK_SIZE);
    
    //Padded result
    unsigned char * dataInPadded = NULL;
    size_t dataInLengthPadded;
    
    if (isEncrypt && dataInLength%AES_BLOCK_SIZE != 0) {
        //PKCS#7 Padding
        uint8_t paddingValue = AES_BLOCK_SIZE - dataInLength%AES_BLOCK_SIZE;
        
        dataInLengthPadded = dataInLength + paddingValue;
        dataInPadded = (unsigned char *)malloc(dataInLengthPadded);
        
        memset(dataInPadded, paddingValue, dataInLengthPadded);
        memcpy(dataInPadded, dataIn, dataInLength);
    } else {
        dataInPadded = dataIn;
        dataInLengthPadded = dataInLength;
    }
    
    AES_KEY aes_key;
    if (isEncrypt) {
        AES_set_encrypt_key(key, keyLen * 8, &aes_key);
    } else {
        AES_set_decrypt_key(key, keyLen * 8, &aes_key);
    }
    
    //
    unsigned char * resultBuffer = (unsigned char *)malloc(dataInLengthPadded);
    memset(resultBuffer, 0, dataInLengthPadded);
    
    AES_cbc_encrypt(dataInPadded,
                    resultBuffer,
                    dataInLengthPadded,
                    &aes_key,
                    customIV,
                    isEncrypt ? AES_ENCRYPT : AES_DECRYPT);
    
    //Save IV
    memcpy(*ivOut, customIV, AES_BLOCK_SIZE);
    
    //Free dataInPadded if needed
    if (dataIn != dataInPadded) {
        free(dataInPadded);
    }
    
    *dataOutLength = dataInLengthPadded;
    *dataOut = resultBuffer;
    
    //If the process is decryption, and unpadding is needed (last block)
    if (!isEncrypt && needUnpadding) {
        uint8_t *lastByteAddress = resultBuffer + dataInLengthPadded - 1;
        uint8_t last = *lastByteAddress; //last是最后一个字节
        
        //PKCS#7 Unpadding
        if (last >= AES_BLOCK_SIZE) {
            return;
        }
        
        //Check if unpadding is suitable for the data
        bool isNeedToUnpad = YES;
        for (int loop = 0; loop < last; loop++) {
            if (*(lastByteAddress - loop) != last) {
                isNeedToUnpad = NO;
                break;
            }
        }
        
        if (isNeedToUnpad) {
            *dataOutLength = dataInLengthPadded - last;
            return;
        }
    }
    return;
}

#pragma mark - Apple

+ (void)p_AES_CBC_AppleWithInput: (NSInputStream * _Nonnull)inputStream
                            output: (NSOutputStream * _Nonnull) outputStream
                                iv: (NSData * _Nonnull)iv
                               key: (NSString * _Nonnull)key
                         isEncrypt: (BOOL)isEncrypt error: (NSError * _Nullable __autoreleasing *_Nullable)error {
    CCCryptorRef cyptor;
    CCCryptorStatus createStatus = CCCryptorCreateWithMode(isEncrypt ? kCCEncrypt : kCCDecrypt,
                                                           kCCModeCBC,
                                                           kCCAlgorithmAES,
                                                           kCCOptionPKCS7Padding,
                                                           iv.bytes,
                                                           key.UTF8String,
                                                           key.length * 8,
                                                           NULL,
                                                           0,
                                                           0,
                                                           0,
                                                           &cyptor);
    if (createStatus != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:kCryptErrorDomain code:createStatus userInfo:nil];
        }
        return;
    }
    
    while ([inputStream hasBytesAvailable]) {
        
        uint8_t buffer[kAESLoopBlockSize] = {0};
        NSUInteger lenRead = [inputStream read:buffer maxLength:kAESLoopBlockSize];
        if (lenRead == 0) {
            break;
        }
        
        uint8_t bufferOut[kAESLoopBlockSize] = {0};
        size_t moved;
        
        //加密/解密
        CCCryptorStatus updateStatus = CCCryptorUpdate(cyptor,
                                                       buffer,
                                                       lenRead,
                                                       bufferOut,
                                                       kAESLoopBlockSize,
                                                       &moved);
        
        if (updateStatus != kCCSuccess) {
            if (error) {
                *error = [NSError errorWithDomain:kCryptErrorDomain code:updateStatus userInfo:nil];
            }
            return;
        }
        
        [outputStream write:bufferOut maxLength:(NSUInteger)moved];
    }
    
    //最后一次aes
    uint8_t bufferLast[AES_BLOCK_SIZE] = {0};
    size_t movedLast;
    CCCryptorStatus finalStatus = CCCryptorFinal(cyptor,
                                                 bufferLast,
                                                 AES_BLOCK_SIZE,
                                                 &movedLast);
    if (finalStatus != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:kCryptErrorDomain code:finalStatus userInfo:nil];
        }
        return;
    }
    [outputStream write:bufferLast maxLength:(NSUInteger)movedLast];
    CCCryptorRelease(cyptor);
}

@end
