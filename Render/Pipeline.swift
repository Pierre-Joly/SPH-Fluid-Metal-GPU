import MetalKit

enum PipelineStates {
    static func createPSO(descriptor: MTLRenderPipelineDescriptor) -> MTLRenderPipelineState {
        let pipelineState: MTLRenderPipelineState
        
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Error creating pipeline state: \(error.localizedDescription)")
        }
        
        return pipelineState
    }
    
    static func createComputePSO(function: String) -> MTLComputePipelineState {
        guard let kernel = Renderer.library.makeFunction(name: function)
            else { fatalError("Unable to create \(function) compute function") }
        
        let pipelineState: MTLComputePipelineState
        
        do {
            pipelineState = try Renderer.device.makeComputePipelineState(function: kernel)
        } catch {
            fatalError("Error creating compute pipeline state: \(error.localizedDescription)")
        }
        
        return pipelineState
    }
    
    static func createGraphicPSO(colorPixelFormat: MTLPixelFormat) -> (MTLRenderPipelineState, MTLFunction) {
        guard let vertexFunction = Renderer.library.makeFunction(name: "vertex_main"),
              let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main") else {
            fatalError("Failed to load shader functions")
        }
        
        // Use your existing vertex descriptor
        guard let vertexDescriptor = MTLVertexDescriptor.defaultLayout else {
            fatalError("Failed to create vertex descriptor")
        }
        
        // Create the pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        
        // Enable alpha blending
        if let attachment = pipelineDescriptor.colorAttachments[0] {
            attachment.isBlendingEnabled = true
            attachment.rgbBlendOperation = .add
            attachment.alphaBlendOperation = .add
            attachment.sourceRGBBlendFactor = .sourceAlpha
            attachment.sourceAlphaBlendFactor = .sourceAlpha
            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }
        let pso = createPSO(descriptor: pipelineDescriptor)
        return (pso, vertexFunction)
    }

    static func createDensityPSO(colorPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        guard let vertexFunction = Renderer.library.makeFunction(name: "density_vertex"),
              let fragmentFunction = Renderer.library.makeFunction(name: "density_fragment") else {
            fatalError("Failed to load density shader functions")
        }

        guard let vertexDescriptor = MTLVertexDescriptor.defaultLayout else {
            fatalError("Failed to create vertex descriptor")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        if let attachment = pipelineDescriptor.colorAttachments[0] {
            attachment.isBlendingEnabled = true
            attachment.rgbBlendOperation = .add
            attachment.alphaBlendOperation = .add
            attachment.sourceRGBBlendFactor = .sourceAlpha
            attachment.sourceAlphaBlendFactor = .sourceAlpha
            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }

        return createPSO(descriptor: pipelineDescriptor)
    }
}
