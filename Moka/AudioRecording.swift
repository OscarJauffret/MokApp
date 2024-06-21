//
//  AudioRecording.swift
//  Moka
//
//  Created by Oscar on 21/06/2024.
//

import SwiftUI
import AVKit

struct AudioRecording: View {
    @State private var client: SocketClient?
    @State private var selectedVoice: Voices = .Papa
    @State private var recording = false
    @State private var session: AVAudioSession!
    @State private var recorder: AVAudioRecorder!
    @State private var alertSend = false
    @State private var audioFileURL: URL?
    
    init(client: SocketClient?, voice: Voices) {
        _client = State(initialValue: client)
        _selectedVoice = State(initialValue: voice)
    }
    
    fileprivate func saveAudioConfirmationAlert() -> Alert {
        return Alert(
            title: Text("Enregistrer l'audio ?"),
            message: Text("Voulez-vous envoyer ce nouvel enregistrement ?"),
            primaryButton: .default(Text("Envoyer")) {
                if let url = self.audioFileURL {
                    self.client?.sendFile(url: url, sender: selectedVoice)
                    removeAudioFile(url)
                }
            },
            secondaryButton: .cancel()
        )
    }
    
    fileprivate func startRecordingNewAudio() throws {
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
    }
    
    fileprivate func removeAudioFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("File removed successfully")
        } catch {
            print("Failed to remove file: \(error.localizedDescription)")
        }
    }
    
    fileprivate func sendRecordingToServer() {
        self.recorder.stop()
        self.recording.toggle()
        
        self.audioFileURL = self.recorder.url
        //self.alertSend = true
        if let url = self.audioFileURL {
            self.client?.sendFile(url: url, sender: selectedVoice)
            removeAudioFile(url)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Enregistrer un nouveau message") {
                        Picker("Sélectionnez votre voix", selection: $selectedVoice) {
                            ForEach(Voices.allCases, id: \.self) { voice in
                                Text(voice.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        Button(action: {
                            do {
                                if self.recording {
                                    sendRecordingToServer()
                                    return
                                }
                                
                                try startRecordingNewAudio()
                            } catch {
                                print(error.localizedDescription)
                            }
                        }) {
                            HStack {
                                Spacer()
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
                                Spacer()
                            }
                        }
                    }
                }
                Text("Assurez-vous de sélectionner votre voix avant d'enregistrer le message \n\nLe message envoyé à Moka lorsqu'un aboiement est détecté est un message sélectionné aléatoirement parmi les messages d'une personne sélectionnée aléatoirement")
                    .font(.caption)
                    .padding()
                    .foregroundStyle(Color.gray)
            }
        }
        .alert(isPresented: self.$alertSend) {
            saveAudioConfirmationAlert()
        }
        .navigationTitle("Enregistrer")
    }
}

