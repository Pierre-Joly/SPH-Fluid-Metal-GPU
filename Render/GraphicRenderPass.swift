//
//  GraphicRenderPass.swift
//  SPH
//
//  Created by Pierre joly on 28/08/2024.
//

import MetalKit

struct GraphicRenderPass {
    var descriptor: MTLRenderPassDescriptor?
    var graphicPSO: MTLRenderPipelineState!
    var vertexFunction: MTLFunction!
    
    var quad: QuadModel
    
    // Buffer provenant du PhysicRenderPass
    var positionBuffer: MTLBuffer
    var velocityBuffer: MTLBuffer
    
    // Constant
    var particleNumber: Int
    var uniforms: Uniforms
    
    // Add properties for the texture and sampler
    var circleTexture: MTLTexture
    var samplerState: MTLSamplerState
    
    // Vertex Argument
    var vertexArgumentBuffer: MTLBuffer
    var vertexArgumentEncoder: MTLArgumentEncoder
        
    init(view: MTKView, device: MTLDevice, physicPass: PhysicRenderPass, quad: QuadModel, camera: OrthographicCamera) {
            // Create the pipeline state and retrieve the vertex function
            let (pso, vertexFunc) = PipelineStates.createGraphicPSO(colorPixelFormat: view.colorPixelFormat)
            self.graphicPSO = pso
            self.vertexFunction = vertexFunc
            
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
            
            // Create the circle texture
            self.circleTexture = GraphicRenderPass.createCircleTexture(device: device, size: 4)
            
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
        }
    
    func draw(commandBuffer: MTLCommandBuffer) {
        guard let descriptor = descriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        // Configure the render pipeline state
        renderEncoder.setRenderPipelineState(self.graphicPSO)
        
        // Set the vertex buffer
        var uniforms = self.uniforms
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        renderEncoder.setVertexBuffer(quad.vertexBuffer, offset: 0, index: VertexBuffer.index)
        renderEncoder.setVertexBuffer(vertexArgumentBuffer, offset: 0, index: VertexArgumentBuffer.index)
        
        // Set the fragment texture and sampler
        renderEncoder.setFragmentTexture(circleTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        // Draw the quads using triangle strip without indexing
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4,
                                     instanceCount: particleNumber)
        
        renderEncoder.endEncoding()
    }

}

extension GraphicRenderPass {
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
        let radius = Float(size) / 5
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
}
