//
//  AudioPlayerManager.swift
//  player
//
//  Audio player manager supporting FLAC, ALAC, WAV, MP3 formats
//

import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTrack: URL?
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var playerNode: AVAudioPlayerNode?
    private var timer: Timer?
    private var engineStartTime: TimeInterval = 0
    private var enginePausedTime: TimeInterval = 0
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func loadAudioFile(url: URL) {
        stop()
        currentTrack = url
        errorMessage = nil
        
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "mp3", "wav", "alac", "m4a":
            loadWithAVAudioPlayer(url: url)
        case "flac":
            loadFLACWithEngine(url: url)
        default:
            // Попробуем оба метода
            if !loadWithAVAudioPlayer(url: url) {
                loadFLACWithEngine(url: url)
            }
        }
    }
    
    private func loadWithAVAudioPlayer(url: URL) -> Bool {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            if let player = audioPlayer {
                duration = player.duration
                return true
            }
        } catch {
            print("AVAudioPlayer failed: \(error)")
            return false
        }
        return false
    }
    
    private func loadFLACWithEngine(url: URL) {
        do {
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            guard let engine = audioEngine, let node = playerNode else {
                errorMessage = "Не удалось инициализировать аудио движок"
                return
            }
            
            audioFile = try AVAudioFile(forReading: url)
            
            guard let file = audioFile else {
                errorMessage = "Не удалось загрузить аудио файл"
                return
            }
            
            let format = file.processingFormat
            let frameCount = UInt32(file.length)
            
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            
            duration = Double(frameCount) / format.sampleRate
            enginePausedTime = 0
            engineStartTime = 0
            
            try engine.start()
        } catch {
            print("AVAudioEngine failed: \(error)")
            errorMessage = "Ошибка загрузки файла: \(error.localizedDescription)"
        }
    }
    
    func play() {
        if let player = audioPlayer {
            player.play()
            isPlaying = true
            startTimer()
        } else if let node = playerNode, let file = audioFile {
            if !node.isPlaying {
                if enginePausedTime > 0 {
                    // Resume from paused position
                    let frame = AVAudioFramePosition(enginePausedTime * file.processingFormat.sampleRate)
                    let remainingFrames = AVAudioFrameCount(file.length - frame)
                    node.scheduleSegment(file, startingFrame: frame, frameCount: remainingFrames, at: nil) { [weak self] in
                        DispatchQueue.main.async {
                            self?.isPlaying = false
                            self?.stopTimer()
                            self?.currentTime = self?.duration ?? 0
                        }
                    }
                    engineStartTime = Date().timeIntervalSince1970 - enginePausedTime
                } else {
                    // Start from beginning
                    node.scheduleFile(file, at: nil) { [weak self] in
                        DispatchQueue.main.async {
                            self?.isPlaying = false
                            self?.stopTimer()
                            self?.currentTime = self?.duration ?? 0
                        }
                    }
                    engineStartTime = Date().timeIntervalSince1970
                }
                node.play()
                isPlaying = true
                startTimer()
            }
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        if let node = playerNode {
            node.pause()
            // Сохраняем текущее время для возобновления
            enginePausedTime = currentTime
        }
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
        currentTime = 0
        enginePausedTime = 0
        engineStartTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        if let player = audioPlayer {
            player.currentTime = time
            currentTime = time
        } else if let node = playerNode, let file = audioFile {
            let wasPlaying = node.isPlaying
            node.stop()
            let frame = AVAudioFramePosition(time * file.processingFormat.sampleRate)
            let remainingFrames = AVAudioFrameCount(file.length - frame)
            node.scheduleSegment(file, startingFrame: frame, frameCount: remainingFrames, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    self?.stopTimer()
                    self?.currentTime = self?.duration ?? 0
                }
            }
            currentTime = time
            enginePausedTime = time
            engineStartTime = Date().timeIntervalSince1970 - time
            if wasPlaying {
                node.play()
            }
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCurrentTime() {
        if let player = audioPlayer {
            currentTime = player.currentTime
        } else if let node = playerNode {
            // Для AVAudioEngine отслеживаем время на основе времени старта
            if isPlaying && node.isPlaying {
                let elapsed = Date().timeIntervalSince1970 - engineStartTime
                currentTime = min(elapsed, duration)
                if currentTime >= duration {
                    currentTime = duration
                    isPlaying = false
                    stopTimer()
                }
            }
        }
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = duration
        stopTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        errorMessage = "Ошибка декодирования: \(error?.localizedDescription ?? "Неизвестная ошибка")"
        isPlaying = false
        stopTimer()
    }
}
