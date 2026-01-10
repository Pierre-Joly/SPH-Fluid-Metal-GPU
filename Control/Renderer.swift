import MetalKit

enum IntegrationMethod: String, CaseIterable, Identifiable {
    case rk4 = "RK4"
    case rk2 = "RK2"
    case predictorCorrector = "PC"
    case verlet = "Verlet"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum RenderMode: String, CaseIterable, Identifiable {
    case particles = "Particles"
    case density = "Density"
    case velocity = "Velocity"

    var id: String { rawValue }
    var label: String { rawValue }
}

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!

    var camera = OrthographicCamera()
    let particleNumber: Int
    var isPaused: Bool = false
    
    var physicRenderPass: PhysicRenderPass
    var graphicRenderPass: GraphicRenderPass
    var quadModel: QuadModel
    var particleSize: Float
    var stiffness: Float
    var restDensity: Float
    var viscosity: Float
    var gravityMultiplier: Float
    var integrationMethod: IntegrationMethod
    var dtValue: Float
    var substeps: Int
    var renderMode: RenderMode
    var gridResolution: Int
    
    init(metalView: MTKView, particleNumber: Int, particleSize: Float, stiffness: Float, restDensity: Float, viscosity: Float, gravityMultiplier: Float, integrationMethod: IntegrationMethod, dtValue: Float, substeps: Int, renderMode: RenderMode, gridResolution: Int) {
        self.particleNumber = particleNumber
        self.particleSize = particleSize
        self.stiffness = stiffness
        self.restDensity = restDensity
        self.viscosity = viscosity
        self.gravityMultiplier = gravityMultiplier
        self.integrationMethod = integrationMethod
        self.dtValue = dtValue
        self.substeps = substeps
        self.renderMode = renderMode
        self.gridResolution = gridResolution
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
                                                 camera: self.camera,
                                                 particleSize: particleSize,
                                                 stiffness: stiffness,
                                                 restDensity: restDensity,
                                                 viscosity: viscosity,
                                                 gravityMultiplier: gravityMultiplier,
                                                 integrationMethod: integrationMethod,
                                                 dtValue: dtValue,
                                                 substeps: substeps)
        
        self.graphicRenderPass = GraphicRenderPass(view: metalView,
                                                   device: device,
                                                   physicPass: self.physicRenderPass,
                                                   quad: quadModel,
                                                   camera: self.camera,
                                                   particleSize: particleSize,
                                                   renderMode: renderMode,
                                                   gridResolution: gridResolution)

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
        if !isPaused {
            physicRenderPass.draw(commandBuffer: commandBuffer)
        }
        
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

extension Renderer {
    func resetSimulation() {
        physicRenderPass.initializePositions(
            device: Self.device,
            commandQueue: Self.commandQueue,
            camera: camera
        )
    }

    func updateRestDensity(_ value: Float) {
        restDensity = value
        physicRenderPass.updateRestDensity(value)
    }

    func updateViscosity(_ value: Float) {
        viscosity = value
        physicRenderPass.updateViscosity(value)
    }

    func updateGravityMultiplier(_ value: Float) {
        gravityMultiplier = value
        physicRenderPass.updateGravityMultiplier(value)
    }

    func updateStiffness(_ value: Float) {
        stiffness = value
        physicRenderPass.updateStiffness(value)
    }

    func updateParticleSize(_ value: Float) {
        particleSize = value
        physicRenderPass.updateParticleSize(value)
        graphicRenderPass.updateParticleSize(value)
    }

    func updateIntegrationMethod(_ value: IntegrationMethod) {
        integrationMethod = value
        physicRenderPass.updateIntegrationMethod(value)
    }

    func updateDT(_ value: Float) {
        dtValue = value
        physicRenderPass.updateDT(value)
    }

    func updateSubsteps(_ value: Int) {
        substeps = value
        physicRenderPass.updateSubsteps(value)
    }

    func updateRenderMode(_ value: RenderMode) {
        renderMode = value
        graphicRenderPass.updateRenderMode(value)
    }

    func updateGridResolution(_ value: Int) {
        gridResolution = value
        graphicRenderPass.updateDensityGridResolution(value)
    }
}
