import SwiftUI

struct SimulationSurface: View {
    let containerSize: CGSize
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
    @Binding var gravityMultiplier: Float
    @Binding var renderMode: RenderMode
    @Binding var gridResolution: Int

    var body: some View {
        MetalView(
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
        .aspectRatio(1, contentMode: .fit)
        .frame(
            minWidth: min(520, containerSize.width * 0.6),
            maxWidth: .infinity,
            minHeight: min(520, containerSize.height * 0.7),
            maxHeight: .infinity
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
    }
}
