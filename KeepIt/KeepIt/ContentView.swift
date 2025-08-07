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
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
