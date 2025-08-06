//
//  KeepItApp.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import SwiftUI

@main
struct KeepItApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
        }
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environmentObject(gameState)
        }
    }
}
