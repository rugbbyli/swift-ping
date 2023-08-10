//
//  PingReply.swift
//  SimpleSwiftPing
//
//  Created by rugbbyli on 2023/8/7.
//

import Foundation

struct PingReply
{
    var ipv4Header: IPv4Header?
    var icmpHeader: ICMPHeader?
    var valid: Bool = false
    
    var IsEchoReply: Bool {
        get {
            if(!valid) {
                return false
            }
            let type = ipv4Header == nil ? ICMPv6TypeEcho.reply.rawValue : ICMPv4TypeEcho.reply.rawValue
            return icmpHeader?.type == type
        }
    }
    
    var IsTtlExceeded: Bool {
        get {
            return icmpHeader?.type == 11
        }
    }
}
