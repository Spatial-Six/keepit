//
//  GameState.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import SwiftUI
import Combine

enum GamePhase {
    case menu
    case playing
    case paused
    case gameOver
}

@MainActor
class GameState: ObservableObject {
    @Published var currentPhase: GamePhase = .menu
    @Published var audioEnabled: Bool = true {
        didSet {
            handleAudioToggle()
        }
    }
    @Published var hasSavedGame: Bool = false
    @Published var score: Int = 0
    @Published var currentLevel: Int = 1
    @Published var showImmersiveSpace: Bool = true
    
    private let audioManager = AudioManager.shared
    
    init() {
        // Start background music when game state is initialized
        if audioEnabled {
            audioManager.startBackgroundMusic()
        }
    }
    
    func startNewGame() {
        currentPhase = .playing
        score = 0
        currentLevel = 1
        hasSavedGame = false
    }
    
    func continueGame() {
        currentPhase = .playing
    }
    
    func pauseGame() {
        currentPhase = .paused
        hasSavedGame = true
    }
    
    func returnToMenu() {
        currentPhase = .menu
    }
    
    func toggleAudio() {
        audioEnabled.toggle()
    }
    
    private func handleAudioToggle() {
        if audioEnabled {
            audioManager.startBackgroundMusic()
        } else {
            audioManager.stopBackgroundMusic()
        }
    }
}
