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
    var verletStep1PSO: MTLComputePipelineState
    var verletStep2PSO: MTLComputePipelineState
    var rk2FinalPSO: MTLComputePipelineState
    var pcPredictPSO: MTLComputePipelineState
    var pcCorrectPSO: MTLComputePipelineState
    var collisionPSO: MTLComputePipelineState
    // Mapping (Morton + radix sort)
    var mortonCodesPSO: MTLComputePipelineState
    var radixFlagsPSO: MTLComputePipelineState
    var radixScanBlockPSO: MTLComputePipelineState
    var radixScanBlockSumsPSO: MTLComputePipelineState
    var radixAddOffsetsPSO: MTLComputePipelineState
    var radixTotalZerosPSO: MTLComputePipelineState
    var radixScatterPSO: MTLComputePipelineState
    var clearCellRangesPSO: MTLComputePipelineState
    var buildCellRangesPSO: MTLComputePipelineState
    var reorderPositionsVelocitiesPSO: MTLComputePipelineState
    var reorderDensityPressurePSO: MTLComputePipelineState
    
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
    var blockSumsBuffer: MTLBuffer
    var blockOffsetsBuffer: MTLBuffer
    var mortonCodesBuffer: MTLBuffer
    var mortonTempBuffer: MTLBuffer
    var particleIdsTempBuffer: MTLBuffer
    var cellLinearBuffer: MTLBuffer
    var cellLinearTempBuffer: MTLBuffer
    var radixFlagsBuffer: MTLBuffer
    var radixPrefixBuffer: MTLBuffer
    var totalZerosBuffer: MTLBuffer
    var sortedPositionBuffer: MTLBuffer
    var sortedVelocityBuffer: MTLBuffer
    var sortedDensityBuffer: MTLBuffer
    var sortedPressureBuffer: MTLBuffer
    
    // Uniforms Grid parameters
    var totalGridCells: Int
    var gridRes: uint2
    var origin: float2
    var invCell: Float
    var particleSize: Float
    var stiffness: Float
    var restDensity: Float
    var viscosity: Float
    var gravityMultiplier: Float
    var integrationMethod: IntegrationMethod
    var dtValue: Float
    var substeps: Int
    let viewWidth: Float
    let viewHeight: Float
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let camera: OrthographicCamera
    
    // Constants
    let particleNumber: Int
    let threadgroupSize: MTLSize
    let threadgroupCount: MTLSize
    let scanBlockSize: Int
    var scanBlockCount: Int
    var mortonBitCount: Int
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue, particleNumber: Int, camera: OrthographicCamera, particleSize: Float, stiffness: Float, restDensity: Float, viscosity: Float, gravityMultiplier: Float, integrationMethod: IntegrationMethod, dtValue: Float, substeps: Int) {
        
        // Constants
        self.particleNumber = particleNumber
        self.particleSize = particleSize
        self.stiffness = stiffness
        self.restDensity = restDensity
        self.viscosity = viscosity
        self.gravityMultiplier = gravityMultiplier
        self.integrationMethod = integrationMethod
        self.dtValue = dtValue
        self.substeps = max(1, substeps)
        self.viewWidth = Float(camera.viewSize) * Float(camera.aspect)
        self.viewHeight = Float(camera.viewSize)
        self.device = device
        self.commandQueue = commandQueue
        self.camera = camera
        self.scanBlockSize = 256
        
        // Uniforms Grid parameters
        let gridConfig = PhysicRenderPass.gridConfig(
            particleSize: particleSize,
            viewWidth: self.viewWidth,
            viewHeight: self.viewHeight
        )
        self.totalGridCells = gridConfig.totalGridCells
        self.scanBlockCount = (particleNumber + self.scanBlockSize - 1) / self.scanBlockSize
        self.gridRes = gridConfig.gridRes
        self.origin = gridConfig.origin
        self.invCell = gridConfig.invCell
        self.mortonBitCount = PhysicRenderPass.mortonBitCount(gridRes: self.gridRes)
        
        // Create compute pipeline states
        self.initPositionPSO = PipelineStates.createComputePSO(function: "init_position")
        self.densityPSO = PipelineStates.createComputePSO(function: "density")
        self.forcePSO = PipelineStates.createComputePSO(function: "force")
        self.rk4Step1PSO = PipelineStates.createComputePSO(function: "rk4_step1")
        self.rk4Step2PSO = PipelineStates.createComputePSO(function: "rk4_step2")
        self.rk4Step3PSO = PipelineStates.createComputePSO(function: "rk4_step3")
        self.rk4FinalPSO = PipelineStates.createComputePSO(function: "integrateRK4Results")
        self.verletStep1PSO = PipelineStates.createComputePSO(function: "verlet_step1")
        self.verletStep2PSO = PipelineStates.createComputePSO(function: "verlet_step2")
        self.rk2FinalPSO = PipelineStates.createComputePSO(function: "integrateRK2Results")
        self.pcPredictPSO = PipelineStates.createComputePSO(function: "pc_predict")
        self.pcCorrectPSO = PipelineStates.createComputePSO(function: "pc_correct")
        self.collisionPSO = PipelineStates.createComputePSO(function: "collision")
        // Mapping (Morton + radix sort)
        self.mortonCodesPSO        = PipelineStates.createComputePSO(function: "compute_morton_codes")
        self.radixFlagsPSO         = PipelineStates.createComputePSO(function: "radix_bit_flags")
        self.radixScanBlockPSO     = PipelineStates.createComputePSO(function: "radix_scan_block_exclusive")
        self.radixScanBlockSumsPSO = PipelineStates.createComputePSO(function: "radix_scan_block_sums_exclusive")
        self.radixAddOffsetsPSO    = PipelineStates.createComputePSO(function: "radix_add_block_offsets")
        self.radixTotalZerosPSO    = PipelineStates.createComputePSO(function: "radix_total_zeros")
        self.radixScatterPSO       = PipelineStates.createComputePSO(function: "radix_scatter")
        self.clearCellRangesPSO    = PipelineStates.createComputePSO(function: "clear_cell_ranges")
        self.buildCellRangesPSO    = PipelineStates.createComputePSO(function: "build_cell_ranges")
        self.reorderPositionsVelocitiesPSO = PipelineStates.createComputePSO(function: "reorder_positions_velocities")
        self.reorderDensityPressurePSO = PipelineStates.createComputePSO(function: "reorder_density_pressure")
        
        
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
            let cellStartBuffer = device.makeBuffer(length: self.totalGridCells * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let cellEndBuffer = device.makeBuffer(length: self.totalGridCells * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let particleIdsBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let blockSumsBuffer = device.makeBuffer(length: self.scanBlockCount * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let blockOffsetsBuffer = device.makeBuffer(length: self.scanBlockCount * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let mortonCodesBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let mortonTempBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let particleIdsTempBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let cellLinearBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let cellLinearTempBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let radixFlagsBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let radixPrefixBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let totalZerosBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let sortedPositionBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let sortedVelocityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let sortedDensityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate),
            let sortedPressureBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate)
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
        self.blockSumsBuffer = blockSumsBuffer
        self.blockOffsetsBuffer = blockOffsetsBuffer
        self.mortonCodesBuffer = mortonCodesBuffer
        self.mortonTempBuffer = mortonTempBuffer
        self.particleIdsTempBuffer = particleIdsTempBuffer
        self.cellLinearBuffer = cellLinearBuffer
        self.cellLinearTempBuffer = cellLinearTempBuffer
        self.radixFlagsBuffer = radixFlagsBuffer
        self.radixPrefixBuffer = radixPrefixBuffer
        self.totalZerosBuffer = totalZerosBuffer
        self.sortedPositionBuffer = sortedPositionBuffer
        self.sortedVelocityBuffer = sortedVelocityBuffer
        self.sortedDensityBuffer = sortedDensityBuffer
        self.sortedPressureBuffer = sortedPressureBuffer
        
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
    
    private func encodeBuildRanges(commandBuffer: MTLCommandBuffer, positions: MTLBuffer) {
        let particleNumber = self.particleNumber
        let totalGridCells = self.totalGridCells
        let scanBlockCount = self.scanBlockCount
        
        var gridRes  = self.gridRes
        var origin = self.origin
        var invCell = self.invCell
        var N32 = UInt32(particleNumber)
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create compute encoder for Morton codes")
        }
        
        // Morton codes + initial ids + cell linear ids
        encoder.setComputePipelineState(mortonCodesPSO)
        encoder.setBuffer(positions, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(mortonCodesBuffer, offset: 0, index: MortonCodeBuffer.index)
        encoder.setBuffer(particleIdsBuffer, offset: 0, index: ParticleIdsBuffer.index)
        encoder.setBuffer(cellLinearBuffer, offset: 0, index: CellLinearBuffer.index)
        encoder.setBytes(&gridRes,  length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.setBytes(&origin, length: MemoryLayout<float2>.stride, index: OriginBuffer.index)
        encoder.setBytes(&invCell, length: MemoryLayout<Float>.stride, index: InvCellBuffer.index)
        encoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
        dispatch1D(encoder, particleNumber)
        encoder.endEncoding()
        
        var useTemp = false
        for bit in 0..<mortonBitCount {
            guard let radixEncoder = commandBuffer.makeComputeCommandEncoder() else {
                fatalError("Failed to create compute encoder for radix")
            }
            
            let keysIn = useTemp ? mortonTempBuffer : mortonCodesBuffer
            let idsIn = useTemp ? particleIdsTempBuffer : particleIdsBuffer
            let cellIn = useTemp ? cellLinearTempBuffer : cellLinearBuffer
            let keysOut = useTemp ? mortonCodesBuffer : mortonTempBuffer
            let idsOut = useTemp ? particleIdsBuffer : particleIdsTempBuffer
            let cellOut = useTemp ? cellLinearBuffer : cellLinearTempBuffer
            var bitIndex = UInt32(bit)
            
            // Flags for current bit
            radixEncoder.setComputePipelineState(radixFlagsPSO)
            radixEncoder.setBuffer(keysIn, offset: 0, index: MortonCodeBuffer.index)
            radixEncoder.setBuffer(radixFlagsBuffer, offset: 0, index: RadixFlagsBuffer.index)
            radixEncoder.setBytes(&bitIndex, length: MemoryLayout<UInt32>.stride, index: BitIndexBuffer.index)
            radixEncoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            dispatch1D(radixEncoder, particleNumber)
            
            // Prefix scan on flags
            radixEncoder.setComputePipelineState(radixScanBlockPSO)
            radixEncoder.setBuffer(radixFlagsBuffer, offset: 0, index: RadixFlagsBuffer.index)
            radixEncoder.setBuffer(radixPrefixBuffer, offset: 0, index: RadixPrefixBuffer.index)
            radixEncoder.setBuffer(blockSumsBuffer, offset: 0, index: BlockSumsBuffer.index)
            radixEncoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            radixEncoder.dispatchThreadgroups(
                MTLSize(width: scanBlockCount, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: scanBlockSize, height: 1, depth: 1)
            )
            
            radixEncoder.setComputePipelineState(radixScanBlockSumsPSO)
            radixEncoder.setBuffer(blockSumsBuffer, offset: 0, index: BlockSumsBuffer.index)
            radixEncoder.setBuffer(blockOffsetsBuffer, offset: 0, index: BlockOffsetsBuffer.index)
            radixEncoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            radixEncoder.dispatchThreadgroups(
                MTLSize(width: 1, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: scanBlockSize, height: 1, depth: 1)
            )
            
            radixEncoder.setComputePipelineState(radixAddOffsetsPSO)
            radixEncoder.setBuffer(radixPrefixBuffer, offset: 0, index: RadixPrefixBuffer.index)
            radixEncoder.setBuffer(blockOffsetsBuffer, offset: 0, index: BlockOffsetsBuffer.index)
            radixEncoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            dispatch1D(radixEncoder, particleNumber, tpg: scanBlockSize)
            
            // Total zeros
            radixEncoder.setComputePipelineState(radixTotalZerosPSO)
            radixEncoder.setBuffer(radixFlagsBuffer, offset: 0, index: RadixFlagsBuffer.index)
            radixEncoder.setBuffer(radixPrefixBuffer, offset: 0, index: RadixPrefixBuffer.index)
            radixEncoder.setBuffer(totalZerosBuffer, offset: 0, index: TotalZerosBuffer.index)
            radixEncoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            dispatch1D(radixEncoder, 1, tpg: 1)
            
            // Scatter
            radixEncoder.setComputePipelineState(radixScatterPSO)
            radixEncoder.setBuffer(keysIn, offset: 0, index: MortonCodeBuffer.index)
            radixEncoder.setBuffer(idsIn, offset: 0, index: ParticleIdsBuffer.index)
            radixEncoder.setBuffer(cellIn, offset: 0, index: CellLinearBuffer.index)
            radixEncoder.setBuffer(radixFlagsBuffer, offset: 0, index: RadixFlagsBuffer.index)
            radixEncoder.setBuffer(radixPrefixBuffer, offset: 0, index: RadixPrefixBuffer.index)
            radixEncoder.setBuffer(totalZerosBuffer, offset: 0, index: TotalZerosBuffer.index)
            radixEncoder.setBuffer(keysOut, offset: 0, index: MortonTempBuffer.index)
            radixEncoder.setBuffer(idsOut, offset: 0, index: ParticleIdsTempBuffer.index)
            radixEncoder.setBuffer(cellOut, offset: 0, index: CellLinearTempBuffer.index)
            radixEncoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
            dispatch1D(radixEncoder, particleNumber)
            
            radixEncoder.endEncoding()
            useTemp.toggle()
        }
        
        if useTemp {
            swap(&mortonCodesBuffer, &mortonTempBuffer)
            swap(&particleIdsBuffer, &particleIdsTempBuffer)
            swap(&cellLinearBuffer, &cellLinearTempBuffer)
        }
        
        guard let rangeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create compute encoder for cell ranges")
        }
        
        rangeEncoder.setComputePipelineState(clearCellRangesPSO)
        rangeEncoder.setBuffer(cellStartBuffer, offset: 0, index: CellStartBuffer.index)
        rangeEncoder.setBuffer(cellEndBuffer, offset: 0, index: CellEndBuffer.index)
        rangeEncoder.setBytes(&gridRes, length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        dispatch1D(rangeEncoder, totalGridCells)
        
        rangeEncoder.setComputePipelineState(buildCellRangesPSO)
        rangeEncoder.setBuffer(cellLinearBuffer, offset: 0, index: CellLinearBuffer.index)
        rangeEncoder.setBuffer(cellStartBuffer, offset: 0, index: CellStartBuffer.index)
        rangeEncoder.setBuffer(cellEndBuffer, offset: 0, index: CellEndBuffer.index)
        rangeEncoder.setBytes(&N32, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
        dispatch1D(rangeEncoder, particleNumber)
        
        rangeEncoder.endEncoding()
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
        
        // Zero dynamic buffers
        encoder.endEncoding()
        zeroSimulationBuffers(commandBuffer: commandBuffer)

        // Commit and wait for completion
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func draw(commandBuffer: MTLCommandBuffer) {
        let steps = max(1, substeps)
        for _ in 0..<steps {
            runPhysicsStep(commandBuffer: commandBuffer)
        }
    }

    private func runPhysicsStep(commandBuffer: MTLCommandBuffer) {
        encodeBuildRanges(commandBuffer: commandBuffer, positions: self.positionBuffer)

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create compute command buffer")
        }

        // Bind Buffers
        // Constants
        var numParticles = UInt32(self.particleNumber)
        encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
        var particleSize = self.particleSize
        encoder.setBytes(&particleSize, length: MemoryLayout<Float>.stride, index: ParticleSizeBuffer.index)
        var stiffnessValue = stiffness
        encoder.setBytes(&stiffnessValue, length: MemoryLayout<Float>.stride, index: StiffnessBuffer.index)
        var restDensityValue = restDensity
        encoder.setBytes(&restDensityValue, length: MemoryLayout<Float>.stride, index: RestDensityBuffer.index)
        var viscosityValue = viscosity
        encoder.setBytes(&viscosityValue, length: MemoryLayout<Float>.stride, index: ViscosityBuffer.index)
        var dtValue = self.dtValue
        encoder.setBytes(&dtValue, length: MemoryLayout<Float>.stride, index: DTBuffer.index)
        var gravityMultiplier = self.gravityMultiplier
        encoder.setBytes(&gravityMultiplier, length: MemoryLayout<Float>.stride, index: GravityBuffer.index)
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
        encoder.setBuffer(self.sortedPositionBuffer, offset: 0, index: SortedPositionBuffer.index)
        encoder.setBuffer(self.sortedVelocityBuffer, offset: 0, index: SortedVelocityBuffer.index)
        encoder.setBuffer(self.sortedDensityBuffer, offset: 0, index: SortedDensityBuffer.index)
        encoder.setBuffer(self.sortedPressureBuffer, offset: 0, index: SortedPressureBuffer.index)
        // Mapping constants
        var gridRes  = self.gridRes
        var origin = self.origin
        var invCell = self.invCell
        encoder.setBytes(&gridRes,  length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.setBytes(&origin, length: MemoryLayout<float2>.stride, index: OriginBuffer.index)
        encoder.setBytes(&invCell, length: MemoryLayout<Float>.stride, index: InvCellBuffer.index)

        switch integrationMethod {
        case .rk4:
            runRK4(encoder: encoder)
        case .verlet:
            runVerlet(encoder: encoder)
        case .rk2:
            runRK2(encoder: encoder)
        case .predictorCorrector:
            runPredictorCorrector(encoder: encoder)
        }
        
        // Collision Handling
        encoder.setComputePipelineState(self.collisionPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
        encoder.endEncoding()
    }

}

extension PhysicRenderPass {
    func updateStiffness(_ value: Float) {
        stiffness = value
    }

    func updateRestDensity(_ value: Float) {
        restDensity = value
    }

    func updateViscosity(_ value: Float) {
        viscosity = value
    }

    func updateGravityMultiplier(_ value: Float) {
        gravityMultiplier = value
    }

    func updateParticleSize(_ value: Float) {
        particleSize = value
        let gridConfig = PhysicRenderPass.gridConfig(
            particleSize: value,
            viewWidth: viewWidth,
            viewHeight: viewHeight
        )
        gridRes = gridConfig.gridRes
        totalGridCells = gridConfig.totalGridCells
        origin = gridConfig.origin
        invCell = gridConfig.invCell
        mortonBitCount = PhysicRenderPass.mortonBitCount(gridRes: gridRes)
        rebuildCellBuffers()
        initializePositions(device: device, commandQueue: commandQueue, camera: camera)
    }

    func updateIntegrationMethod(_ value: IntegrationMethod) {
        integrationMethod = value
    }

    func updateDT(_ value: Float) {
        dtValue = value
    }

    func updateSubsteps(_ value: Int) {
        substeps = max(1, value)
    }

    private func rebuildCellBuffers() {
        self.scanBlockCount = (particleNumber + scanBlockSize - 1) / scanBlockSize
        guard
            let cellStartBuffer = device.makeBuffer(length: totalGridCells * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let cellEndBuffer = device.makeBuffer(length: totalGridCells * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let blockSumsBuffer = device.makeBuffer(length: scanBlockCount * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let blockOffsetsBuffer = device.makeBuffer(length: scanBlockCount * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let mortonCodesBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let mortonTempBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let particleIdsTempBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let cellLinearBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let cellLinearTempBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let radixFlagsBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let radixPrefixBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let totalZerosBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModePrivate),
            let sortedPositionBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let sortedVelocityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<float2>.stride, options: .storageModePrivate),
            let sortedDensityBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate),
            let sortedPressureBuffer = device.makeBuffer(length: particleNumber * MemoryLayout<Float>.stride, options: .storageModePrivate)
        else {
            fatalError("Failed to recreate cell buffers")
        }
        self.cellStartBuffer = cellStartBuffer
        self.cellEndBuffer = cellEndBuffer
        self.blockSumsBuffer = blockSumsBuffer
        self.blockOffsetsBuffer = blockOffsetsBuffer
        self.mortonCodesBuffer = mortonCodesBuffer
        self.mortonTempBuffer = mortonTempBuffer
        self.particleIdsTempBuffer = particleIdsTempBuffer
        self.cellLinearBuffer = cellLinearBuffer
        self.cellLinearTempBuffer = cellLinearTempBuffer
        self.radixFlagsBuffer = radixFlagsBuffer
        self.radixPrefixBuffer = radixPrefixBuffer
        self.totalZerosBuffer = totalZerosBuffer
        self.sortedPositionBuffer = sortedPositionBuffer
        self.sortedVelocityBuffer = sortedVelocityBuffer
        self.sortedDensityBuffer = sortedDensityBuffer
        self.sortedPressureBuffer = sortedPressureBuffer
    }

    private static func gridConfig(particleSize: Float, viewWidth: Float, viewHeight: Float) -> (gridRes: uint2, totalGridCells: Int, origin: float2, invCell: Float) {
        let cellSize = max(particleSize * 4.0, 1e-5)
        let gridX = max(1, Int(ceil(viewWidth / cellSize)))
        let gridY = max(1, Int(ceil(viewHeight / cellSize)))
        let gridRes = uint2(UInt32(gridX), UInt32(gridY))
        let totalGridCells = gridX * gridY
        let origin = float2(-viewWidth * 0.5, -viewHeight * 0.5)
        let invCell = 1.0 / cellSize
        return (gridRes, totalGridCells, origin, invCell)
    }

    private static func mortonBitCount(gridRes: uint2) -> Int {
        let maxDim = max(Int(gridRes.x), Int(gridRes.y))
        var bits = 0
        var value = 1
        while value < maxDim {
            value <<= 1
            bits += 1
        }
        return max(1, bits * 2)
    }

    private func zeroSimulationBuffers(commandBuffer: MTLCommandBuffer) {
        guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            fatalError("Failed to create blit encoder")
        }

        let zeroBuffers: [MTLBuffer] = [
            velocityBuffer,
            velocityK1Buffer,
            velocityK2Buffer,
            velocityK3Buffer,
            forceK1Buffer,
            forceK2Buffer,
            forceK3Buffer,
            forceK4Buffer,
            densityBuffer,
            pressureBuffer
        ]

        for buffer in zeroBuffers {
            blitEncoder.fill(buffer: buffer, range: 0..<buffer.length, value: 0)
        }

        blitEncoder.endEncoding()
    }
}
