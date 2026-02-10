import SwiftUI

struct ContentView: View {
    @State private var particleSize: Float = 0.005
    @State private var restDensity: Float = 1000.0
    @State private var stiffness: Float = 1e5
    @State private var viscosity: Float = 1e-2
    @State private var gravityMultiplier: Float = 1.0
    @State private var particleCount: Int = 50_000
    @State private var isRunning: Bool = true
    @State private var restartToken: Int = 0
    @State private var integrationMethod: IntegrationMethod = .rk4
    @State private var dtValue: Float = 5e-5
    @State private var substeps: Int = 1
    @State private var renderMode: RenderMode = .particles
    @State private var gridResolution: Int = 256

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 980
            ZStack {
                BackgroundView()
                Group {
                    if isCompact {
                        VStack(spacing: 20) {
                            ControlPanel(
                                particleSize: $particleSize,
                                restDensity: $restDensity,
                                stiffness: $stiffness,
                                viscosity: $viscosity,
                                gravityMultiplier: $gravityMultiplier,
                                particleCount: $particleCount,
                                isRunning: $isRunning,
                                restartToken: $restartToken,
                                integrationMethod: $integrationMethod,
                                renderMode: $renderMode,
                                dtValue: $dtValue,
                                substeps: $substeps,
                                gridResolution: $gridResolution
                            )
                            SimulationSurface(
                                containerSize: proxy.size,
                                particleSize: $particleSize,
                                restDensity: $restDensity,
                                stiffness: $stiffness,
                                particleCount: $particleCount,
                                isRunning: $isRunning,
                                restartToken: $restartToken,
                                integrationMethod: $integrationMethod,
                                dtValue: $dtValue,
                                substeps: $substeps,
                                viscosity: $viscosity,
                                gravityMultiplier: $gravityMultiplier,
                                renderMode: $renderMode,
                                gridResolution: $gridResolution
                            )
                        }
                    } else {
                        HStack(spacing: 24) {
                            ControlPanel(
                                particleSize: $particleSize,
                                restDensity: $restDensity,
                                stiffness: $stiffness,
                                viscosity: $viscosity,
                                gravityMultiplier: $gravityMultiplier,
                                particleCount: $particleCount,
                                isRunning: $isRunning,
                                restartToken: $restartToken,
                                integrationMethod: $integrationMethod,
                                renderMode: $renderMode,
                                dtValue: $dtValue,
                                substeps: $substeps,
                                gridResolution: $gridResolution
                            )
                            SimulationSurface(
                                containerSize: proxy.size,
                                particleSize: $particleSize,
                                restDensity: $restDensity,
                                stiffness: $stiffness,
                                particleCount: $particleCount,
                                isRunning: $isRunning,
                                restartToken: $restartToken,
                                integrationMethod: $integrationMethod,
                                dtValue: $dtValue,
                                substeps: $substeps,
                                viscosity: $viscosity,
                                gravityMultiplier: $gravityMultiplier,
                                renderMode: $renderMode,
                                gridResolution: $gridResolution
                            )
                        }
                    }
                }
                .padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
