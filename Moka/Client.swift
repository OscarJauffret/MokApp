//
//  Client.swift
//  Moka
//
//  Created by Oscar on 20/06/2024.
//

import Foundation
import Network

class SocketClient {
    @Published var receivedData: String?
    let connection: NWConnection
    typealias DataReceivedCallback = (String) -> Void
    var dataReceivedCallback: DataReceivedCallback?
    private var accumulatedData: String = ""

    init() {
        connection = NWConnection(host: "192.168.1.37", port: 8081, using: .tcp) // Port 8081 utilisé
    }

    func start() {
        connection.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                print("Connected to the server")
            case .waiting(let error):
                print("Waiting for connection: \(error)")
            case .failed(let error):
                print("Failed to connect: \(error)")
            default:
                break
            }
        }

        connection.start(queue: .main)
    }
    
    fileprivate func sendTag(_ header: Data?) {
        connection.send(content: header, completion: .contentProcessed({ (error) in
            if let error = error {
                print("Send header error: \(error)")
            } else {
                print("Data sent successfully")
            }
        }))
    }
    
    func sendData(message: String) {
        let data = message.data(using: .utf8)
        sendTag(data)
    }
    
    func sendFile(url: URL, sender: Voices) {
        do {
            let fileData = try Data(contentsOf: url)
            let header = "AUDIO_FILE".data(using: .utf8)
            let tail = "END_OF_FILE_\(sender)".data(using: .utf8)
            sendTag(header)
            sendTag(fileData)
            sendTag(tail)
            
        } catch {
            print("Failed to read file data: \(error.localizedDescription)")
        }
    }
    
    func receiveData() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, context, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(decoding: data, as: UTF8.self)
                self.dataReceivedCallback?(message)

                // Vérifier si le message contient "END_OF_PARAMETERS"
                if message.contains("END_OF_PARAMETERS") {
                    print("Received END_OF_PARAMETERS, stopping reception")
                    return
                }

                // Process the received data
            }
            if let error = error {
                print("Receive error: \(error)")
            } else {
                // Continue to receive more data
                self.receiveData()
            }
        }
    }

    func closeConnection() {
        connection.cancel()
        print("Connection closed")
    }
}
