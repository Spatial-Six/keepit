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
            switch gameState.currentPhase {
            case .menu:
                MainMenuView(gameState: gameState)
            case .playing:
                GameplayView(gameState: gameState)
            case .paused:
                PauseView(gameState: gameState)
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

// Placeholder views for different game states
struct GameplayView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack {
            Text("Game Playing")
                .font(.largeTitle)
                .foregroundStyle(.white)
            
            Button("Pause") {
                gameState.pauseGame()
            }
            .buttonStyle(MenuButtonStyle())
        }
    }
}

struct PauseView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Paused")
                .font(.largeTitle)
                .foregroundStyle(.white)
            
            Button("Continue") {
                gameState.continueGame()
            }
            .buttonStyle(MenuButtonStyle())
            
            Button("Main Menu") {
                gameState.returnToMenu()
            }
            .buttonStyle(MenuButtonStyle())
        }
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
