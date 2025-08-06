//
//  AudioManager.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import AVFoundation
import SwiftUI

@MainActor
class AudioManager {
    static let shared = AudioManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var isInitialized = false
    
    private init() {
        setupAudioSession()
        loadBackgroundMusic()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func loadBackgroundMusic() {
        guard let musicURL = Bundle.main.url(forResource: "theme", withExtension: "mp3") else {
            print("Could not find theme.mp3 in app bundle")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = 0.1
            backgroundMusicPlayer?.prepareToPlay()
            isInitialized = true
        } catch {
            print("Failed to load background music: \(error)")
        }
    }
    
    func startBackgroundMusic() {
        guard isInitialized, let player = backgroundMusicPlayer else { return }
        
        if !player.isPlaying {
            player.play()
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer?.currentTime = 0
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        backgroundMusicPlayer?.play()
    }
    
    var isPlaying: Bool {
        return backgroundMusicPlayer?.isPlaying ?? false
    }
}
