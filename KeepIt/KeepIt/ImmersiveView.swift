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
            // Create football field environment
            await setupFootballField(content: content)
        }
    }
}

@MainActor
func setupFootballField(content: RealityViewContent) async {
    // Create ground plane (football field)
    let fieldMesh = MeshResource.generatePlane(width: 100, depth: 60)
    let fieldMaterial = SimpleMaterial(color: .green, roughness: 0.8, isMetallic: false)
    let fieldEntity = ModelEntity(mesh: fieldMesh, materials: [fieldMaterial])
    fieldEntity.position = [0, 0, 0]
    content.add(fieldEntity)
    
    // Create goal posts placeholder
    let goalPostMaterial = SimpleMaterial(color: .white, roughness: 0.2, isMetallic: false)
    
    // Left goal post
    let leftPostMesh = MeshResource.generateBox(width: 0.2, height: 8, depth: 0.2)
    let leftPost = ModelEntity(mesh: leftPostMesh, materials: [goalPostMaterial])
    leftPost.position = [-12, 4, 0]
    content.add(leftPost)
    
    // Right goal post
    let rightPost = ModelEntity(mesh: leftPostMesh, materials: [goalPostMaterial])
    rightPost.position = [12, 4, 0]
    content.add(rightPost)
    
    // Crossbar
    let crossbarMesh = MeshResource.generateBox(width: 24, height: 0.2, depth: 0.2)
    let crossbar = ModelEntity(mesh: crossbarMesh, materials: [goalPostMaterial])
    crossbar.position = [0, 8, 0]
    content.add(crossbar)
    
    // Add field markings (penalty box outline)
    let penaltyBoxMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
    
    // Front line of penalty box
    let frontLineMesh = MeshResource.generateBox(width: 40, height: 0.05, depth: 0.3)
    let frontLine = ModelEntity(mesh: frontLineMesh, materials: [penaltyBoxMaterial])
    frontLine.position = [0, 0.05, -18]
    content.add(frontLine)
    
    // Left side of penalty box
    let leftSideMesh = MeshResource.generateBox(width: 0.3, height: 0.05, depth: 18)
    let leftSide = ModelEntity(mesh: leftSideMesh, materials: [penaltyBoxMaterial])
    leftSide.position = [-20, 0.05, -9]
    content.add(leftSide)
    
    // Right side of penalty box
    let rightSide = ModelEntity(mesh: leftSideMesh, materials: [penaltyBoxMaterial])
    rightSide.position = [20, 0.05, -9]
    content.add(rightSide)
    
    // Add ambient lighting
    let ambientLight = Entity()
    let lightComponent = DirectionalLightComponent(
        color: .white,
        intensity: 2000
    )
    ambientLight.components.set(lightComponent)
    ambientLight.transform.rotation = simd_quatf(angle: .pi * -0.3, axis: [1, 0, 0])
    content.add(ambientLight)
}

#Preview {
    ImmersiveView()
}
