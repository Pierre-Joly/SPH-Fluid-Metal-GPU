import MetalKit

class PhysicRenderPass {
    // Pipeline state objects
    var initPositionPSO: MTLComputePipelineState
    var densityPSO: MTLComputePipelineState
    var forcePSO: MTLComputePipelineState
    var rk4Step1PSO: MTLComputePipelineState
    var rk4Step2PSO: MTLComputePipelineState
    var rk4Step3PSO: MTLComputePipelineState
    var rk4FinalPSO: MTLComputePipelineState
    var collisionPSO: MTLComputePipelineState
    // Mapping
    var zeroCellsPSO: MTLComputePipelineState
    var histogramCellsPSO: MTLComputePipelineState
    var exclusiveScanCountsPSO: MTLComputePipelineState
    var copyStartsToEndsPSO: MTLComputePipelineState
    var scatterSortedIdsPSO: MTLComputePipelineState
    
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
        // mapping
    var cellStartBuffer: MTLBuffer
    var cellEndBuffer: MTLBuffer
    var particleIdsBuffer: MTLBuffer
    
    // Uniforms Grid parameters
    var totalGridCells: Int
    var gridRes: uint2
    var origin: float2
    var invCell: Float
    
    // Constants
    let particleNumber: Int
    let threadgroupSize: MTLSize
    let threadgroupCount: MTLSize
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue, particleNumber: Int, camera: OrthographicCamera) {
        
        // Constants
        self.particleNumber = particleNumber
        
        // Uniforms Grid parameters
        self.totalGridCells = 1600
        self.gridRes = uint2(40, 40)
        self.origin = float2(
            -Float(camera.viewSize) * Float(camera.aspect) * 0.5,
             -Float(camera.viewSize) * 0.5
        )
        let cellSize: Float = 0.05
        self.invCell = 1.0 / cellSize
        
        // Create compute pipeline states
        self.initPositionPSO = PipelineStates.createComputePSO(function: "init_position")
        self.densityPSO = PipelineStates.createComputePSO(function: "density")
        self.forcePSO = PipelineStates.createComputePSO(function: "force")
        self.rk4Step1PSO = PipelineStates.createComputePSO(function: "rk4_step1")
        self.rk4Step2PSO = PipelineStates.createComputePSO(function: "rk4_step2")
        self.rk4Step3PSO = PipelineStates.createComputePSO(function: "rk4_step3")
        self.rk4FinalPSO = PipelineStates.createComputePSO(function: "integrateRK4Results")
        self.collisionPSO = PipelineStates.createComputePSO(function: "collision")
        // Mapping
        self.zeroCellsPSO          = PipelineStates.createComputePSO(function: "zero_cells")
        self.histogramCellsPSO     = PipelineStates.createComputePSO(function: "histogram_cells")
        self.exclusiveScanCountsPSO = PipelineStates.createComputePSO(function: "exclusive_scan_counts")
        self.copyStartsToEndsPSO   = PipelineStates.createComputePSO(function: "copy_starts_to_ends")
        self.scatterSortedIdsPSO   = PipelineStates.createComputePSO(function: "scatter_sorted_ids")
        
        
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
            
                // Mapping
            let cellStartBuffer           = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let cellEndBuffer       = device.makeBuffer(length: self.totalGridCells * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let particleIdsBuffer = device.makeBuffer(length: self.totalGridCells * MemoryLayout<UInt32>.stride, options: .storageModePrivate)
        else {
            fatalError("Failed to create one or more buffers")
        }
        
        // Assign position and velocity buffers
        self.positionBuffer = positionBuffer
        self.velocityBuffer = velocityBuffer
        
        // Assign RK4 buffers
        self.positionKBuffer = positionKBuffer
        self.velocityK1Buffer = velocityK1Buffer
        self.velocityK2Buffer = velocityK2Buffer
        self.velocityK3Buffer = velocityK3Buffer
        self.forceK1Buffer = forceK1Buffer
        self.forceK2Buffer = forceK2Buffer
        self.forceK3Buffer = forceK3Buffer
        self.forceK4Buffer = forceK4Buffer
        self.cellStartBuffer = cellStartBuffer
        self.cellEndBuffer = cellEndBuffer
        self.particleIdsBuffer = particleIdsBuffer
        
        // Physics buffers
        self.densityBuffer = densityBuffer
        self.pressureBuffer = pressureBuffer
        
        // Threading
        self.threadgroupSize  = MTLSize(width: 256, height: 1, depth: 1)
        let groups = (particleNumber + threadgroupSize.width - 1) / threadgroupSize.width
        self.threadgroupCount = MTLSize(width: groups, height: 1, depth: 1)
        
        // Initialize positions
        self.initializePositions(device: device, commandQueue: commandQueue, camera: camera)
    }
    
    @inline(__always)
    private func dispatch1D(_ encoder: MTLComputeCommandEncoder, _ n: Int, tpg: Int = 256) {
        encoder.dispatchThreads(MTLSize(width: n, height: 1, depth: 1),
                            threadsPerThreadgroup: MTLSize(width: tpg, height: 1, depth: 1))
    }
    
    private func encodeBuildRanges(_ encoder: MTLComputeCommandEncoder, positions: MTLBuffer) {
        let particleNumber = self.particleNumber
        let totalGridCells = self.totalGridCells
        
        var gridRes  = self.gridRes
        var origin = self.origin
        var invCell = self.invCell
        var N32 = UInt32(particleNumber)
        
        // zero counts in cellStart
        encoder.setComputePipelineState(zeroCellsPSO)
        encoder.setBuffer(cellStartBuffer, offset: 0, index: CellStartBuffer.index)
        encoder.setBytes(&gridRes,  length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        dispatch1D(encoder, totalGridCells)
        
        // histogram counts per cell
        encoder.setComputePipelineState(histogramCellsPSO)
        encoder.setBuffer(positions,              offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(cellStartBuffer,    offset: 0, index: CellStartBuffer.index)
        encoder.setBytes(&gridRes,  length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.setBytes(&origin, length: MemoryLayout<float2>.stride, index: OriginBuffer.index)
        encoder.setBytes(&invCell, length: MemoryLayout<Float>.stride,       index: InvCellBuffer.index)
        encoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride,      index: NumParticlesBuffer.index)
        dispatch1D(encoder, particleNumber)
        
        // exclusive scan in-place: counts -> starts
        encoder.setComputePipelineState(exclusiveScanCountsPSO)
        encoder.setBuffer(cellStartBuffer, offset: 0, index: CellStartBuffer.index)
        encoder.setBytes(&gridRes, length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        dispatch1D(encoder, 1, tpg: 1)
        
        // copy starts -> ends
        encoder.setComputePipelineState(copyStartsToEndsPSO)
        encoder.setBuffer(cellStartBuffer, offset: 0, index: CellStartBuffer.index)
        encoder.setBuffer(cellEndBuffer,   offset: 0, index: CellEndBuffer.index)
        encoder.setBytes(&gridRes, length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        dispatch1D(encoder, totalGridCells)
        
        // scatter particle IDs by cell
        encoder.setComputePipelineState(scatterSortedIdsPSO)
        encoder.setBuffer(positions,                    offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(cellEndBuffer,           offset: 0, index: CellEndBuffer.index)
        encoder.setBuffer(particleIdsBuffer,  offset: 0, index: ParticleIdsBuffer.index)
        encoder.setBytes(&gridRes,  length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.setBytes(&origin, length: MemoryLayout<float2>.stride, index: OriginBuffer.index)
        encoder.setBytes(&invCell, length: MemoryLayout<Float>.stride,       index: InvCellBuffer.index)
        encoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride,      index: NumParticlesBuffer.index)
        dispatch1D(encoder, particleNumber)
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
        encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionKBuffer.index)
        
        // Set constants sending
        var numParticles = UInt32(self.particleNumber)
        encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
        var viewWidth = Float(camera.viewSize) * Float(camera.aspect)
        encoder.setBytes(&viewWidth, length: MemoryLayout<Float>.stride, index: ViewWidthBuffer.index)
        var viewHeight = Float(camera.viewSize)
        encoder.setBytes(&viewHeight, length: MemoryLayout<Float>.stride, index: ViewHeightBuffer.index)
        
        // Dispatch threads
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
        // Commit and wait for completion
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
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
        // Mapping
        encoder.setBuffer(self.cellStartBuffer, offset: 0, index: CellStartBuffer.index)
        encoder.setBuffer(self.cellEndBuffer, offset: 0, index: CellEndBuffer.index)
        encoder.setBuffer(self.particleIdsBuffer, offset: 0, index: ParticleIdsBuffer.index)
        // Mapping constants
        var gridRes  = self.gridRes
        var origin = self.origin
        var invCell = self.invCell
        encoder.setBytes(&gridRes,  length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.setBytes(&origin, length: MemoryLayout<uint2>.stride, index: OriginBuffer.index)
        encoder.setBytes(&invCell, length: MemoryLayout<Float>.stride, index: InvCellBuffer.index)

        
        // RK4 Step Computation
        //{
        // Runge Kutta 4 - Step 1
        // {
        // Position Buffer Binding
        encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
        
        // Mapping
        encodeBuildRanges(encoder, positions: self.positionBuffer)
        
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
        // Position Buffer Binding
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionBuffer.index)

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
        
        // Positions
        encoder.setBuffer(self.positionBuffer,  offset: 0, index: PositionBuffer.index)
        
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
