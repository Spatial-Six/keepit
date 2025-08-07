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
    @EnvironmentObject var gameState: GameState
    @State private var ballEntities: [UUID: ModelEntity] = [:]
    
    var body: some View {
        RealityView { content in
            await setupFootballField(content: content)
        } update: { content in
            updateBalls(content: content)
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

// MARK: - Ball Management
extension ImmersiveView {
    @MainActor
    func updateBalls(content: RealityViewContent) {
        // Add new balls
        for ball in gameState.activeBalls {
            if ballEntities[ball.id] == nil {
                Task {
                    await createBallEntity(for: ball, content: content)
                }
            }
        }
        
        // Clean up removed balls
        let activeBallIds = Set(gameState.activeBalls.map { $0.id })
        for (ballId, ballEntity) in ballEntities {
            if !activeBallIds.contains(ballId) {
                ballEntity.removeFromParent()
                ballEntities.removeValue(forKey: ballId)
            }
        }
    }
    
    @MainActor
    func createBallEntity(for ball: Ball, content: RealityViewContent) async {
        do {
            // Load FootBall.usdz asset
            let ballModel = try await ModelEntity(named: "FootBall", in: realityKitContentBundle)
            
            ballModel.position = ball.startPosition
            ballModel.scale = SIMD3(0.1, 0.1, 0.1)
            ballModel.name = "Ball_\(ball.id.uuidString)"
            
            // Add physics components
            let ballShape = ShapeResource.generateSphere(radius: 0.15)
            ballModel.components.set(CollisionComponent(shapes: [ballShape]))
            
            let physicsMaterial = PhysicsMaterialResource.generate(
                staticFriction: 0.6,
                dynamicFriction: 0.4,
                restitution: 0.8
            )
            
            ballModel.components.set(PhysicsBodyComponent(
                massProperties: .init(mass: 0.1),
                material: physicsMaterial,
                mode: .kinematic
            ))
            
            content.add(ballModel)
            ballEntities[ball.id] = ballModel
            
            animateBall(ballModel, to: ball.targetPosition, speed: ball.speed)
            
            print("⚽ FootBall model created")
            
        } catch {
            print("❌ Failed to load FootBall: \(error)")
            
            // Fallback: create simple sphere
            let ballMesh = MeshResource.generateSphere(radius: 0.15)
            let ballMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
            let ballModel = ModelEntity(mesh: ballMesh, materials: [ballMaterial])
            
            ballModel.position = ball.startPosition
            ballModel.scale = SIMD3(0.3, 0.3, 0.3)
            ballModel.name = "Ball_\(ball.id.uuidString)"
            
            content.add(ballModel)
            ballEntities[ball.id] = ballModel
            
            animateBall(ballModel, to: ball.targetPosition, speed: ball.speed)
            print("⚽ Fallback ball created")
        }
    }
    
    @MainActor
    func animateBall(_ ballEntity: ModelEntity, to target: SIMD3<Float>, speed: Float) {
        let distance = length(target - ballEntity.position)
        let duration = TimeInterval(distance / speed)
        
        // Animate with Transform
        var transform = ballEntity.transform
        transform.translation = target
        
        ballEntity.move(
            to: transform,
            relativeTo: ballEntity.parent,
            duration: duration,
            timingFunction: .easeOut
        )
        
        print("⚽ Ball animated - duration: \(duration)s, speed: \(speed)")
    }
}

#Preview {
    ImmersiveView()
}
