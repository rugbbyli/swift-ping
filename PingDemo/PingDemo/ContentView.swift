//
//  ContentView.swift
//  PingDemo
//
//  Created by liyang on 2023/8/8.
//

import SwiftUI
import SwiftPing

struct ContentView: View {
    internal init(pingTarget: String = "google.com", pingTtl: String = "64", pingResult: String = "") {
        self.pingTarget = pingTarget
        self.pingTtl = pingTtl
        self.pingResult = pingResult
    }
    
    
    private func formatReply(reply: PingWrapper.Result) -> String {
        let head = ("Ping \(reply.target) [\(reply.targetAddr ?? "*")] with \(reply.packetSize) bytes data")
        var info: String
        if(reply.status == .Success) {
            info = ("reply from \(reply.responderAddr ?? "*"): time=\(reply.time)ms, TTL=\(reply.ttl)")
        }
        else if(reply.status == .Timeout) {
            info = ("failed: timed out")
        }
        else if(reply.status == .Fail) {
            info = ("reply from \(reply.responderAddr ?? "*"): status=failed, type=\(reply.icmpType), code=\(reply.icmpCode)")
        }
        else {
            info = ("reply from \(reply.responderAddr ?? "*") error: \(formatError(from: reply.error))")
        }
        return head + "\n" + info
    }
    
    private func formatError(from error: Error?) -> String {
        if error == nil { return "" }
        let nsError = error! as NSError
        
        /* *** Handle DNS errors as a special case. *** */
        if nsError.domain == kCFErrorDomainCFNetwork as String && nsError.code == Int(CFNetworkErrors.cfHostErrorUnknown.rawValue) {
            if let failure = (nsError.userInfo[kCFGetAddrInfoFailureKey as String] as? NSNumber)?.int32Value,
                failure != 0,
                let failureCStr = gai_strerror(failure), let failureStr = String(cString: failureCStr, encoding: .ascii)
            {
                return failureStr /* To do things perfectly we should punny-decode the error message… */
            }
        }
        
        /* *** Otherwise try various properties of the error object. *** */
        return nsError.localizedFailureReason ?? nsError.localizedDescription
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                TextField(
                        "host or ipaddress",
                        text: $pingTarget
                    )
                TextField("ttl", text: $pingTtl).frame(width: 50)
            }
            Text(pingResult)
                .frame(height: 60)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
            Button("Run Ping") {
//                let opts = PingWrapper.Options(hostOrAddress: pingTarget, addressStyle: .icmpV4, ttl: Int(pingTtl) ?? 64, packetSize: 16, callback: {reply in
//                    pingResult = formatReply(reply: reply)
//                    ping = nil
//                })
//                ping = PingWrapper(opts: opts)
//                ping!.start()
                
                
            }
        }
        .padding()
    }
    
    @State private var pingw: PingWrapper?
    @State private var pingTarget: String
    @State private var pingTtl: String
    @State private var pingResult: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
