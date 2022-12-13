//
//  File.swift
//  
//
//  Created by jyrnan on 2022/12/9.
//

import Foundation
import Network

@available(macOS 10.14, *)
///  可以参考心跳包的写法
class NetworkService {

    lazy var heartbeatTimeoutTask: DispatchWorkItem = {
        return DispatchWorkItem { self.handleHeartbeatTimeOut() }
    }()

    lazy var connection: NWConnection = {
        // Create the connection
        let connection = NWConnection(host: "x.x.x.x", port: 1234, using: self.parames)
        connection.stateUpdateHandler = self.listenStateUpdate(to:)
        return connection
    }()
    
    lazy var parames: NWParameters = {
        let parames = NWParameters(tls: nil, tcp: self.tcpOptions)
        if let isOption = parames.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            isOption.version = .v4
        }
        parames.preferNoProxies = true
        parames.expiredDNSBehavior = .allow
        parames.multipathServiceType = .interactive
        parames.serviceClass = .background
        return parames
    }()
    
    lazy var tcpOptions: NWProtocolTCP.Options = {
        let options = NWProtocolTCP.Options()
        options.enableFastOpen = true // Enable TCP Fast Open (TFO)
        options.connectionTimeout = 5 // connection timed out
        return options
    }()
    
    let queue = DispatchQueue(label: "hostname", attributes: .concurrent)
    
    private func listenStateUpdate(to state: NWConnection.State) {
        // Set the state update handler
        switch state {
        case .setup:
            // init state
            debugPrint("The connection has been initialized but not started.")
        case .waiting(let error):
            debugPrint("The connection is waiting for a network path change with: \(error)")
            self.disconnect()
        case .preparing:
            debugPrint("The connection in the process of being established.")
        case .ready:
            // Handle connection established
            // this means that the handshake is finished
            debugPrint("The connection is established, and ready to send and receive data.")
            self.receiveData()
            self.sendHeartbeat()
        case .failed(let error):
            debugPrint("The connection has disconnected or encountered an: \(error)")
            self.disconnect()
        case .cancelled:
            debugPrint("The connection has been canceled.")
        default:
            break
        }
    }
    
    // MARK: - Socket I/O
    func connect() {
        // Start the connection
        self.connection.start(queue: self.queue)
    }
    
    func disconnect() {
        // Stop the connection
        self.connection.stateUpdateHandler = nil
        self.connection.cancel()
    }
    
    private func sendPacket() {
        var packet: Data? // do something for heartbeat packet
        self.connection.send(content: packet, completion: .contentProcessed({ (error) in
            if let err = error {
                // Handle error in sending
                debugPrint("encounter an error with: \(err) after send Packet")
            } else {
                // Send has been processed
            }
        }))
    }
    
    private func receiveData() {
        self.connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] (data, context, isComplete, error) in
            guard let weakSelf = self else { return }
            if weakSelf.connection.state == .ready && isComplete == false, var data = data, !data.isEmpty {
                // do something for detect heart packet
                weakSelf.parseHeartBeat(&data)
            }
        }
    }
    
    // MARK: - Heartbeat
    private func sendHeartbeat() {
        // sendHeartbeatPacket
        self.sendPacket()
        // trigger timeout mission if the server no response corresponding packet within 5 second
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5.0, execute: self.heartbeatTimeoutTask)
    }
    
    private func handleHeartbeatTimeOut() {
        // this's sample time out mission, you can customize this chunk
        self.heartbeatTimeoutTask.cancel()
        self.disconnect()
    }
    
    private func parseHeartBeat(_ heartbeatData: inout Data) {
        // do something for parse heartbeat
        
        // cancel heartbeat timeout after parse packet success
        self.heartbeatTimeoutTask.cancel()
        
        // send heartbeat for monitor server after computing 15 second
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 15.0) {
            self.sendHeartbeat()
        }
    }

}
