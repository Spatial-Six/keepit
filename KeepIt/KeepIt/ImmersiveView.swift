//
//  ImmersiveView.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            await setupFootballField(content: content)
        }
    }
}

@MainActor
func createGrassField(content: RealityViewContent) async {
    do {
        guard let grassURL = realityKitContentBundle.url(forResource: "Grass", withExtension: "usdz") else {
            return
        }
        
        let grassModel = try await Entity(contentsOf: grassURL)
        
        // Field dimensions - extended for better coverage
        let patchSize: Float = 5.0
        let fieldWidth: Float = 25
        let fieldDepth: Float = 25
        
        // Calculate grid dimensions
        let patchesX = Int(ceil(fieldWidth / patchSize))
        let patchesZ = Int(ceil(fieldDepth / patchSize))
        
        // Create grass field by tiling patches
        for x in 0..<patchesX {
            for z in 0..<patchesZ {
                let grassPatch = grassModel.clone(recursive: true)
                grassPatch.scale = SIMD3(0.02, 0.02, 0.02)
                
                let posX = Float(x) * patchSize - fieldWidth/2 + patchSize/2
                let posZ = Float(z) * patchSize - fieldDepth/2 + patchSize/2
                
                grassPatch.position = SIMD3(posX, -1, posZ)
                content.add(grassPatch)
            }
        }
    } catch {
        return
    }
}

@MainActor
func setupFootballField(content: RealityViewContent) async {
    await createGrassField(content: content)
    setupLighting(content: content)
}

@MainActor
func setupLighting(content: RealityViewContent) {
    // Create directional light to simulate sunlight
    let sunLight = Entity()
    let directionalLight = DirectionalLightComponent(
        color: .white,
        intensity: 10000
    )
    
    sunLight.components.set(directionalLight)
    
    // Position sun at an angle to create natural daylight effect
    // Looking down from above and slightly behind
    sunLight.look(at: [0, 0, 0], from: [10, 15, -10], relativeTo: nil)
    
    content.add(sunLight)
}

#Preview {
    ImmersiveView()
}
