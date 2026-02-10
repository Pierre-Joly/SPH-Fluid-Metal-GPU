import MetalKit

struct GraphicRenderPass {
    var device: MTLDevice
    var descriptor: MTLRenderPassDescriptor?
    var graphicPSO: MTLRenderPipelineState!
    var vertexFunction: MTLFunction!
    var densityPSO: MTLRenderPipelineState!
    var renderMode: RenderMode
    
    var quad: QuadModel
    
    // Buffer coming from PhysicRenderPass
    var positionBuffer: MTLBuffer
    var velocityBuffer: MTLBuffer
    var densityGridBuffer: MTLBuffer
    
    // Constant
    var particleNumber: Int
    var uniforms: Uniforms
    var particleSize: Float
    var densityScale: Float
    var viewWidth: Float
    var viewHeight: Float
    var densityGridRes: uint2
    var gridBaseRes: Int
    var densityTexture: MTLTexture
    var clearDensityGridPSO: MTLComputePipelineState
    var accumulateDensityGridPSO: MTLComputePipelineState
    var densityToTexturePSO: MTLComputePipelineState
    
    // Properties for the texture and sampler
    var circleTexture: MTLTexture
    var samplerState: MTLSamplerState
    
    // Vertex Argument
    var vertexArgumentBuffer: MTLBuffer
    var vertexArgumentEncoder: MTLArgumentEncoder
        
    init(view: MTKView, device: MTLDevice, physicPass: PhysicRenderPass, quad: QuadModel, camera: OrthographicCamera, particleSize: Float, renderMode: RenderMode, gridResolution: Int) {
            self.device = device

            // Create the pipeline state and retrieve the vertex function
            let (pso, vertexFunc) = PipelineStates.createGraphicPSO(colorPixelFormat: view.colorPixelFormat)
            self.graphicPSO = pso
            self.vertexFunction = vertexFunc
            self.densityPSO = PipelineStates.createDensityPSO(colorPixelFormat: view.colorPixelFormat)
            self.renderMode = renderMode
            
            // Retrieve buffers from the physics simulation
            self.positionBuffer = physicPass.positionBuffer
            self.velocityBuffer = physicPass.velocityBuffer
            self.particleNumber = physicPass.particleNumber
            
            // Quad vertex model
            self.quad = quad
        
            // Create uniforms
            var uniforms = Uniforms()
            uniforms.projectionMatrix = camera.projectionMatrix
            uniforms.viewMatrix = camera.viewMatrix
            self.uniforms = uniforms
            
            self.particleSize = particleSize
            self.densityScale = 0.02
            self.viewWidth = Float(camera.viewSize) * Float(camera.aspect)
            self.viewHeight = Float(camera.viewSize)
            self.gridBaseRes = gridResolution
            self.densityGridRes = GraphicRenderPass.densityGridResolution(baseRes: gridResolution, viewWidth: self.viewWidth, viewHeight: self.viewHeight)
            self.densityTexture = GraphicRenderPass.createDensityTexture(device: device, width: Int(densityGridRes.x), height: Int(densityGridRes.y))
            self.clearDensityGridPSO = PipelineStates.createComputePSO(function: "clear_density_grid")
            self.accumulateDensityGridPSO = PipelineStates.createComputePSO(function: "accumulate_density_grid")
            self.densityToTexturePSO = PipelineStates.createComputePSO(function: "density_grid_to_texture")
            
            // Create the circle texture
            self.circleTexture = GraphicRenderPass.createCircleTexture(device: device, size: 16)
            
            // Create the sampler state
            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            samplerDescriptor.sAddressMode = .clampToEdge
            samplerDescriptor.tAddressMode = .clampToEdge
            guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor)
            else {
                fatalError("Failed to create sampler state")
            }
            self.samplerState = sampler

            // Create the Argument Encoder from the vertex function
            self.vertexArgumentEncoder = vertexFunction.makeArgumentEncoder(bufferIndex: VertexArgumentBuffer.index)
            
            // Allocate the Argument Buffer
            let argumentBufferLength = vertexArgumentEncoder.encodedLength
            guard let vertexArgumentBuffer = device.makeBuffer(length: argumentBufferLength, options: []) else {
                fatalError("Failed to create argument buffer")
            }
        
            self.vertexArgumentBuffer = vertexArgumentBuffer
            vertexArgumentEncoder.setArgumentBuffer(vertexArgumentBuffer, offset: 0)
            
            // Assign buffers to the argument one
            vertexArgumentEncoder.setBuffer(positionBuffer, offset: 0, index: 0)
            vertexArgumentEncoder.setBuffer(velocityBuffer, offset: 0, index: 1)

            let gridCount = Int(densityGridRes.x * densityGridRes.y)
            guard let densityGridBuffer = device.makeBuffer(length: gridCount * MemoryLayout<UInt32>.stride, options: .storageModePrivate) else {
                fatalError("Failed to create density grid buffer")
            }
            self.densityGridBuffer = densityGridBuffer
        }
    
    func draw(commandBuffer: MTLCommandBuffer) {
        guard let descriptor = descriptor else { return }

        if renderMode != .particles {
            encodeDensityField(commandBuffer: commandBuffer)
            drawDensityTexture(commandBuffer: commandBuffer, descriptor: descriptor)
        } else {
            drawParticles(commandBuffer: commandBuffer, descriptor: descriptor)
        }
    }

}

extension GraphicRenderPass {
    mutating func updateParticleSize(_ size: Float) {
        particleSize = size
    }

    mutating func updateRenderMode(_ mode: RenderMode) {
        renderMode = mode
    }

    mutating func updateDensityGridResolution(_ baseRes: Int) {
        gridBaseRes = baseRes
        densityGridRes = GraphicRenderPass.densityGridResolution(baseRes: baseRes, viewWidth: viewWidth, viewHeight: viewHeight)
        densityTexture = GraphicRenderPass.createDensityTexture(device: device, width: Int(densityGridRes.x), height: Int(densityGridRes.y))
        let gridCount = Int(densityGridRes.x * densityGridRes.y)
        guard let densityGridBuffer = device.makeBuffer(length: gridCount * MemoryLayout<UInt32>.stride, options: .storageModePrivate) else {
            fatalError("Failed to create density grid buffer")
        }
        self.densityGridBuffer = densityGridBuffer
    }

    static func createCircleTexture(device: MTLDevice, size: Int) -> MTLTexture {
        // Define the texture descriptor
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = size
        textureDescriptor.height = size
        textureDescriptor.usage = .shaderRead
        
        // Create the texture
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create texture")
        }
        
        // Generate the circle image data
        var pixelData = [UInt8](repeating: 0, count: size * size * 4) // 4 bytes per pixel (RGBA)
        let radius = Float(size) / 2.0
        let radiusSqr = radius * radius
        let center = Float(size) / 2.0
        
        for y in 0..<size {
            for x in 0..<size {
                let dx = Float(x) - center + 0.5 // +0.5 for pixel center alignment
                let dy = Float(y) - center + 0.5
                let distanceSqr = dx * dx + dy * dy
                
                // Determine the alpha value based on the distance
                let alpha: UInt8 = distanceSqr <= radiusSqr ? 255 : 0

                
                // Set the pixel data (white color with variable alpha)
                let pixelIndex = (y * size + x) * 4
                pixelData[pixelIndex] = 255      // Red
                pixelData[pixelIndex + 1] = 255  // Green
                pixelData[pixelIndex + 2] = 255  // Blue
                pixelData[pixelIndex + 3] = alpha  // Alpha
            }
        }
        
        // Upload the pixel data to the texture
        let region = MTLRegionMake2D(0, 0, size, size)
        texture.replace(region: region, mipmapLevel: 0, withBytes: pixelData, bytesPerRow: size * 4)
        
        return texture
    }

    static func createDensityTexture(device: MTLDevice, width: Int, height: Int) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float,
                                                                          width: width,
                                                                          height: height,
                                                                          mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create density texture")
        }
        return texture
    }

    static func densityGridResolution(baseRes: Int, viewWidth: Float, viewHeight: Float) -> uint2 {
        let aspect = viewWidth / max(viewHeight, 0.0001)
        let gridX = max(1, UInt32(round(Float(baseRes) * aspect)))
        let gridY = max(1, UInt32(baseRes))
        return uint2(gridX, gridY)
    }

    private func encodeDensityField(commandBuffer: MTLCommandBuffer) {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        var gridRes = self.densityGridRes
        var origin = float2(-viewWidth * 0.5, -viewHeight * 0.5)
        var viewWidth = self.viewWidth
        var viewHeight = self.viewHeight
        var numParticles = UInt32(self.particleNumber)
        var densityScale = self.densityScale
        if renderMode == .velocity {
            densityScale = -densityScale
        }

        let totalCells = Int(gridRes.x * gridRes.y)
        encoder.setComputePipelineState(clearDensityGridPSO)
        encoder.setBuffer(densityGridBuffer, offset: 0, index: ForceBuffer.index)
        encoder.setBytes(&gridRes, length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.dispatchThreads(MTLSize(width: totalCells, height: 1, depth: 1),
                                threadsPerThreadgroup: MTLSize(width: 256, height: 1, depth: 1))

        encoder.setComputePipelineState(accumulateDensityGridPSO)
        encoder.setBuffer(positionBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(velocityBuffer, offset: 0, index: VelocityBuffer.index)
        encoder.setBuffer(densityGridBuffer, offset: 0, index: ForceBuffer.index)
        encoder.setBytes(&gridRes, length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.setBytes(&origin, length: MemoryLayout<float2>.stride, index: OriginBuffer.index)
        encoder.setBytes(&viewWidth, length: MemoryLayout<Float>.stride, index: ViewWidthBuffer.index)
        encoder.setBytes(&viewHeight, length: MemoryLayout<Float>.stride, index: ViewHeightBuffer.index)
        encoder.setBytes(&numParticles, length: MemoryLayout<UInt32>.stride, index: NumParticlesBuffer.index)
        encoder.setBytes(&densityScale, length: MemoryLayout<Float>.stride, index: DensityScaleBuffer.index)
        encoder.dispatchThreads(MTLSize(width: particleNumber, height: 1, depth: 1),
                                threadsPerThreadgroup: MTLSize(width: 256, height: 1, depth: 1))

        encoder.setComputePipelineState(densityToTexturePSO)
        encoder.setBuffer(densityGridBuffer, offset: 0, index: ForceBuffer.index)
        encoder.setTexture(densityTexture, index: 0)
        encoder.setBytes(&gridRes, length: MemoryLayout<uint2>.stride, index: GridResBuffer.index)
        encoder.setBytes(&densityScale, length: MemoryLayout<Float>.stride, index: DensityScaleBuffer.index)
        encoder.dispatchThreads(MTLSize(width: Int(gridRes.x), height: Int(gridRes.y), depth: 1),
                                threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
        encoder.endEncoding()
    }

    private func drawParticles(commandBuffer: MTLCommandBuffer, descriptor: MTLRenderPassDescriptor) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        renderEncoder.setRenderPipelineState(self.graphicPSO)

        var uniforms = self.uniforms
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        var particleSize = self.particleSize
        renderEncoder.setVertexBytes(&particleSize, length: MemoryLayout<Float>.stride, index: ParticleSizeBuffer.index)
        renderEncoder.setVertexBuffer(quad.vertexBuffer, offset: 0, index: VertexBuffer.index)
        renderEncoder.setVertexBuffer(vertexArgumentBuffer, offset: 0, index: VertexArgumentBuffer.index)

        renderEncoder.setFragmentTexture(circleTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4,
                                     instanceCount: particleNumber)
        renderEncoder.endEncoding()
    }

    private func drawDensityTexture(commandBuffer: MTLCommandBuffer, descriptor: MTLRenderPassDescriptor) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        renderEncoder.setRenderPipelineState(self.densityPSO)
        renderEncoder.setVertexBuffer(quad.vertexBuffer, offset: 0, index: VertexBuffer.index)
        renderEncoder.setFragmentTexture(densityTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}
