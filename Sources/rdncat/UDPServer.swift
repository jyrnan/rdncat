//
//  UDPServer.swift
//  
//
//  Created by jyrnan on 2022/12/8.
//

import Foundation
import Network

@available(macOS 10.14, *)
class UDPServer {
    let port: NWEndpoint.Port
    let listener: NWListener
    
    //这里还需要考虑是不是有必要创建Diction来保存UDP的“连接”？
    //因为有一定的风险会导致这些connection不被释放造成内存泄露
    private var connectionsByID: [Int: UDPServerConnection] = [:]
    
    init(port: UInt16) {
        self.port = NWEndpoint.Port(rawValue: port)!
        listener = try! NWListener(using: .udp, on: self.port)
    }
    
    func start() throws {
        print("UDPServer starting...")
        listener.stateUpdateHandler = self.stateDidChange(to:)
        listener.newConnectionHandler = self.didAccept(nwConnection:)
        listener.start(queue: .main)
    }
    
    func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
          print("Server ready.")
        case .failed(let error):
            print("Server failure, error: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        default:
            break
        }
    }
    
    private func didAccept(nwConnection: NWConnection) {
        let connection = UDPServerConnection(nwConnection: nwConnection)
        self.connectionsByID[connection.id] = connection
        
        //设置connection在结束时回调方法，目的是从Sever保存的连接中去掉当前连接
        connection.didStopCallback = { _ in
            self.connectionDidStop(connection)
        }
        connection.start()
        connection.send(data: "Welcome you are connection: \(connection.id)".data(using: .utf8)!)
        print("server did open connection \(connection.id)")
    }
    
    private func connectionDidStop(_ connection: UDPServerConnection) {
        self.connectionsByID.removeValue(forKey: connection.id)
        print("server did close connection \(connection.id)")
    }
    
    private func stop() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        self.listener.cancel()
        for connection in self.connectionsByID.values {
            connection.didStopCallback = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
    }
}


