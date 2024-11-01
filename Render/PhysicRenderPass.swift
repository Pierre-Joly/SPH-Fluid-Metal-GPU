//
//  PhysicRenderPass.swift
//  SPH
//
//  Created by Pierre Joly on 28/08/2024.
//

import MetalKit

struct RK4Step {
    var pipelineState: MTLComputePipelineState?
    var positionBuffer: MTLBuffer
    var positionIndex: Int
    var velocityBuffer: MTLBuffer
    var velocityIndex: Int
    var forceBuffer: MTLBuffer?
    var forceIndex: Int?
}

class PhysicRenderPass {
    // Pipeline state objects
    var initPositionPSO: MTLComputePipelineState
    var densityPSO: MTLComputePipelineState
    var forcePSO: MTLComputePipelineState
    var rk4Step1PSO: MTLComputePipelineState
    var rk4Step2PSO: MTLComputePipelineState
    var rk4Step3PSO: MTLComputePipelineState
    var rk4Step4PSO: MTLComputePipelineState
    var rk4FinalPSO: MTLComputePipelineState
    var collisionPSO: MTLComputePipelineState

    // Buffers
    var positionBuffer: MTLBuffer
    var positionK1Buffer: MTLBuffer
    var positionK2Buffer: MTLBuffer
    var positionK3Buffer: MTLBuffer
    var positionK4Buffer: MTLBuffer
    var velocityBuffer: MTLBuffer
    var velocityK1Buffer: MTLBuffer
    var velocityK2Buffer: MTLBuffer
    var velocityK3Buffer: MTLBuffer
    var velocityK4Buffer: MTLBuffer
    var densityBuffer: MTLBuffer
    var pressureBuffer: MTLBuffer
    var forceK1Buffer: MTLBuffer
    var forceK2Buffer: MTLBuffer
    var forceK3Buffer: MTLBuffer
    var forceK4Buffer: MTLBuffer
    let rk4HashMap: [RK4Step]

    // Constants
    let particleNumber: Int
    let threadgroupSize: MTLSize
    let threadgroupCount: MTLSize
    let dt: Float

    init(device: MTLDevice, commandQueue: MTLCommandQueue, particleNumber: Int, camera: OrthographicCamera) {
        
        // Constants
        self.particleNumber = particleNumber
        self.dt = 0.0005;

        // Create compute pipeline states
        self.densityPSO = PipelineStates.createComputePSO(function: "density_main")
        self.forcePSO = PipelineStates.createComputePSO(function: "force_main")
        self.rk4Step1PSO = PipelineStates.createComputePSO(function: "rk4_step1")
        self.rk4Step2PSO = PipelineStates.createComputePSO(function: "rk4_step2")
        self.rk4Step3PSO = PipelineStates.createComputePSO(function: "rk4_step3")
        self.rk4Step4PSO = PipelineStates.createComputePSO(function: "rk4_step4")
        self.rk4FinalPSO = PipelineStates.createComputePSO(function: "integrateRK4Results")
        self.initPositionPSO = PipelineStates.createComputePSO(function: "init_position")
        self.collisionPSO = PipelineStates.createComputePSO(function: "collision_main")

        // Buffers
        guard       
            // Initialize position and velocity buffers
            let positionBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let velocityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            
            // Initialize RK4 position buffers
            let positionK1Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let positionK2Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let positionK3Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let positionK4Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),

            // Initialize RK4 velocity buffers
            let velocityK1Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let velocityK2Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let velocityK3Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let velocityK4Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            
            // Initialize RK4 force buffers
            let forceK1Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let forceK2Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let forceK3Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let forceK4Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            
            // Initialize Physics buffers
            let densityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate),
            let pressureBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate)
        else {
            fatalError("Failed to create one or more buffers")
        }
        
        // Assign position and velocity buffers
        self.positionBuffer = positionBuffer
        self.velocityBuffer = velocityBuffer

        // Assign RK4 buffers
        self.positionK1Buffer = positionK1Buffer
        self.positionK2Buffer = positionK2Buffer
        self.positionK3Buffer = positionK3Buffer
        self.positionK4Buffer = positionK4Buffer
        self.velocityK1Buffer = velocityK1Buffer
        self.velocityK2Buffer = velocityK2Buffer
        self.velocityK3Buffer = velocityK3Buffer
        self.velocityK4Buffer = velocityK4Buffer
        self.forceK1Buffer = forceK1Buffer
        self.forceK2Buffer = forceK2Buffer
        self.forceK3Buffer = forceK3Buffer
        self.forceK4Buffer = forceK4Buffer
        
        // Physics buffers
        self.densityBuffer = densityBuffer
        self.pressureBuffer = pressureBuffer
        
        // Buffer Hash Map
        self.rk4HashMap = [
                // Initial Step: No compute pipeline state, no force buffer
                RK4Step(
                    pipelineState: nil,
                    positionBuffer: positionBuffer,
                    positionIndex: PositionBuffer.index,
                    velocityBuffer: velocityBuffer,
                    velocityIndex: VelocityBuffer.index,
                    forceBuffer: nil,
                    forceIndex: nil
                ),
                // RK4 Step 1
                RK4Step(
                    pipelineState: rk4Step1PSO,
                    positionBuffer: positionK1Buffer,
                    positionIndex: PositionK1Buffer.index,
                    velocityBuffer: velocityK1Buffer,
                    velocityIndex: VelocityK1Buffer.index,
                    forceBuffer: forceK1Buffer,
                    forceIndex: ForceK1Buffer.index
                ),
                // RK4 Step 2
                RK4Step(
                    pipelineState: rk4Step2PSO,
                    positionBuffer: positionK2Buffer,
                    positionIndex: PositionK2Buffer.index,
                    velocityBuffer: velocityK2Buffer,
                    velocityIndex: VelocityK2Buffer.index,
                    forceBuffer: forceK2Buffer,
                    forceIndex: ForceK2Buffer.index
                ),
                // RK4 Step 3
                RK4Step(
                    pipelineState: rk4Step3PSO,
                    positionBuffer: positionK3Buffer,
                    positionIndex: PositionK3Buffer.index,
                    velocityBuffer: velocityK3Buffer,
                    velocityIndex: VelocityK3Buffer.index,
                    forceBuffer: forceK3Buffer,
                    forceIndex: ForceK3Buffer.index
                ),
                // RK4 Step 4
                RK4Step(
                    pipelineState: rk4Step4PSO,
                    positionBuffer: positionK4Buffer,
                    positionIndex: PositionK4Buffer.index,
                    velocityBuffer: velocityK4Buffer,
                    velocityIndex: VelocityK4Buffer.index,
                    forceBuffer: forceK4Buffer,
                    forceIndex: ForceK4Buffer.index
                )
            ]

        // Calculate threadgroup sizes
        self.threadgroupSize = MTLSize(width: 1024, height: 1, depth: 1)
        self.threadgroupCount = MTLSize(width: (particleNumber / self.threadgroupSize.width) + 1, height: 1, depth: 1)

        // Initialize positions using compute shader
        self.initializePositions(device: device, commandQueue: commandQueue, camera: camera)
    }

    func initializePositions(device: MTLDevice, commandQueue: MTLCommandQueue, camera: OrthographicCamera) {
        // Create a command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create command buffer or compute encoder")
        }

        // Set the compute pipeline state
        encoder.setComputePipelineState(self.initPositionPSO)

        // Set buffers
        encoder.setBuffer(positionBuffer, offset: 0, index: PositionBuffer.index)

        // Set constants sending
        var constants = InitPositionConstants(
            particleNumber: UInt32(self.particleNumber),
            viewWidth: Float(camera.viewSize) * Float(camera.aspect),
            viewHeight: Float(camera.viewSize)
        )
        encoder.setBytes(&constants, length: MemoryLayout<InitPositionConstants>.stride, index: ConstantBuffer.index)

        // Dispatch threads
        let threadsPerGrid = MTLSize(width: self.particleNumber, height: 1, depth: 1)
        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: self.threadgroupSize)

        // Commit and wait for completion
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func draw(commandBuffer: MTLCommandBuffer) {
        
        // RK4 Step Computation
        for i in 0..<4 {
            // Density Calculation
            densityCalculation(commandBuffer: commandBuffer,
                               positions: self.rk4HashMap[i].positionBuffer)
            
            // Force Calculation
            forceCalculation(commandBuffer: commandBuffer,
                             positions: self.rk4HashMap[i].positionBuffer,
                             velocities: self.rk4HashMap[i].velocityBuffer,
                             forces: self.rk4HashMap[i + 1].forceBuffer!)
            
            // RK4 Step i - Prediction
            rk4IntegrationStep(commandBuffer: commandBuffer,
                               stepNumber: i)
        }
        
        // Final Integration Step - Combine all RK4 intermediate values to update position and velocity
        rk4IntegrationFinal(commandBuffer: commandBuffer)

        // Collision Handling
        collisionHandling(commandBuffer: commandBuffer)
    }
    
    func densityCalculation(commandBuffer: MTLCommandBuffer,
                            positions: MTLBuffer)
    {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.setComputePipelineState(self.densityPSO)
            // Parameters
            encoder.setBuffer(positions, offset: 0, index: PositionBuffer.index)
            //
            encoder.setBuffer(self.densityBuffer, offset: 0, index: DensityBuffer.index)
            encoder.setBuffer(self.pressureBuffer, offset: 0, index: PressureBuffer.index)
            var numParticles = UInt32(self.particleNumber)
            encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            encoder.endEncoding()
        }
    }
    
    func forceCalculation(commandBuffer: MTLCommandBuffer,
                          positions: MTLBuffer,
                          velocities: MTLBuffer,
                          forces: MTLBuffer)
    {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.setComputePipelineState(self.forcePSO)
            // Parameters
            encoder.setBuffer(positions, offset: 0, index: PositionBuffer.index)
            encoder.setBuffer(velocities, offset: 0, index: VelocityBuffer.index)
            encoder.setBuffer(forces, offset: 0, index: ForceBuffer.index)
            //
            encoder.setBuffer(self.pressureBuffer, offset: 0, index: PressureBuffer.index)
            encoder.setBuffer(self.densityBuffer, offset: 0, index: DensityBuffer.index)
            var numParticles = UInt32(self.particleNumber)
            encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            encoder.endEncoding()
        }
    }
    
    func rk4IntegrationStep(commandBuffer: MTLCommandBuffer, stepNumber: Int)
    {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.setComputePipelineState(self.rk4HashMap[stepNumber + 1].pipelineState!)
            
            // Position Velocity Buffers
            encoder.setBuffer(rk4HashMap[stepNumber].positionBuffer, offset: 0, index: rk4HashMap[stepNumber].positionIndex)
            encoder.setBuffer(rk4HashMap[stepNumber].velocityBuffer, offset: 0, index: rk4HashMap[stepNumber].velocityIndex)
            encoder.setBuffer(rk4HashMap[stepNumber + 1].positionBuffer, offset: 0, index: rk4HashMap[stepNumber + 1].positionIndex)
            encoder.setBuffer(rk4HashMap[stepNumber + 1].velocityBuffer, offset: 0, index: rk4HashMap[stepNumber + 1].velocityIndex)
            encoder.setBuffer(rk4HashMap[stepNumber + 1].forceBuffer, offset: 0, index: rk4HashMap[stepNumber + 1].forceIndex!)
            
            var dt: Float = self.dt
            encoder.setBytes(&dt, length: MemoryLayout<Float>.stride, index: DTBuffer.index)
            var numParticles = UInt32(self.particleNumber)
            encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            encoder.endEncoding()
        }
    }
    
    func rk4IntegrationFinal(commandBuffer: MTLCommandBuffer)
    {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.setComputePipelineState(self.rk4FinalPSO)
            
            // Position Velocity Buffers
            for rk4Map in self.rk4HashMap {
                encoder.setBuffer(rk4Map.positionBuffer, offset: 0, index: rk4Map.positionIndex)
                encoder.setBuffer(rk4Map.velocityBuffer, offset: 0, index: rk4Map.velocityIndex)
            }
            
            // Forces Buffers
            for rk4Map in self.rk4HashMap.dropFirst() {
                encoder.setBuffer(rk4Map.forceBuffer, offset: 0, index: rk4Map.forceIndex!)
            }
                                  
            var dt: Float = self.dt
            encoder.setBytes(&dt, length: MemoryLayout<Float>.stride, index: DTBuffer.index)
            var numParticles = UInt32(self.particleNumber)
            encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            encoder.endEncoding()
        }
    }
    
    func collisionHandling(commandBuffer: MTLCommandBuffer)
    {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.setComputePipelineState(self.collisionPSO)
            
            // Position Velocity Buffers
            encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
            encoder.setBuffer(self.velocityBuffer, offset: 0, index: VelocityBuffer.index)
            
            var numParticles = UInt32(self.particleNumber)
            encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            encoder.endEncoding()
        }
    }
}
