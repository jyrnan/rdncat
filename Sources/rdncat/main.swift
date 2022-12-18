import Foundation
import Network


if #available(macOS 11.0, *) {
var isServer = false

func initServer(port: UInt16) {
//    let server = UDPServer(port: port)
//    try! server.start()
    let server = MulticastClient()
    server.start()
}

func initClient(server: String, port: UInt16) {
    let client = UDPClient(host: server, port: port)
    client.start()
    while(true) {
      var command = readLine(strippingNewline: true)
      switch (command){
      case "CRLF":
          command = "\r\n"
      case "RETURN":
          command = "\n"
      case "exit":
          client.stop()
      case "bingo":
          command = makeLongStr()
      case "oneTime":
          client.connection.nwConnection.send(content: "oneTime".data(using: .utf8)!, contentContext: NWConnection.ContentContext.finalMessage, isComplete: true, completion: .contentProcessed{_ in})
      default:
          break
      }
      client.connection.send(data: (command?.data(using: .utf8))!)
    }
}
    
func makeLongStr() -> String {
    return Array(repeating: "A", count: 20).joined() + "end"
}
    
guard CommandLine.arguments.count >= 2 else {
    print("Hello, world!")
    exit(EXIT_FAILURE)
}

let firstArgument = CommandLine.arguments[1]
switch (firstArgument) {
case "-l":
    isServer = true
default:
    break
}

if isServer {
    if let port = UInt16(CommandLine.arguments[2]) {
      initServer(port: port)
    } else {
        print("Error invalid port")
    }
} else {
    let server = CommandLine.arguments[1]
    if let port = UInt16(CommandLine.arguments[2]) {
      initClient(server: server, port: port)
    } else {
        print("Error invalid port")
    }
}
RunLoop.current.run()

} else {
  let stderr = FileHandle.standardError
  let message = "Requires macOS 10.14 or newer"
  stderr.write(message.data(using: .utf8)!)
  exit(EXIT_FAILURE)
}
