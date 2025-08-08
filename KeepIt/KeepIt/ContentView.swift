//
//  ContentView.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        ZStack {
            // Always show immersive space content (football field)
            Color.clear
            
            // Overlay UI based on game state
            switch gameState.currentPhase {
            case .menu, .paused:
                MainMenuView(gameState: gameState)
            case .playing:
                GameplayView(gameState: gameState)
            case .levelComplete:
                LevelCompleteView(gameState: gameState)
            case .gameComplete:
                GameCompleteView(gameState: gameState)
            case .gameOver:
                GameOverView(gameState: gameState)
            }
        }
        .onAppear {
            Task {
                if gameState.showImmersiveSpace {
                    await openImmersiveSpace(id: "ImmersiveSpace")
                }
            }
        }
        .onChange(of: gameState.currentPhase) { oldValue, newValue in
            Task {
                switch newValue {
                case .menu, .gameOver, .levelComplete, .gameComplete:
                    if gameState.showImmersiveSpace {
                        await openImmersiveSpace(id: "ImmersiveSpace")
                    }
                case .playing, .paused:
                    break
                }
            }
        }
    }
}

// Gameplay view - only shows pause button in top left corner
struct GameplayView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack {
            HStack {
                // Persistent pause button in top left corner
                Button(action: {
                    gameState.pauseGame()
                }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial, style: FillStyle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                        .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 20)
                .padding(.leading, 20)
                
                Spacer()
                
                // Level and score display in top right corner
                VStack(alignment: .trailing, spacing: 8) {
                    Text("LEVEL \(gameState.currentLevel)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                    
                    Text("BALL \(gameState.ballsSpawned)/10")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("SCORE: \(gameState.levelScore)/\((gameState.ballsCompleted*100))")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                    
                    Text("TOTAL: \(gameState.totalScore)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    // Current level reaction time with larger numbers
                    HStack(spacing: 2) {
                        Text("RT: ")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.orange)
                        Text(String(format: "%.2f", gameState.getReactionTime(for: gameState.currentLevel)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                        Text("s")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial, style: FillStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1)
                .padding(.top, 20)
                .padding(.trailing, 20)
            }
            
            // Countdown display in center
            if gameState.showCountdown {
                VStack {
                    Spacer()
                    
                    Text("\(gameState.countdownValue)")
                        .font(.system(size: 150, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.2), value: gameState.countdownValue)
                    
                    Spacer()
                }
            }
            // Feedback display in center (SAVE/MISS)
            else if gameState.showFeedback {
                VStack {
                    Spacer()
                    
                    Text(gameState.feedbackText)
                        .font(.system(size: gameState.feedbackText.contains("\n") ? 60 : 120, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gameState.feedbackColor, gameState.feedbackColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 6)
                        .scaleEffect(gameState.feedbackText.contains("\n") ? 1.0 : 1.2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: gameState.showFeedback)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                }
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Screen color flash overlay
        .overlay(
            Rectangle()
                .fill(gameState.feedbackColor.opacity(gameState.showFeedback ? 0.1 : 0.0))
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: gameState.showFeedback)
        )
    }
}

struct LevelCompleteView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 30) {
            if gameState.levelPassed() {
                Text("Level \(gameState.currentLevel) Passed!")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                    .fontWeight(.bold)
            } else {
                Text("Level \(gameState.currentLevel) Failed!")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 15) {
                Text("Level Score: \(gameState.levelScore)")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text("Total Score: \(gameState.totalScore)")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                
                // Reaction Time Information with larger numbers
                VStack(spacing: 5) {
                    let components = gameState.getReactionTimeComponents()
                    
                    if components.numbers.count == 1 {
                        // Single number case
                        HStack(spacing: 4) {
                            Text(components.prefix)
                                .font(.title3)
                                .foregroundStyle(.cyan)
                            Text(String(format: "%.2f", components.numbers[0]))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.cyan)
                            Text(components.suffix)
                                .font(.title3)
                                .foregroundStyle(.cyan)
                        }
                    } else {
                        // Two numbers case (range)
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Text(components.prefix)
                                    .font(.title3)
                                    .foregroundStyle(.cyan)
                                Text(String(format: "%.2f", components.numbers[0]))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.cyan)
                                Text("to")
                                    .font(.title3)
                                    .foregroundStyle(.cyan)
                                Text(String(format: "%.2f", components.numbers[1]))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.cyan)
                            }
                            Text(components.suffix)
                                .font(.title3)
                                .foregroundStyle(.cyan)
                        }
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(15)
            
            HStack(spacing: 20) {
                if gameState.levelPassed() {
                    if gameState.currentLevel < 5 {
                        Button("Next Level") {
                            gameState.nextLevel()
                        }
                        .buttonStyle(MenuButtonStyle())
                    } else {
                        Button("Complete Game") {
                            gameState.nextLevel()
                        }
                        .buttonStyle(MenuButtonStyle())
                    }
                } else {
                    Button("Retry Level") {
                        gameState.retryLevel()
                    }
                    .buttonStyle(MenuButtonStyle())
                }
                
                Button("Main Menu") {
                    gameState.returnToMenu()
                }
                .buttonStyle(MenuButtonStyle())
            }
        }
        .padding()
    }
}

struct GameCompleteView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🏆 Game Complete! 🏆")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
                .fontWeight(.bold)
            
            Text("Congratulations!")
                .font(.title)
                .foregroundStyle(.white)
            
            VStack(spacing: 15) {
                Text("Final Score: \(gameState.totalScore)")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                
                Text("All 5 levels completed!")
                    .font(.title3)
                    .foregroundStyle(.green)
                
                // Show final reaction time achievement with larger number
                VStack(spacing: 5) {
                    HStack(spacing: 4) {
                        Text("You achieved a best reaction time of")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                        Text(String(format: "%.2f", gameState.getReactionTime(for: 5)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.cyan)
                        Text("seconds!")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(15)
            
            HStack(spacing: 20) {
                Button("Play Again") {
                    gameState.startNewGame()
                }
                .buttonStyle(MenuButtonStyle())
                
                Button("Main Menu") {
                    gameState.returnToMenu()
                }
                .buttonStyle(MenuButtonStyle())
            }
        }
        .padding()
    }
}

struct GameOverView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.largeTitle)
                .foregroundStyle(.white)
            
            Text("Score: \(gameState.totalScore)")
                .font(.title)
                .foregroundStyle(.white)
            
            Button("Play Again") {
                gameState.startNewGame()
            }
            .buttonStyle(MenuButtonStyle())
            
            Button("Main Menu") {
                gameState.returnToMenu()
            }
            .buttonStyle(MenuButtonStyle())
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(GameState())
}
