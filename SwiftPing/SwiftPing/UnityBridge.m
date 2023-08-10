//
//  UnityBridge.m
//  swift-ping
//
//  Created by liyang on 2023/8/8.
//

#import <Foundation/Foundation.h>
#import "UnityBridge.h"
#import "SwiftPing-Swift.h"

const char* nsStr2cStr(const NSString* nsstr) {
    if(!nsstr) return NULL;
    return nsstr.UTF8String;
}

const char* nsErr2cStr(const NSError* nserr) {
    if(!nserr) return NULL;
    return nserr.localizedDescription.UTF8String;
}

static PingWrapper *_ping;
void ping(const char* hostOrAddress,
          const int8_t addressStyle,
          const int ttl,
          const int timeout,
          const int packetSize,
          const PingCallback callback) {
    NSLog(@"entering unity bridge ping function now...");
    _ping = [[PingWrapper alloc] initWithHostOrAddress:[NSString stringWithUTF8String:hostOrAddress]
                                                      addressStyle:addressStyle
                                                               ttl:ttl
                                                           timeout:timeout
                                                        packetSize:packetSize
                                                          callback: ^(PingWrapper* sender,
                                                                      NSString* target,
                                                                      NSString* targetAddr,
                                                                      int8_t status,
                                                                      NSString* responderAddr,
                                                                      NSInteger packetSize,
                                                                      uint8_t icmpType,
                                                                      uint8_t icmpCode,
                                                                      NSError* error,
                                                                      uint8_t ttl,
                                                                      int32_t time) {
        NSLog(@"entering callback of ping wrapper now...");
        _ping = NULL;
        callback(nsStr2cStr(target),
                 nsStr2cStr(targetAddr),
                 status,
                 nsStr2cStr(responderAddr),
                 packetSize,
                 icmpType,
                 icmpCode,
                 nsErr2cStr(error),
                 ttl,
                 time);
    }];
    [_ping start];
}

