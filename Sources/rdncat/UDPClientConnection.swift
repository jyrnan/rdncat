//
//  UDPClientConnection.swift
//  
//
//  Created by jyrnan on 2022/12/8.
//

import Foundation
import Network

@available(macOS 10.14, *)
class UDPClientConnection {
    
    let nwConnection: NWConnection
    let queue = DispatchQueue(label: "UDPClient connection Q")
    
    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
    }
    
    var didStopCallback: ((Error?) -> Void)? = nil
    
    func start() {
        print("connection will start")
        nwConnection.stateUpdateHandler = stateDidChange(to:)
        setupReceive() //🤔是不是该放在这里？应该可以的，这个receive动作会放到Queue里面按序执行
        nwConnection.start(queue: queue)
    }
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("Client connection ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }
    
    private func setupReceive() {
        nwConnection.receiveMessage { (data, context, isComplete, error) in
//            if let data = data, !data.isEmpty {
//                let message = String(data: data, encoding: .utf8)
//                print("connection did receive, data: \(data as NSData) string: \(message ?? "-" )")
//            }
//            if isComplete {
//                self.connectionDidEnd()
//            } else if let error = error {
//                self.connectionDidFail(error: error)
//            } else {
//                self.setupReceive()
//            }
            
            //这里按照另外一种处理收到信息的方式来调整了
            if let error = error {
                self.connectionDidFail(error: error)
            }
            guard isComplete, let data = data, !data.isEmpty else {
                self.connectionDidEnd()
                return
            }
            let message = String(data: data, encoding: .utf8)
            print("connection did receive, data: \(data as NSData) string: \(message ?? "-" )")
            self.setupReceive() //继续监听
        }
    }
        
    func send(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
                print("connection did send, data: \(data as NSData)")
        }))
    }
    
    func stop() {
        print("connection will stop")
        stop(error: nil)
    }
    
    private func connectionDidFail(error: Error) {
        print("connection did fail, error: \(error)")
        self.stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("connection did end")
        self.stop(error: nil)
    }
    
    private func stop(error: Error?) {
        self.nwConnection.stateUpdateHandler = nil
        self.nwConnection.cancel()
        if let didStopCallback = self.didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
}
