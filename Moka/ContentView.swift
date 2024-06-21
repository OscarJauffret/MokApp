//
//  ContentView.swift
//  Moka
//
//  Created by Oscar on 18/06/2024.
//

import SwiftUI
import AVKit

enum Voices: String, CaseIterable {
    case Papa, Maman, Héloïse, Oscar, Augustine
}

struct ContentView: View {
    @State private var client: SocketClient?
    @State private var isAppOn = false
    @State private var isAppOnManual = true
    @State private var selectedVoice: Voices = .Papa
    @State private var alertRecord = false
    @State private var alertVoiceInfo = false
    @Environment(\.scenePhase) private var scenePhase
    
    
    fileprivate func allowMicrophoneAccessAlert() -> Alert {
        return Alert(title: Text("Erreur"), message: Text("Vous pouvez autoriser l'accès au microphone dans les réglages"))
    }
    
    fileprivate func voiceSelectionInformationAlert() -> Alert {
        return Alert(
            title: Text("Information"),
            message: Text("Cette voix sera utilisée pour réprimander Moka manuellement"),
            dismissButton: .default(Text("Ok"))
        )
    }
    
    fileprivate func resetServerConnectionAfterBackground() {
        if scenePhase == .inactive {
            self.client?.closeConnection()
            print("App moved to background or became inactive, connection closed.")
        }
    }
    
    fileprivate func processReceivedAppState(data: String?) {
        guard let data = data else {
            print("Received data is nil")
            return
        }
        let cleanData = String(data.split(separator: "END_OF_MESSAGE")[0])
        self.isAppOnManual = false
        switch cleanData {
        case "0":
            isAppOn = false
        case "1":
            isAppOn = true
        default:
            break
        }
        self.isAppOnManual = true
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Outils")) {
                        Toggle("Allumer", isOn: $isAppOn)
                            .onChange(of: isAppOn) {
                                if self.isAppOnManual {
                                    if isAppOn {
                                        self.client?.sendData(message: "1")
                                    } else {
                                        self.client?.sendData(message: "0")
                                    }
                                }
                                self.isAppOnManual = true
                            }
                        HStack {
                            Picker("Sélectionnez une voix", selection: $selectedVoice) {
                                ForEach(Voices.allCases, id: \.self) { voice in
                                    Text(voice.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(!isAppOn)
                            Button(action: {
                                self.alertVoiceInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Color.blue)
                            }
                        }
                        HStack {
                            Button(action: {
                                self.client?.sendData(message: "2")
                            }) {
                                Text("Réprimander manuellement")
                            }
                            .disabled(!isAppOn)
                        }
                    }
                    Section {
                        NavigationLink(destination: AudioRecording(client: self.client, voice: self.selectedVoice)) {
                            Text("Enregistrer un nouveau message")
                        }
                        .disabled(!isAppOn)
                    }
                }
            }
            .navigationTitle("Moka")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink (destination: ParametersView(client: self.client)) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .padding()
                            .foregroundColor(.blue)
                    }
                    .disabled(!isAppOn)
                }
            }
        }
        .alert(isPresented: self.$alertRecord) {
            allowMicrophoneAccessAlert()
        }
        .alert(isPresented: self.$alertVoiceInfo) {
            voiceSelectionInformationAlert()
        }
        .task {
            await setupClientAndSession()
        }
        .onChange(of: scenePhase) {
            resetServerConnectionAfterBackground()
        }
    }
    
    func setupClientAndSession() async {
        if self.client == nil {
            self.client = SocketClient()
            self.client?.start()
        }
        self.client?.dataReceivedCallback = { data in
            self.processReceivedAppState(data: data)
        }
        self.client?.sendData(message: "REQUEST_APP_STATE")
        self.client?.receiveData()
        /*do {
            self.session = AVAudioSession.sharedInstance()
            try self.session.setCategory(.playAndRecord)
            
            let permission = await AVAudioApplication.requestRecordPermission()
            if !permission {
                self.alertRecord.toggle()
            }
        } catch {
            print(error.localizedDescription)
        }*/
    }
}


#Preview {
    ContentView()
}

