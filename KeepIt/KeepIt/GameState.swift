//
//  GameState.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import SwiftUI
import Combine
import RealityKit

enum GamePhase {
    case menu
    case playing
    case paused
    case gameOver
}

struct Ball: Equatable {
    let id = UUID()
    var startPosition: SIMD3<Float>
    var targetPosition: SIMD3<Float>
    var speed: Float
    var isActive: Bool = true
    
    static func == (lhs: Ball, rhs: Ball) -> Bool {
        return lhs.id == rhs.id
    }
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
    @Published var activeBalls: [Ball] = []
    @Published var countdownValue: Int = 0
    @Published var showCountdown: Bool = false
    
    private let audioManager = AudioManager.shared
    private var gameUpdateTimer: Timer?
    private var countdownTimer: Timer?
    
    init() {
        // Start background music when game state is initialized
        if audioEnabled {
            audioManager.startBackgroundMusic()
        }
    }
    
    deinit {
        gameUpdateTimer?.invalidate()
        gameUpdateTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    func startNewGame() {
        currentPhase = .playing
        score = 0
        currentLevel = 1
        hasSavedGame = false
        activeBalls.removeAll()
        
        // Start countdown for first ball (3 second delay)
        startCountdown()
        startGameTimer()
    }
    
    func continueGame() {
        currentPhase = .playing
        startGameTimer()
    }
    
    func pauseGame() {
        currentPhase = .paused
        hasSavedGame = true
        stopGameTimer()
        stopCountdownTimer()
    }
    
    func returnToMenu() {
        currentPhase = .menu
        stopGameTimer()
        stopCountdownTimer()
        activeBalls.removeAll()
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
    
    // MARK: - Ball System
    func spawnBall() {
        // Remove existing ball (only allow 1 ball at a time)
        activeBalls.removeAll()
        
        // Start in front of user (negative Z) with random spread
        let startX = Float.random(in: -10...10)
        let startY = Float.random(in: 0.5...4.0)
        let startZ: Float = Float.random(in: -25.0...(-15.0))
        let startPosition = SIMD3<Float>(startX, startY, startZ)
        
        // Target behind user (positive Z)
        let targetX = Float.random(in: -5...5)
        let targetY = Float.random(in: -1.0...2.0)
        let targetZ: Float = Float.random(in: 25.0...35.0)
        let targetPosition = SIMD3<Float>(targetX, targetY, targetZ)
        
        let ball = Ball(
            startPosition: startPosition,
            targetPosition: targetPosition,
            speed: 8.0
        )
        
        activeBalls.append(ball)
        print("⚽ Ball spawned: \(startPosition) → \(targetPosition)")
    }
    
    @objc func updateGame() {
        guard currentPhase == .playing else { return }
        
        // This will be called every ~5 seconds by the timer
        spawnBall()
    }
    
    func startGameTimer() {
        stopGameTimer()
        
        // Spawn new ball every 5 seconds (but first ball is delayed by countdown)
        gameUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.startCountdown()
        }
        
        print("⏰ Game timer started - new ball every 5 seconds")
    }
    
    func stopGameTimer() {
        gameUpdateTimer?.invalidate()
        gameUpdateTimer = nil
    }
    
    func startCountdown() {
        stopCountdownTimer()
        countdownValue = 3
        showCountdown = true
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.countdownValue > 1 {
                self.countdownValue -= 1
            } else {
                self.showCountdown = false
                self.stopCountdownTimer()
                // Spawn ball when countdown reaches 1
                self.spawnBall()
            }
        }
    }
    
    func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        showCountdown = false
    }
}
