import SwiftUI

struct ControlPanel: View {
    @Binding var particleSize: Float
    @Binding var restDensity: Float
    @Binding var stiffness: Float
    @Binding var viscosity: Float
    @Binding var gravityMultiplier: Float
    @Binding var particleCount: Int
    @Binding var isRunning: Bool
    @Binding var restartToken: Int
    @Binding var integrationMethod: IntegrationMethod
    @Binding var renderMode: RenderMode
    @Binding var dtValue: Float
    @Binding var substeps: Int
    @Binding var gridResolution: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SPH Lab")
                    .font(.custom("Avenir Next", size: 28).weight(.semibold))
                    .foregroundStyle(Color.white)
                Text("Smooth Particle Hydrodynamics")
                    .font(.custom("Avenir Next", size: 12).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1.6)
            }

            HStack(spacing: 12) {
                InfoPill(title: "Particles", value: "\(particleCount)")
                InfoPill(title: "Solver", value: integrationMethod.label)
                InfoPill(title: "Render", value: renderMode.label)
            }

            TransportControls(isRunning: $isRunning, restartToken: $restartToken)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Controls")
                        .font(.custom("Avenir Next", size: 14).weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))

                    ControlStepper(
                        title: "Particle Count",
                        value: $particleCount,
                        range: 1_024...500_000,
                        step: 1_024
                    )

                ControlPicker(
                    title: "Integration Method",
                    selection: $integrationMethod
                )

                RenderModePicker(
                    title: "Render Mode",
                    selection: $renderMode
                )

                if renderMode != .particles {
                    ControlStepper(
                        title: "Grid Resolution",
                        value: $gridResolution,
                        range: 64...512,
                        step: 32
                    )
                }

                ControlSlider(
                    title: "Time Step (dt)",
                    value: $dtValue,
                        range: 1e-7...5e-5,
                        format: .number.precision(.fractionLength(6))
                    )

                    ControlStepper(
                        title: "Substeps",
                        value: $substeps,
                        range: 1...8,
                        step: 1
                    )

                    ControlSlider(
                        title: "Particle Radius",
                        value: $particleSize,
                        range: 0.001...0.01,
                        format: .number.precision(.fractionLength(3))
                    )

                    ControlSlider(
                        title: "Rest Density",
                        value: $restDensity,
                        range: 0.1...5000,
                        format: .number.precision(.fractionLength(0))
                    )

                    ControlSlider(
                        title: "Stiffness",
                        value: $stiffness,
                        range: 1e1...5e5,
                        format: .number.precision(.fractionLength(2))
                    )

                    ControlSlider(
                        title: "Viscosity",
                        value: $viscosity,
                        range: 1e-6...1e-1,
                        format: .number.precision(.fractionLength(6))
                    )

                    ControlSlider(
                        title: "Gravity Multiplier",
                        value: $gravityMultiplier,
                        range: -100.0...100.0,
                        format: .number.precision(.fractionLength(2))
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.custom("Avenir Next", size: 14).weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                        Text("Particle count and particle radius restarts the simulation with new buffers.")
                            .font(.custom("Avenir Next", size: 12))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .padding(22)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                        .blur(radius: 12)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
