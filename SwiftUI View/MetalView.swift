import SwiftUI
import MetalKit

struct MetalView: View {
    @State private var metalView = MTKView()
    @State private var renderer: Renderer?
    @Binding var particleSize: Float
    @Binding var restDensity: Float
    @Binding var stiffness: Float
    @Binding var particleCount: Int
    @Binding var isRunning: Bool
    @Binding var restartToken: Int
    @Binding var integrationMethod: IntegrationMethod
    @Binding var dtValue: Float
    @Binding var substeps: Int
    @Binding var viscosity: Float
    @Binding var renderMode: RenderMode
    @Binding var gridResolution: Int

    var body: some View {
        MetalViewRepresentable(metalView: $metalView)
            .onAppear {
                renderer = Renderer(
                    metalView: metalView,
                    particleNumber: particleCount,
                    particleSize: particleSize,
                    stiffness: stiffness,
                    restDensity: restDensity,
                    viscosity: viscosity,
                    integrationMethod: integrationMethod,
                    dtValue: dtValue,
                    substeps: substeps,
                    renderMode: renderMode,
                    gridResolution: gridResolution
                )
                renderer?.isPaused = !isRunning
            }
            .onChange(of: particleCount) { _, newValue in
                metalView.delegate = nil
                renderer = Renderer(
                    metalView: metalView,
                    particleNumber: newValue,
                    particleSize: particleSize,
                    stiffness: stiffness,
                    restDensity: restDensity,
                    viscosity: viscosity,
                    integrationMethod: integrationMethod,
                    dtValue: dtValue,
                    substeps: substeps,
                    renderMode: renderMode,
                    gridResolution: gridResolution
                )
                renderer?.isPaused = !isRunning
            }
            .onChange(of: particleSize) { _, newValue in
                renderer?.updateParticleSize(newValue)
            }
            .onChange(of: restDensity) { _, newValue in
                renderer?.updateRestDensity(newValue)
            }
            .onChange(of: stiffness) { _, newValue in
                renderer?.updateStiffness(newValue)
            }
            .onChange(of: viscosity) { _, newValue in
                renderer?.updateViscosity(newValue)
            }
            .onChange(of: isRunning) { _, newValue in
                renderer?.isPaused = !newValue
            }
            .onChange(of: restartToken) { _, _ in
                renderer?.resetSimulation()
            }
            .onChange(of: integrationMethod) { _, newValue in
                renderer?.updateIntegrationMethod(newValue)
            }
            .onChange(of: dtValue) { _, newValue in
                renderer?.updateDT(newValue)
            }
            .onChange(of: substeps) { _, newValue in
                renderer?.updateSubsteps(newValue)
            }
            .onChange(of: renderMode) { _, newValue in
                renderer?.updateRenderMode(newValue)
            }
            .onChange(of: gridResolution) { _, newValue in
                renderer?.updateGridResolution(newValue)
            }
    }
}

typealias ViewRepresentable = NSViewRepresentable

struct MetalViewRepresentable: ViewRepresentable {
  @Binding var metalView: MTKView

  func makeNSView(context: Context) -> some NSView {
    metalView
  }
  func updateNSView(_ uiView: NSViewType, context: Context) {
    updateMetalView()
  }

  func updateMetalView() {
  }
}
