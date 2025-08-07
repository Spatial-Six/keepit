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
                case .menu, .gameOver:
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
                
                // Score display in top right corner
                Text("Score: \(gameState.score)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial, style: FillStyle())
                            .overlay(
                                Capsule()
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
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gameState.feedbackColor, gameState.feedbackColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 6)
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: gameState.showFeedback)
                    
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

struct GameOverView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.largeTitle)
                .foregroundStyle(.white)
            
            Text("Score: \(gameState.score)")
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
