import MetalKit

class QuadModel {
    var vertexBuffer: MTLBuffer?

    init(device: MTLDevice) {
        // Vertex data for a quad using triangle strip
        let vertices: [Float] = [
            // Position X, Position Y, Position Z, W

            // Vertex 0: Bottom-left
            -0.5, -0.5,

            // Vertex 1: Top-left
            -0.5,  0.5,

            // Vertex 2: Bottom-right
             0.5, -0.5,

            // Vertex 3: Top-right
             0.5,  0.5,
        ]

        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.stride, options: [])
    }
}

