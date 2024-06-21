//
//  Parameters.swift
//  Moka
//
//  Created by Oscar on 20/06/2024.
//

import SwiftUI

struct ParametersView: View {
    @State private var client: SocketClient?
    @State private var thresholds: [Double] = [10.0, 0.7]
    @State private var cooldown: Int = 120
    @State private var isEditingdB = false
    @State private var isEditingResemblance = false
    @State private var receivedData: String? = nil
    @Environment(\.colorScheme) var colorScheme
    
    init(client: SocketClient?) {
        _client = State(initialValue: client)
    }

    func processReceivedData(data: String?) {
        guard let data = data else {
            print("Received data is nil")
            return
        }
        // Parse the received data
        let parsedData = parseDataString(data)
        
        // Update the thresholds and cooldown
        for item in parsedData {
            switch item.1 {
            case "noise_threshold":
                self.thresholds[0] = item.2 as! Double
            case "resemblance_threshold":
                self.thresholds[1] = item.2 as! Double
            case "cooldown":
                self.cooldown = item.2 as! Int
            default:
                break
            }
        }
        print("New parameters are: \(thresholds[0]), \(thresholds[1])")
    }
    
    func parseDataString(_ data: String) -> [(Int, String, Any)] {
        // Assuming data format: [(1, 'noise_threshold', 10.0), (2, 'resemblance_threshold', 0.7), (3, 'cooldown', 120.0)]
        var result: [(Int, String, Any)] = []
        let cleanedData = data.replacingOccurrences(of: "[", with: "")
                                .replacingOccurrences(of: "]", with: "")
                                .replacingOccurrences(of: "(", with: "")
                                .replacingOccurrences(of: ")", with: "")
        
        let items = cleanedData.split(separator: ",")
        var currentItem: [String] = []
        
        for item in items {
            let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
            currentItem.append(trimmedItem)
            if currentItem.count == 3 {
                if let id = Int(currentItem[0]),
                   let value = Double(currentItem[2]) {
                    let name = currentItem[1].replacingOccurrences(of: "'", with: "")
                    result.append((id, name, value))
                }
                currentItem.removeAll()
            }
        }
        return result
    }
    
    var body: some View {
        VStack {
            Text("Paramètres")
                .font(.largeTitle)
                .padding()
                .onDisappear {
                    //self.client
                    self.client?.sendData(message: "2 \(thresholds)")
                }
            HStack {
                Text(String(format: "Seuil de dB requis : %.0f", thresholds[0]))
                    .foregroundColor(isEditingdB ? .blue : (colorScheme == .dark ? .white : .black))
                    .padding()
                Spacer()
                Slider(value: $thresholds[0], in: 0...20, onEditingChanged: {
                    editing in isEditingdB = editing
                })
                .padding()
                .frame(width: 180)
            }
            HStack {
                Text(String(format: "Ressemblance : %.0f%%", thresholds[1] * 100))
                    .foregroundColor(isEditingResemblance ? .blue : (colorScheme == .dark ? .white : .black))
                    .padding()
                Spacer()
                Slider(value: $thresholds[1], in: 0...1, onEditingChanged: {
                    editing in isEditingResemblance = editing
                })
                .padding()
                .frame(width: 180)
            }
            
        }
        .onAppear {
            /*
            self.client?.dataReceivedCallback = { data in
                self.processReceivedData(data: data)
            }
            self.client?.sendData(message: "REQUEST_PARAMETERS")
            self.client?.receiveData()
             */
        }
    }
}


