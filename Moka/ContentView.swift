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
    @State private var isAppOn = true
    @State private var selectedVoice: Voices = .Papa
    @State private var recording = false
    @State private var session: AVAudioSession!
    @State private var recorder: AVAudioRecorder!
    @State private var alertRecord = false
    @State private var alertSend = false
    @State private var alertVoiceInfo = false
    @State private var audioFileURL: URL?
    @State private var currentThresholds: [Double]?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    HStack {
                        Text("Moka")
                            .padding()
                            .font(.largeTitle)
                        Spacer()
                    }
                    Toggle("Allumer", isOn: $isAppOn)
                        .padding()
                        .onChange(of: isAppOn) {
                            if isAppOn {
                                self.client?.sendData(message: "Allumer")
                            } else {
                                self.client?.sendData(message: "Éteindre")
                            }
                        }
                    HStack {
                        Text("Sélectionnez une voix")
                            .padding(.leading)
                        Button(action: {
                            self.alertVoiceInfo = true
                        }) {
                            Image(systemName: "info.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color.blue)
                        }
                        Spacer()
                        Picker("Sélectionner une voix", selection: $selectedVoice) {
                            ForEach(Voices.allCases, id: \.self) { voice in
                                Text(voice.rawValue)
                            }
                        }
                        .padding()
                    }
                    Button(action: {
                        self.client?.sendData(message: "1")
                    }) {
                        Text("Réprimander manuellement")
                    }
                    .padding()
                    Spacer()
                }
                VStack {
                    Spacer()
                    Button(action: {
                        do {
                            if self.recording {
                                self.recorder.stop()
                                self.recording.toggle()
                                
                                self.audioFileURL = self.recorder.url
                                //self.alertSend = true
                                if let url = self.audioFileURL {
                                    self.client?.sendFile(url: url, sender: selectedVoice)
                                    do {
                                        try FileManager.default.removeItem(at: url)
                                        print("File removed successfully")
                                    } catch {
                                        print("Failed to remove file: \(error.localizedDescription)")
                                    }
                                }

                                return
                            }
                            
                            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) [0]
                            let fileName = url.appendingPathComponent("test.m4a")
                            let settings = [
                                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                AVSampleRateKey: 12000,
                                AVNumberOfChannelsKey: 1,
                                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                            ]
                            self.recorder = try AVAudioRecorder(url: fileName, settings: settings)
                            self.recorder.record()
                            self.recording.toggle()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(self.recording ? Color.blue : Color.clear)
                                .frame(width: 50, height: 50)
                            Image(systemName: "mic.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(self.recording ? .white : .blue)
                        }
                    }
                    Text("Cliquez pour enregistrer un nouveau message")
                        .font(.caption)
                    Spacer()
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink (destination: ParametersView(client: self.client)) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .padding()
                                .foregroundColor(.blue)
                        }
                    }
                }
                
            }
            .alert(isPresented: self.$alertSend) {
                Alert(
                    title: Text("Enregistrer l'audio ?"),
                    message: Text("Voulez-vous envoyer ce nouvel enregistrement ?"),
                    primaryButton: .default(Text("Envoyer")) {
                        if let url = self.audioFileURL {
                            self.client?.sendFile(url: url, sender: selectedVoice)
                            do {
                                try FileManager.default.removeItem(at: url)
                                print("File removed successfully")
                            } catch {
                                print("Failed to remove file: \(error.localizedDescription)")
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: self.$alertRecord, content: {
                Alert(title: Text("Erreur"), message: Text("Vous pouvez autoriser l'accès au microphone dans les réglages"))
            })
            .alert(isPresented: self.$alertVoiceInfo) {
                Alert(
                    title: Text("Information"),
                    message: Text("Cette voix sera utilisée pour réprimander Moka manuellement et créer de nouveaux enregistrements"),
                    dismissButton: .default(Text("Ok"))
                )
            }

            .task {
                await setupClientAndSession()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .inactive {
                    self.client?.closeConnection()
                    print("App moved to background or became inactive, connection closed.")
                }
            }
        }
    }
    
    func setupClientAndSession() async {
        if self.client == nil {
            self.client = SocketClient()
            self.client?.start()
        }
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

