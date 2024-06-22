//
//  Parameters.swift
//  Moka
//
//  Created by Oscar on 20/06/2024.
//

import SwiftUI

struct ParametersView: View {
    @State private var client: SocketClient?
    @State private var parameters: [Double] = [10.0, 0.7, 120, 2]
    @State private var dBThresholdsBounds: [Double] = [0, 20]
    @State private var resemblanceThresholdsBounds: [Double] = [0, 1]
    @State private var showConfirmationAlert = false
    @State private var cooldownBounds: [Double] = [60, 300]
    @State private var delayBounds: [Double] = [0, 5]
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
        let cleanData = String(data.split(separator: "END_OF_MESSAGE")[0])
        let parsedData = parseDataString(cleanData)
        
        // Update the thresholds and cooldown
        for item in parsedData {
            switch item.0 {
            case "noise_threshold":
                self.parameters[0] = item.1
            case "resemblance_threshold":
                self.parameters[1] = item.1
            case "cooldown":
                self.parameters[2] = item.1
            case "delay":
                self.parameters[3] = item.1
            default:
                break
            }
        }
        print("New parameters are: \(parameters)")
    }
    
    func parseDataString(_ data: String) -> [(String, Double)] {
        var result: [(String, Double)] = []
        let parameters = data.split(separator: ",")
        
        for param in parameters {
            let components = param.split(separator: ":")
            guard components.count == 2 else {
                continue // Ignorer les paires mal formées
            }
            let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let valueStr = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let value = Double(valueStr) {
                result.append((String(name), value))
            }
        }
        return result
    }
    
    fileprivate func resetParameters() -> Alert {
       return Alert(
           title: Text("Êtes-vous sûr ?"),
           message: Text("Voulez-vous réinitialiser les paramètres"),
           primaryButton: .default(Text("Oui")) {
               self.parameters = [10.0, 0.7, 120.0, 2]
           },
           secondaryButton: .default(Text("Annuler"))
       )
   }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Seuil de détection") {
                        HStack {
                            Text("\(Int(self.dBThresholdsBounds[0])) dB")
                            Slider(value: $parameters[0], in: self.dBThresholdsBounds[0]...self.dBThresholdsBounds[1])
                            Text("\(Int(self.dBThresholdsBounds[1])) dB")
                        }
                    }
                    Section("Dergé de ressemblance") {
                        HStack {
                            Text("\(Int(self.resemblanceThresholdsBounds[0]) * 100)%")
                            Slider(value: $parameters[1], in: self.resemblanceThresholdsBounds[0]...self.resemblanceThresholdsBounds[1])
                            Text("\(Int(self.resemblanceThresholdsBounds[1]) * 100)%")
                        }
                    }
                    Section("Temps d'attente entre les messages") {
                        HStack {
                            Text("\(Int(self.cooldownBounds[0]) / 60) min.")
                            Slider(value: $parameters[2], in: self.cooldownBounds[0]...self.cooldownBounds[1])
                            Text("\(Int(self.cooldownBounds[1]) / 60) min.")
                        }
                    }
                    Section("Délai entre l'aboiement et la réponse") {
                        HStack {
                            Text("\(Int(self.delayBounds[0]))s")
                            Slider(value: $parameters[3], in: self.delayBounds[0]...self.delayBounds[1])
                            Text("\(Int(self.delayBounds[1]))s")
                        }
                    }
                    
                    Button(action: {
                        self.showConfirmationAlert = true
                    }) {
                        Text("Réinitialiser les paramètres")
                            .bold()
                            .foregroundStyle(Color.red)
                    }
                    .alert(isPresented: $showConfirmationAlert) {
                        resetParameters()
                    }
                }
            }
            .navigationTitle("Paramètres")
        }
        .onAppear {
            self.client?.dataReceivedCallback = { data in
                self.processReceivedData(data: data)
            }
            self.client?.sendData(message: "REQUEST_PARAMETERS")
            self.client?.receiveData()
        }
        .onDisappear {
            self.client?.sendData(message: "3 \(parameters)")
        }
    }
}

#Preview {
    ParametersView(client: nil)
}

