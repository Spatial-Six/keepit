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
        ZStack {
            // Thick glass background panel
            RoundedRectangle(cornerRadius: 24)
                .fill(.thickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.8), radius: 40, x: 0, y: 20)
                .frame(width: 500, height: 600)
            
            // Content on top
            VStack(spacing: 50) {
                // Title
                Text("Keep It!")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.green.opacity(0.5), radius: 15, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Menu Buttons Container
                VStack(spacing: 24) {
                    // New Game Button
                    Button("New Game") {
                        gameState.startNewGame()
                    }
                    .buttonStyle(MenuButtonStyle())
                    
                    // Continue Button (only if saved game exists)
                    if gameState.hasSavedGame {
                        Button("Continue Game") {
                            gameState.continueGame()
                        }
                        .buttonStyle(MenuButtonStyle())
                    }
                    
                    // Audio Toggle
                    Button(action: {
                        gameState.toggleAudio()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: gameState.audioEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                            
                            Text("Audio \(gameState.audioEnabled ? "On" : "Off")")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.4))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 50)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thickMaterial.opacity(0.6))
                    )
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 0)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    MainMenuView(gameState: GameState())
        .background(.black)
}
