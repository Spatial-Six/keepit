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
    case levelComplete
    case gameComplete
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
    @Published var totalScore: Int = 0
    @Published var currentLevel: Int = 1
    @Published var levelScore: Int = 0
    @Published var ballsSpawned: Int = 0
    @Published var ballsCompleted: Int = 0
    @Published var showImmersiveSpace: Bool = true
    @Published var activeBalls: [Ball] = []
    @Published var countdownValue: Int = 0
    @Published var showCountdown: Bool = false
    @Published var showFeedback: Bool = false
    @Published var feedbackText: String = ""
    @Published var feedbackColor: Color = .green
    
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
        totalScore = 0
        currentLevel = 1
        levelScore = 0
        ballsSpawned = 0
        ballsCompleted = 0
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
    
    // MARK: - Level Management
    func getBallSpeed() -> Float {
        switch currentLevel {
        case 1: return 8.0
        case 2: return 15.0
        case 3: return 20.0
        default: return 8.0
        }
    }
    
    func checkLevelComplete() {
        if ballsCompleted >= 10 {
            currentPhase = .levelComplete
            stopGameTimer()
            stopCountdownTimer()
        }
    }
    
    func ballSaved() {
        levelScore += 1
        totalScore += 1
        ballsCompleted += 1
        checkLevelComplete()
    }
    
    func ballMissed() {
        ballsCompleted += 1
        checkLevelComplete()
    }
    
    func nextLevel() {
        if currentLevel >= 3 {
            // Game completed!
            currentPhase = .gameComplete
        } else {
            currentLevel += 1
            levelScore = 0
            ballsSpawned = 0
            ballsCompleted = 0
            activeBalls.removeAll()
            currentPhase = .playing
            startCountdown()
            startGameTimer()
        }
    }
    
    func retryLevel() {
        levelScore = 0
        ballsSpawned = 0
        ballsCompleted = 0
        activeBalls.removeAll()
        currentPhase = .playing
        startCountdown()
        startGameTimer()
    }
    
    func levelPassed() -> Bool {
        return levelScore >= 5
    }
    
    // MARK: - Ball System
    func spawnBall() {
        // Check if we've spawned enough balls for this level
        if ballsSpawned >= 10 {
            return
        }
        
        // Remove existing ball (only allow 1 ball at a time)
        activeBalls.removeAll()
        
        // Increment balls spawned counter
        ballsSpawned += 1
        
        // Start in front of user (negative Z) with random spread
        let startX = Float.random(in: -10...10)
        let startY = Float.random(in: 0.5...4.0)
        let startZ: Float = Float.random(in: -25.0...(-15.0))
        let startPosition = SIMD3<Float>(startX, startY, startZ)
        
        // Target toward actual goal position (matches ImmersiveView goal at Z=2.0)
        let goalCenterX: Float = 0.0
        let goalCenterY: Float = 0.5  // Goal center height above ground
        let goalCenterZ: Float = 2.0  // Actual goal position (2m behind user)
        
        let goalWidth: Float = 1.0   // Half-width for targeting inside opening
        let goalHeight: Float = 1.0  // Height from ground level
        
        let targetX = Float.random(in: (goalCenterX - goalWidth)...(goalCenterX + goalWidth))
        let targetY = Float.random(in: goalCenterY...(goalCenterY + goalHeight))
        let targetZ = goalCenterZ + 1.8 // Target exactly at goal plane
        let targetPosition = SIMD3<Float>(targetX, targetY, targetZ)
        
        let ball = Ball(
            startPosition: startPosition,
            targetPosition: targetPosition,
            speed: getBallSpeed()
        )
        
        activeBalls.append(ball)
        print("⚽ Ball \(ballsSpawned)/10 spawned at speed \(getBallSpeed()): \(startPosition) → \(targetPosition)")
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
            Task { @MainActor in
                self.startCountdown()
            }
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
            Task { @MainActor in
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
    }
    
    func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        showCountdown = false
    }
    
    // MARK: - Feedback System
    func showSaveFeedback() {
        feedbackText = "SAVE!"
        feedbackColor = .green
        showFeedback = true
        
        // Auto-hide after 1.5 seconds
        Task {
            try await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                showFeedback = false
            }
        }
    }
    
    func showMissFeedback() {
        feedbackText = "MISS!"
        feedbackColor = .red
        showFeedback = true
        
        // Auto-hide after 1.5 seconds
        Task {
            try await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                showFeedback = false
            }
        }
    }
}
