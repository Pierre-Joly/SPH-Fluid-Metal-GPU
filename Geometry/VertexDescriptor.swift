import MetalKit

extension MTLVertexDescriptor {
    static var defaultLayout: MTLVertexDescriptor? {
        return MTKMetalVertexDescriptorFromModelIO(.defaultLayout)
    }
}

extension MDLVertexDescriptor {
    static var defaultLayout: MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        
        // Position attribute (attribute 0)
        vertexDescriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float2,
            offset: 0,
            bufferIndex: VertexBuffer.index)
        offset += MemoryLayout<SIMD2<Float>>.stride
        
        // Vertex buffer layout
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
}

extension BufferIndices {
    var index: Int {
        return Int(self.rawValue)
    }
}
