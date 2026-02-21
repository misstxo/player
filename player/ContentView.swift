//
//  ContentView.swift
//  player
//
//  Main player interface
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var playerManager = AudioPlayerManager()
    @State private var showingFilePicker = false
    @State private var selectedFile: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Информация о треке
                VStack(spacing: 10) {
                    if let track = playerManager.currentTrack {
                        Text(track.lastPathComponent)
                            .font(.headline)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(formatDuration(playerManager.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Выберите аудио файл")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 80)
                
                // Прогресс бар
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { playerManager.currentTime },
                            set: { playerManager.seek(to: $0) }
                        ),
                        in: 0...max(playerManager.duration, 1)
                    )
                    .disabled(playerManager.duration == 0)
                    
                    HStack {
                        Text(formatDuration(playerManager.currentTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(playerManager.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Кнопки управления
                HStack(spacing: 40) {
                    Button(action: {
                        if let track = selectedFile {
                            playerManager.loadAudioFile(url: track)
                            playerManager.play()
                        }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .disabled(selectedFile == nil)
                    
                    Button(action: {
                        if playerManager.isPlaying {
                            playerManager.pause()
                        } else {
                            if playerManager.currentTrack == nil, let track = selectedFile {
                                playerManager.loadAudioFile(url: track)
                            }
                            playerManager.play()
                        }
                    }) {
                        Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .disabled(selectedFile == nil && playerManager.currentTrack == nil)
                    
                    Button(action: {
                        playerManager.stop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .disabled(!playerManager.isPlaying && playerManager.currentTrack == nil)
                }
                .padding(.vertical)
                
                // Кнопка выбора файла
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("Выбрать аудио файл")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Сообщение об ошибке
                if let error = playerManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Аудио Плеер")
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [
                    .audio,
                    UTType(filenameExtension: "flac")!,
                    UTType(filenameExtension: "alac")!,
                    UTType(filenameExtension: "wav")!,
                    UTType(filenameExtension: "mp3")!
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        _ = url.startAccessingSecurityScopedResource()
                        selectedFile = url
                        playerManager.loadAudioFile(url: url)
                    }
                case .failure(let error):
                    playerManager.errorMessage = "Ошибка выбора файла: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        guard !duration.isNaN && !duration.isInfinite else {
            return "0:00"
        }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
