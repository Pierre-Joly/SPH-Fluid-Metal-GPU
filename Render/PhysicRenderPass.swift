//
//  PhysicRenderPass.swift
//  SPH
//
//  Created by Pierre Joly on 28/08/2024.
//

import MetalKit

class PhysicRenderPass {
    // Pipeline state objects
    var initPositionPSO: MTLComputePipelineState
    var initCountGridPSO: MTLComputePipelineState
    var assignParticlesToGridPSO: MTLComputePipelineState
    var densityPSO: MTLComputePipelineState
    var forcePSO: MTLComputePipelineState
    var rk4Step1PSO: MTLComputePipelineState
    var rk4Step2PSO: MTLComputePipelineState
    var rk4Step3PSO: MTLComputePipelineState
    var rk4FinalPSO: MTLComputePipelineState
    var collisionPSO: MTLComputePipelineState

    // Buffers
    var positionBuffer: MTLBuffer
    var positionKBuffer: MTLBuffer
    var velocityBuffer: MTLBuffer
    var velocityK1Buffer: MTLBuffer
    var velocityK2Buffer: MTLBuffer
    var velocityK3Buffer: MTLBuffer
    var densityBuffer: MTLBuffer
    var pressureBuffer: MTLBuffer
    var forceK1Buffer: MTLBuffer
    var forceK2Buffer: MTLBuffer
    var forceK3Buffer: MTLBuffer
    var forceK4Buffer: MTLBuffer
    var gridCountsBuffer: MTLBuffer
    var gridParticleIndicesBuffer:  MTLBuffer
    
    // TODO: Argument Buffer
    
    // TODO: Heap
    
    // Uniforms Grid parameters
    let totalGridCells: Int
    let maxParticlesPerCell: Int
    
    // Constants
    let particleNumber: Int
    let threadgroupSize: MTLSize
    let threadgroupCount: MTLSize
    let threadgroupCountGrid: MTLSize

    init(device: MTLDevice, commandQueue: MTLCommandQueue, particleNumber: Int, camera: OrthographicCamera) {
        
        // Constants
        self.particleNumber = particleNumber
        
        // Uniforms Grid parameters
        self.totalGridCells = 1600
        self.maxParticlesPerCell = 200

        // Create compute pipeline states
        self.initPositionPSO = PipelineStates.createComputePSO(function: "init_position")
        self.initCountGridPSO = PipelineStates.createComputePSO(function: "init_count_grid")
        self.assignParticlesToGridPSO = PipelineStates.createComputePSO(function: "assign_particles_to_grid")
        self.densityPSO = PipelineStates.createComputePSO(function: "density")
        self.forcePSO = PipelineStates.createComputePSO(function: "force")
        self.rk4Step1PSO = PipelineStates.createComputePSO(function: "rk4_step1")
        self.rk4Step2PSO = PipelineStates.createComputePSO(function: "rk4_step2")
        self.rk4Step3PSO = PipelineStates.createComputePSO(function: "rk4_step3")
        self.rk4FinalPSO = PipelineStates.createComputePSO(function: "integrateRK4Results")
        self.collisionPSO = PipelineStates.createComputePSO(function: "collision")

        // Buffers
        guard
            // Initialize position buffer
            let positionBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let positionKBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),

            // Initialize velocity buffers
            let velocityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let velocityK1Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let velocityK2Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let velocityK3Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            
            // Initialize RK4 force buffers
            let forceK1Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let forceK2Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let forceK3Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let forceK4Buffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            
            // Initialize Physics buffers
            let densityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate),
            let pressureBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate),
            
            // Uniforms Grid buffers
            let gridParticleIndicesBuffer = device.makeBuffer(length: self.totalGridCells * self.maxParticlesPerCell * MemoryLayout<UInt32>.stride, options: .storageModePrivate
            ),
            let gridCountsBuffer = device.makeBuffer(length: self.totalGridCells * MemoryLayout<UInt32>.stride, options: .storageModePrivate
            )
        else {
            fatalError("Failed to create one or more buffers")
        }
        
        // Assign position and velocity buffers
        self.positionBuffer = positionBuffer
        self.velocityBuffer = velocityBuffer
        self.positionBuffer.label = "position"
        
        // Assign RK4 buffers
        self.positionKBuffer = positionKBuffer
        self.velocityK1Buffer = velocityK1Buffer
        self.velocityK2Buffer = velocityK2Buffer
        self.velocityK3Buffer = velocityK3Buffer
        self.forceK1Buffer = forceK1Buffer
        self.forceK2Buffer = forceK2Buffer
        self.forceK3Buffer = forceK3Buffer
        self.forceK4Buffer = forceK4Buffer
        
        // Uniform grid buffers
        self.gridParticleIndicesBuffer = gridParticleIndicesBuffer
        self.gridParticleIndicesBuffer.label = "indices"
        self.gridCountsBuffer = gridCountsBuffer
        self.gridCountsBuffer.label = "count"
        
        // Physics buffers
        self.densityBuffer = densityBuffer
        self.densityBuffer.label = "density"
        self.pressureBuffer = pressureBuffer

        // Calculate threadgroup sizes
        self.threadgroupSize = MTLSize(width: 1024, height: 1, depth: 1)
        self.threadgroupCount = MTLSize(width: (self.particleNumber / self.threadgroupSize.width) + 1, height: 1, depth: 1)
        self.threadgroupCountGrid = MTLSize(width: (self.totalGridCells / self.threadgroupSize.width) + 1, height: 1, depth: 1)

        // Initialize positions using compute shader
        self.initializePositions(device: device, commandQueue: commandQueue, camera: camera)
    }

    func draw(commandBuffer: MTLCommandBuffer) {
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            fatalError("Failed to create compute command buffer")
        }
        
        // Bind Buffers
            // Constants
        var numParticles = UInt32(self.particleNumber)
        encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            // Physics
        encoder.setBuffer(self.densityBuffer, offset: 0, index: DensityBuffer.index)
        encoder.setBuffer(self.pressureBuffer, offset: 0, index: PressureBuffer.index)
            // Positions
        encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionKBuffer.index)
            // Velocities
        encoder.setBuffer(self.velocityK1Buffer, offset: 0, index: VelocityK1Buffer.index)
        encoder.setBuffer(self.velocityK2Buffer, offset: 0, index: VelocityK2Buffer.index)
        encoder.setBuffer(self.velocityK3Buffer, offset: 0, index: VelocityK3Buffer.index)
            // Forces
        encoder.setBuffer(self.forceK1Buffer, offset: 0, index: ForceK1Buffer.index)
        encoder.setBuffer(self.forceK2Buffer, offset: 0, index: ForceK2Buffer.index)
        encoder.setBuffer(self.forceK3Buffer, offset: 0, index: ForceK3Buffer.index)
        encoder.setBuffer(self.forceK4Buffer, offset: 0, index: ForceK4Buffer.index)
            // Neighborhood Search
        encoder.setBuffer(self.gridCountsBuffer, offset: 0, index: GridCountsBuffer.index)
        encoder.setBuffer(self.gridParticleIndicesBuffer, offset: 0, index: GridParticleIndicesBuffer.index)
        
        // RK4 Step Computation
        //{
            // Runge Kutta 4 - Step 1
            // {
            // Reset GridCounts to zero
            encoder.setComputePipelineState(self.initCountGridPSO)
            encoder.dispatchThreadgroups(self.threadgroupCountGrid, threadsPerThreadgroup: self.threadgroupSize)
        
            // Neighborhood Search
            encoder.setComputePipelineState(self.assignParticlesToGridPSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
            // Density Buffer Binding
            encoder.setBuffer(self.velocityBuffer, offset: 0, index: VelocityBuffer.index)
        
            // Density Calculation
            encoder.setComputePipelineState(self.densityPSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
            // Force Buffer Binding
            encoder.setBuffer(self.forceK1Buffer, offset: 0, index: ForceBuffer.index)
            
            // Force Calculation
            encoder.setComputePipelineState(self.forcePSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            
            // Integration Calculation
            encoder.setComputePipelineState(rk4Step1PSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            // }
            
            // Runge Kutta 4 - Step 2
            // {
            // Reset GridCounts to zero
            //encoder.setComputePipelineState(self.initCountGridPSO)
            //encoder.dispatchThreadgroups(self.threadgroupCountGrid, threadsPerThreadgroup: self.threadgroupSize)
        
            // Neighborhood Search
            //encoder.setComputePipelineState(self.assignParticlesToGridPSO)
            //encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
            // Density Buffer Binding
            encoder.setBuffer(self.velocityK1Buffer, offset: 0, index: VelocityBuffer.index)
            
        
            // Density Calculation
            encoder.setComputePipelineState(self.densityPSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            
            // Force Buffer Binding
            encoder.setBuffer(self.forceK2Buffer, offset: 0, index: ForceBuffer.index)
            
            // Force Calculation
            encoder.setComputePipelineState(self.forcePSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            
            // Integration Calculation
            encoder.setComputePipelineState(self.rk4Step2PSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            // }
        
            // Runge Kutta 4 - Step 3
            // {
            // Reset GridCounts to zero
            //encoder.setComputePipelineState(self.initCountGridPSO)
            //encoder.dispatchThreadgroups(self.threadgroupCountGrid, threadsPerThreadgroup: self.threadgroupSize)
        
            // Neighborhood Search
            //encoder.setComputePipelineState(self.assignParticlesToGridPSO)
            //encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
            // Density Buffer Binding
            encoder.setBuffer(self.velocityK2Buffer, offset: 0, index: VelocityBuffer.index)
            
            
            // Density Calculation
            encoder.setComputePipelineState(self.densityPSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
            // Force Buffer Binding
            encoder.setBuffer(self.forceK3Buffer, offset: 0, index: ForceBuffer.index)
            
            // Force Calculation
            encoder.setComputePipelineState(self.forcePSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            
            // Integration Calculation
            encoder.setComputePipelineState(self.rk4Step3PSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            // }
        
            // Runge Kutta 4 - Step 4
            // {
            // Reset GridCounts to zero
            //encoder.setComputePipelineState(self.initCountGridPSO)
            //encoder.dispatchThreadgroups(self.threadgroupCountGrid, threadsPerThreadgroup: self.threadgroupSize)
        
            // Neighborhood Search
            //encoder.setComputePipelineState(self.assignParticlesToGridPSO)
            //encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
            // Density Buffer Binding
            encoder.setBuffer(self.velocityK3Buffer, offset: 0, index: VelocityBuffer.index)
            
            // Density Calculation
            encoder.setComputePipelineState(self.densityPSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            
            // Force Buffer Binding
            encoder.setBuffer(self.forceK4Buffer, offset: 0, index: ForceBuffer.index)
            
            // Force Calculation
            encoder.setComputePipelineState(self.forcePSO)
            encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
            // }
        //}
        
        // Final Integration Buffers Binding
            // Velocities
        encoder.setBuffer(self.velocityBuffer, offset: 0, index: VelocityBuffer.index)
        
        // Final Integration Step - Combine all RK4 intermediate values to update position and velocity
        encoder.setComputePipelineState(self.rk4FinalPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
        // Collision Handling
        encoder.setComputePipelineState(self.collisionPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
        encoder.endEncoding()
    }
}

extension PhysicRenderPass {
    
    func initializePositions(device: MTLDevice, commandQueue: MTLCommandQueue, camera: OrthographicCamera) {
        // Create a command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create command buffer or compute encoder")
        }

        // Set the compute pipeline state
        encoder.setComputePipelineState(self.initPositionPSO)

        // Set buffers
        encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionKBuffer.index)

        // Set constants sending
        var constants = InitPositionConstants(
            particleNumber: UInt32(self.particleNumber),
            viewWidth: Float(camera.viewSize) * Float(camera.aspect),
            viewHeight: Float(camera.viewSize)
        )
        encoder.setBytes(&constants, length: MemoryLayout<InitPositionConstants>.stride, index: ConstantBuffer.index)

        // Dispatch threads
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Commit and wait for completion
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
