//
//  ImmersiveView.swift
//  KeepIt
//
//  Created by Ruban on 2025-08-06.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    @EnvironmentObject var gameState: GameState
    @State private var ballEntities: [UUID: ModelEntity] = [:]
    @State private var leftHandAnchor: AnchorEntity?
    @State private var rightHandAnchor: AnchorEntity?
    @State private var positionTimer: Timer?
    @State private var arkitSession = ARKitSession()
    @State private var handTrackingProvider = HandTrackingProvider()
    @State private var latestHandAnchors: [HandAnchor.Chirality: HandAnchor] = [:]
    @State private var currentBallPositions: [UUID: SIMD3<Float>] = [:]
    @State private var collisionCheckTimer: Timer?
    
    var body: some View {
        RealityView { content in
            let skybox = createSkybox()
            content.add(skybox!)
            
            await setupFootballField(content: content)
            setupHandSpheres(content: content)
            // setupCollisionHandling(content: content) // Disabled - using distance-based detection now
            
            // Start hand tracking and position timer
            Task {
                await startHandTracking()
                startPositionTimer()
                startCollisionCheckTimer()
            }
        } update: { content in
            updateBalls(content: content)
        }
        .onDisappear {
            stopPositionTimer()
            stopCollisionCheckTimer()
        }
    }
    
    private func createSkybox() -> Entity? {
        let largeSphere = MeshResource.generateSphere(radius: 15)
        var skyboxMaterial = UnlitMaterial()
        
        do {
            let texture = try TextureResource.load(named: "test3")
            skyboxMaterial.color = .init(texture: .init(texture))
        } catch {
            print("Failed to create skybox material: \(error)")
            return nil
        }
        
        let skyboxEntity = Entity()
        skyboxEntity.components.set(ModelComponent(mesh: largeSphere, materials: [skyboxMaterial]))
        
        skyboxEntity.scale = .init(x: -1, y: 1, z: 1)
        return skyboxEntity
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
    await createGoal(content: content)
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

@MainActor
func createGoal(content: RealityViewContent) async {
    do {
        let goalModel = try await ModelEntity(named: "Goal", in: realityKitContentBundle)
        goalModel.position = SIMD3(0, -1.0, 2.0)
        goalModel.scale = SIMD3(0.4, 0.4, 0.4)
        let rotation180 = simd_quatf(angle: Float.pi, axis: SIMD3(0, 1, 0))
        goalModel.orientation = rotation180
        
        // Add collision physics so balls stop at goalpost
        goalModel.generateCollisionShapes(recursive: true)
        let goalPhysics = PhysicsBodyComponent(
            massProperties: .init(mass: 1000.0),
            material: PhysicsMaterialResource.generate(restitution: 0.3),
            mode: .static
        )
        goalModel.components.set(goalPhysics)
        
        content.add(goalModel)
        print("🥅 Goal loaded with collision physics")
    } catch {
        print("❌ Failed to load Goal: \(error)")
    }
}

// MARK: - Hand Tracking Spheres
extension ImmersiveView {
    func setupHandSpheres(content: RealityViewContent) {
        // Left hand sphere
        let leftAnchor = AnchorEntity(.hand(.left, location: .palm))
        let leftSphere = createHandSphere(color: .blue, name: "LeftHandSphere")
        leftAnchor.addChild(leftSphere)
        content.add(leftAnchor)
        leftHandAnchor = leftAnchor
        
        // Right hand sphere  
        let rightAnchor = AnchorEntity(.hand(.right, location: .palm))
        let rightSphere = createHandSphere(color: .green, name: "RightHandSphere")
        rightAnchor.addChild(rightSphere)
        content.add(rightAnchor)
        rightHandAnchor = rightAnchor
        
        print("🖐️ Hand collision spheres created with palm anchors")
    }
    
    func createHandSphere(color: UIColor, name: String) -> ModelEntity {
        let sphere = MeshResource.generateSphere(radius: 0.1) // 10cm diameter
        
        var material = UnlitMaterial()
        material.color = .init(tint: color.withAlphaComponent(0.5))
        
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        sphereEntity.name = name
        
        // Add collision component for physics collision detection
        let handCollisionShape = ShapeResource.generateSphere(radius: 0.1)
        sphereEntity.components.set(CollisionComponent(shapes: [handCollisionShape]))
        
        print("🖐️ Hand sphere '\(name)' created with collision component")
        return sphereEntity
    }
    
    func setupCollisionHandling(content: RealityViewContent) {
        // Subscribe to collision events
        _ = content.subscribe(to: CollisionEvents.Began.self) { [gameState] event in
            let entityA = event.entityA
            let entityB = event.entityB
            
            // Check if this is a ball-hand collision
            var ballEntity: Entity?
            var handEntity: Entity?
            
            if entityA.name.starts(with: "Ball_") && (entityB.name == "LeftHandSphere" || entityB.name == "RightHandSphere") {
                ballEntity = entityA
                handEntity = entityB
            } else if entityB.name.starts(with: "Ball_") && (entityA.name == "LeftHandSphere" || entityA.name == "RightHandSphere") {
                ballEntity = entityB
                handEntity = entityA
            }
            
            if let ball = ballEntity, let hand = handEntity {
                print("✋ COLLISION DETECTED! \(ball.name) hit \(hand.name)")
                
                // Handle ball save directly in the closure
                let ballName = ball.name
                if ballName.starts(with: "Ball_") {
                    let ballIdString = String(ballName.dropFirst(5)) // Remove "Ball_" prefix
                    if let ballId = UUID(uuidString: ballIdString) {
                        // Remove ball from scene
                        ball.removeFromParent()
                        
                        // Remove from game state and increment score
                        Task { @MainActor in
                            gameState.activeBalls.removeAll { $0.id == ballId }
                            gameState.score += 1
                            print("⚽ Ball saved with physics collision! Score: \(gameState.score)")
                        }
                    }
                }
            }
        }
        
        print("🔄 Collision event subscription set up")
    }
    
    func startHandTracking() async {
        do {
            if HandTrackingProvider.isSupported {
                try await arkitSession.run([handTrackingProvider])
                
                // Start monitoring hand updates
                Task {
                    for await update in handTrackingProvider.anchorUpdates {
                        latestHandAnchors[update.anchor.chirality] = update.anchor
                    }
                }
            }
        } catch {
            print("❌ Failed to start hand tracking: \(error)")
        }
    }
    
    func startPositionTimer() {
        stopPositionTimer()
        
        positionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] _ in
            printHandPositions()
        }
    }
    
    func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }
    
    func printHandPositions() {
        guard let leftHandAnchor = latestHandAnchors[.left],
              let rightHandAnchor = latestHandAnchors[.right] else {
            return
        }
        
        // Get hand positions from anchor transforms (real 3D coordinates)  
        let leftHandTransform = leftHandAnchor.originFromAnchorTransform
        let rightHandTransform = rightHandAnchor.originFromAnchorTransform
        
        let leftPos = SIMD3<Float>(leftHandTransform.columns.3.x, leftHandTransform.columns.3.y, leftHandTransform.columns.3.z)
        let rightPos = SIMD3<Float>(rightHandTransform.columns.3.x, rightHandTransform.columns.3.y, rightHandTransform.columns.3.z)
        
        print("🖐️ Hand Positions - Left: (x: \(String(format: "%.2f", leftPos.x)), y: \(String(format: "%.2f", leftPos.y)), z: \(String(format: "%.2f", leftPos.z))) | Right: (x: \(String(format: "%.2f", rightPos.x)), y: \(String(format: "%.2f", rightPos.y)), z: \(String(format: "%.2f", rightPos.z)))")
    }
    
    // MARK: - Distance-Based Collision Detection
    func startCollisionCheckTimer() {
        stopCollisionCheckTimer()
        
        // Check collisions at 60fps for smooth detection
        collisionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [self] _ in
            checkBallHandCollisions()
        }
    }
    
    func stopCollisionCheckTimer() {
        collisionCheckTimer?.invalidate()
        collisionCheckTimer = nil
    }
    
    func checkBallHandCollisions() {
        guard let leftHandAnchor = latestHandAnchors[.left],
              let rightHandAnchor = latestHandAnchors[.right] else {
            return
        }
        
        // Get current hand positions
        let leftHandTransform = leftHandAnchor.originFromAnchorTransform
        let rightHandTransform = rightHandAnchor.originFromAnchorTransform
        let leftHandPos = SIMD3<Float>(leftHandTransform.columns.3.x, leftHandTransform.columns.3.y, leftHandTransform.columns.3.z)
        let rightHandPos = SIMD3<Float>(rightHandTransform.columns.3.x, rightHandTransform.columns.3.y, rightHandTransform.columns.3.z)
        
        // Check each ball for collisions
        for (ballId, ballEntity) in ballEntities {
            let ballPos = ballEntity.position
            currentBallPositions[ballId] = ballPos
            
            // Check distance to each hand (collision radius = 15cm)
            let collisionDistance: Float = 0.5
            
            let leftDistance = distance(ballPos, leftHandPos)
            let rightDistance = distance(ballPos, rightHandPos)
            
            if leftDistance < collisionDistance {
                handleBallSave(ballId: ballId, ballEntity: ballEntity, handType: "Left")
            } else if rightDistance < collisionDistance {
                handleBallSave(ballId: ballId, ballEntity: ballEntity, handType: "Right")
            }
        }
    }
    
    func handleBallSave(ballId: UUID, ballEntity: ModelEntity, handType: String) {
        let ballPos = ballEntity.position
        print("🎉 GOAL SAVED! \(handType) hand caught ball at position: (x: \(String(format: "%.2f", ballPos.x)), y: \(String(format: "%.2f", ballPos.y)), z: \(String(format: "%.2f", ballPos.z)))")
        
        // Remove ball from scene and tracking
        ballEntity.removeFromParent()
        ballEntities.removeValue(forKey: ballId)
        currentBallPositions.removeValue(forKey: ballId)
        
        // Update game state
        Task { @MainActor in
            gameState.activeBalls.removeAll { $0.id == ballId }
            gameState.score += 1
            print("⚽ Score: \(gameState.score)")
        }
    }
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
            ballModel.scale = SIMD3(0.05, 0.05, 0.05)
            ballModel.name = "Ball_\(ball.id.uuidString)"
            
            // Add physics components
            let ballShape = ShapeResource.generateSphere(radius: 0.05) // Match the visual scale (0.1 * 0.5 = 0.05)
            ballModel.components.set(CollisionComponent(shapes: [ballShape]))
            
            let physicsMaterial = PhysicsMaterialResource.generate(
                staticFriction: 0.6,
                dynamicFriction: 0.4,
                restitution: 0.8
            )
            
            ballModel.components.set(PhysicsBodyComponent(
                massProperties: .init(mass: 0.06),
                material: physicsMaterial,
                mode: .kinematic
            ))
            
            content.add(ballModel)
            ballEntities[ball.id] = ballModel
            
            animateBall(ballModel, to: ball.targetPosition, speed: ball.speed)
            
            print("⚽ FootBall model created")
            
        } catch {
            print("❌ Failed to load FootBall: \(error)")
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
    
    func handleBallSaveWithPhysics(ballEntity: Entity) {
        // Find the ball ID from the entity name
        let ballName = ballEntity.name
        if ballName.starts(with: "Ball_") {
            let ballIdString = String(ballName.dropFirst(5)) // Remove "Ball_" prefix
            if let ballId = UUID(uuidString: ballIdString) {
                // Remove from ball entities dictionary
                if let ballModel = ballEntities[ballId] {
                    ballModel.removeFromParent()
                    ballEntities.removeValue(forKey: ballId)
                }
                
                // Remove from game state
                gameState.activeBalls.removeAll { $0.id == ballId }
                
                // Increment score
                gameState.score += 1
                
                print("⚽ Ball saved with physics collision! Score: \(gameState.score)")
            }
        }
    }
}

#Preview {
    ImmersiveView()
}
