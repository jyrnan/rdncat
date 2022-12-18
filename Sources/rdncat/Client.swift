import Foundation
import Network

@available(macOS 10.14, *)
class Client {
    let connection: ClientConnection
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    
    init(host: String, port: UInt16) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        
        //自定义TcpOption，增加心跳设置? 看不到发送心跳包
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2
        tcpOptions.keepaliveCount = 2
        tcpOptions.keepaliveInterval = 2
        
        let parameters:NWParameters
//
        if #available(macOS 10.15, *) {
//            parameters = NWParameters(tls: NWParameters.tlsOptions(passcode: "8888"),tcp: tcpOptions)
            parameters = NWParameters(tls: nil,tcp: tcpOptions)
            
        } else {
            parameters = NWParameters(tls: nil, tcp: tcpOptions)
        }
        
        let nwConnection = NWConnection(host: self.host, port: self.port, using: parameters)
        connection = ClientConnection(nwConnection: nwConnection)
    }
    
    func start() {
        print("Client started \(host) \(port)")
        connection.didStopCallback = didStopCallback(error:)
        connection.start()
    }
    
    func stop() {
        connection.stop()
    }
    
    func send(data: Data) {
        connection.send(data: data)
    }
    
    func didStopCallback(error: Error?) {
        if error == nil {
            exit(EXIT_SUCCESS)
        } else {
            exit(EXIT_FAILURE)
        }
    }
}
