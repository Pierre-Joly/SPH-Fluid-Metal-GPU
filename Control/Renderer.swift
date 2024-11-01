//
//  Renderer.swift
//  SPH
//
//  Created by Pierre joly on 26/08/2024.
//

import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!

    var camera = OrthographicCamera()
    let particleNumber: Int = 8192
    
    var physicRenderPass: PhysicRenderPass
    var graphicRenderPass: GraphicRenderPass
    var quadModel: QuadModel
    
    init(metalView: MTKView) {
        // Create the device and command queue
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else { fatalError("GPU not available") }
        
        Self.device = device
        Self.commandQueue = commandQueue
        metalView.device = device

        // Create the shader function library
        let library = device.makeDefaultLibrary()
        Self.library = library
        
        // Mesh Model
        self.quadModel = QuadModel(device: device)
        
        // Render Pass
        self.physicRenderPass = PhysicRenderPass(device: Self.device,
                                                 commandQueue: Self.commandQueue,
                                                 particleNumber: self.particleNumber,
                                                 camera: self.camera)
        
        self.graphicRenderPass = GraphicRenderPass(view: metalView,
                                                   device: device,
                                                   physicPass: self.physicRenderPass,
                                                   quad: quadModel,
                                                   camera: self.camera)

        super.init()
        
        metalView.clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 1.0)

        metalView.delegate = self
        mtkView(
            metalView,
            drawableSizeWillChange: metalView.drawableSize)
        }
}

extension Renderer: MTKViewDelegate {
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize)
    {

    }

    func draw(in view: MTKView) {
        // set up command
        guard
            let commandBuffer = Self.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor
            else { return }
        
        // Physic computation
        physicRenderPass.draw(commandBuffer: commandBuffer)
        
        // Graphic rendering
        graphicRenderPass.descriptor = descriptor
        graphicRenderPass.draw(commandBuffer: commandBuffer)
        
        // Finish the frame
        guard let drawable = view.currentDrawable
            else { return }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
