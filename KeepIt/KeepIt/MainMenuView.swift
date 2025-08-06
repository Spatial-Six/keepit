//
//  MainMenuView.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import SwiftUI

struct MainMenuView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title
            Text("Keep It!")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Spacer()
            
            // Menu Buttons
            VStack(spacing: 20) {
                // Start Game Button
                Button("Start Game") {
                    gameState.startNewGame()
                }
                .buttonStyle(MenuButtonStyle())
                
                // Continue Button (only if saved game exists)
                if gameState.hasSavedGame {
                    Button("Continue") {
                        gameState.continueGame()
                    }
                    .buttonStyle(MenuButtonStyle())
                }
                
                // Audio Toggle
                HStack {
                    Button(action: {
                        gameState.toggleAudio()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: gameState.audioEnabled ? "checkmark.square.fill" : "square")
                                .font(.title2)
                                .foregroundStyle(.white)
                            
                            Text("Audio")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.6))
                    .stroke(.white.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    MainMenuView(gameState: GameState())
        .background(.black)
}