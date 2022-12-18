//
//  File.swift
//  
//
//  Created by jyrnan on 2022/12/18.
//

import Foundation
import Network

@available(macOS 11.0, *)
class MulticastClient {
    let connection: NWConnectionGroup
    
    init() {
        let multicastDescriptor = try! NWMulticastGroup(for: [.hostPort(host: "224.0.0.1", port: 8899)])
        self.connection = NWConnectionGroup(with: multicastDescriptor, using: .udp)
    }
    
    
    func start() {
        connection.setReceiveHandler{message, data, bool in
            print("🧑‍💻 Received message:")
            if let data = data {
                print(String(data: data, encoding: .utf8))
            }
        }
        
        connection.stateUpdateHandler = { (newState) in
            print("Group entered state \(String(describing: newState))")
        }
        
        connection.start(queue: .global())
    }
    
    func send(data:Data) {
        let content = "Hello".data(using: .utf8)
        connection.send(content: content) {error in
            if error != nil {
                print("Some error: \(error?.debugDescription)")
            }
        }
    }
}
