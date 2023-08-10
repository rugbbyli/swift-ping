//
//  PingWrapper.swift
//  SimpleSwiftPing
//
//  Created by rugbbyli on 2023/8/7.
//

import Foundation

@objc public class PingWrapper : NSObject, SimplePingDelegate {
    
    public struct Options {
        public init(hostOrAddress: String, addressStyle: SimplePing.AddressStyle, ttl: Int = 64, timeout: Double = 5000.0, packetSize: Int = 32, callback: @escaping (PingWrapper,PingWrapper.Result) -> Void) {
            self.hostOrAddress = hostOrAddress
            self.addressStyle = addressStyle
            self.ttl = ttl
            self.timeout = timeout
            self.packetSize = packetSize
            self.callback = callback
        }
        
        public var hostOrAddress: String
        public var addressStyle: SimplePing.AddressStyle
        public var ttl: Int = 64
        public var timeout = 5000.0
        public var packetSize = 32
        public var callback: (PingWrapper,Result) -> Void
    }
    
    public struct Result {
        public var target: String
        public var targetAddr: String?
        public var status: Status
        public var responderAddr: String?
        public var packetSize: Int
        public var icmpType: UInt8
        public var icmpCode: UInt8
        public var error: Error?
        public var ttl: UInt8
        public var time: Int32
    }
    
    public enum Status : Int8
    {
        case Success = 0
        case Fail = 1
        case Timeout = 2
        case Exception = 3
    }

    var pinger: SimplePing?
    var timer: Timer?
    var startTime: TimeInterval?
    var opts: Options
    
    public init(opts: Options) {
        self.opts = opts
        
        let p = SimplePing(hostName: opts.hostOrAddress, addressStyle: opts.addressStyle)
        pinger = p
        
        NSLog("init PingWrapper...")
    }
    
    @objc
    public convenience init(hostOrAddress: String,
         addressStyle: Int8,
         ttl: Int,
         timeout: Int,
         packetSize: Int,
         callback: @escaping ((PingWrapper,String,String?,Int8, String?,Int,UInt8,UInt8,Error?,UInt8,Int32) -> Void)) {
        
        let style: SimplePing.AddressStyle = addressStyle == 0 ? .icmpV4 : addressStyle == 1 ? .icmpV6 : .any
        self.init(opts: Options(hostOrAddress: hostOrAddress,
                                addressStyle: style,
                                ttl: ttl,
                                timeout: Double(timeout),
                                packetSize: packetSize,
                                callback: { o,r in
            callback(o, r.target, r.targetAddr, r.status.rawValue, r.responderAddr, r.packetSize, r.icmpType, r.icmpCode, r.error, r.ttl, r.time)
        }))
    }
    
    deinit {
        pinger?.stop()
        timer?.invalidate()
        NSLog("deinit PingWrapper...")
    }
    
    @objc
    public func start() {
        assert(pinger != nil)
        pinger!.delegate = self
        pinger!.start()
    }
    
    func callback(result: Result) {
        timer?.invalidate()
        timer = nil
        pinger?.stop()
        pinger = nil
        
        opts.callback(self, result)
    }
    
    func simplePing(_ pinger: SimplePing, didStart address: Data) {
        assert(pinger === self.pinger)
        
        pinger.setTTL(ttl: opts.ttl)
        pinger.sendPing(data: nil)
        
        assert(timer == nil)
        timer = Timer.scheduledTimer(withTimeInterval: opts.timeout / 1000.0, repeats: false) {timer in
            let opts = self.opts
            let costTime = Date.timeIntervalSinceReferenceDate - self.startTime!
            self.callback(result: Result(target: opts.hostOrAddress, targetAddr: self.formatIPAddress(for: pinger.hostAddress), status: Status.Timeout, packetSize: opts.packetSize, icmpType: 0, icmpCode: 0, error: nil, ttl: 0, time: Int32(1000 * costTime)))
        }
        
        startTime = Date.timeIntervalSinceReferenceDate
    }
    
    func simplePing(_ pinger: SimplePing, didFail error: Error) {
        assert(pinger === self.pinger)
        
        callback(result: Result(target: opts.hostOrAddress, targetAddr: formatIPAddress(for: pinger.hostAddress), status: Status.Exception, packetSize: opts.packetSize, icmpType: 0, icmpCode: 0, error: error, ttl: 0, time: 0))
    }
    
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
    }
    
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        assert(pinger === self.pinger)
        
        callback(result: Result(target: opts.hostOrAddress, targetAddr: formatIPAddress(for: pinger.hostAddress), status: Status.Exception, packetSize: opts.packetSize, icmpType: 0, icmpCode: 0, error: error, ttl: 0, time: 0))
    }
    
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket reply: PingReply, sequenceNumber: UInt16) {
        assert(pinger === self.pinger)
        
        let status: Status = reply.valid ? .Success : .Fail
        let costTime = Date.timeIntervalSinceReferenceDate - startTime!
        callback(result: Result(target: opts.hostOrAddress, targetAddr: formatIPAddress(for: pinger.hostAddress), status: status, responderAddr: reply.ipv4Header?.sourceAddress.toString(), packetSize: opts.packetSize, icmpType: reply.icmpHeader!.type, icmpCode: reply.icmpHeader!.code, error: nil, ttl: reply.ipv4Header?.timeToLive ?? 0, time: Int32(1000 * costTime)))
    }
    
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket reply: PingReply) {
        assert(pinger === self.pinger)
        
        let costTime = Date.timeIntervalSinceReferenceDate - startTime!
        callback(result: Result(target: opts.hostOrAddress, targetAddr: formatIPAddress(for: pinger.hostAddress), status: Status.Fail, responderAddr: reply.ipv4Header?.sourceAddress.toString(), packetSize: opts.packetSize, icmpType: reply.icmpHeader?.type ?? 255, icmpCode: reply.icmpHeader?.code ?? 255, error: nil, ttl: reply.ipv4Header?.timeToLive ?? 0, time: Int32(1000 * costTime)))
    }
    
    private func formatIPAddress(for address: Data?) -> String? {
        if address == nil {
            return nil
        }
        var error = Int32(0)
        let hostStrDataCount = Int(NI_MAXHOST)
        var hostStrData = Data(count: hostStrDataCount)
        hostStrData.withUnsafeMutableBytes{ (hostStrPtr: UnsafeMutablePointer<Int8>) in
            address!.withUnsafeBytes{ (sockaddrPtr: UnsafePointer<sockaddr>) in
                error = getnameinfo(sockaddrPtr, socklen_t(address!.count), hostStrPtr, socklen_t(hostStrDataCount), nil, 0, NI_NUMERICHOST)
            }
        }
        
        if error == 0, let hostStr = String(data: hostStrData, encoding: .ascii) {
            return hostStr
        }
        else                                                                     {
            return nil
        }
    }
}
