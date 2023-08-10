//
//  UnityBridge.h
//  SwiftPing
//
//  Created by liyang on 2023/8/9.
//

#ifndef UnityBridge_h
#define UnityBridge_h

typedef void (*PingCallback)(const char* target,
                             const char* targetAddr,
                             const uint8_t status,
                             const char* responderAddr,
                             const uint8_t packetSize,
                             const uint8_t icmpType,
                             const uint8_t icmpCode,
                             const char* error,
                             const uint8_t ttl,
                             const double time);

void ping(const char* hostOrAddress,
          const int8_t addressStyle,
          const int ttl,
          const int timeout,
          const int packetSize,
          const PingCallback callback);

#endif /* UnityBridge_h */
