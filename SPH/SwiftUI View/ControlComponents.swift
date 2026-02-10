import SwiftUI

struct ControlSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: FloatingPointFormatStyle<Float>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.custom("Avenir Next", size: 12).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer()
                Text(value, format: format)
                    .font(.custom("Menlo", size: 11))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound)
            )
            .tint(Color(red: 0.9, green: 0.6, blue: 0.2))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

struct ControlStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.custom("Avenir Next", size: 12).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer()
                Text("\(value)")
                    .font(.custom("Menlo", size: 11))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            HStack(spacing: 10) {
                Stepper(
                    value: $value,
                    in: range,
                    step: step
                ) {
                    EmptyView()
                }
                .labelsHidden()
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Int($0 / Double(step)) * step }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .tint(Color(red: 0.3, green: 0.75, blue: 0.6))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

struct ControlPicker: View {
    let title: String
    @Binding var selection: IntegrationMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.custom("Avenir Next", size: 12).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer()
                Text(selection.label)
                    .font(.custom("Menlo", size: 11))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            Picker("", selection: $selection) {
                ForEach(IntegrationMethod.allCases) { method in
                    Text(method.label).tag(method)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Color.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

struct RenderModePicker: View {
    let title: String
    @Binding var selection: RenderMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.custom("Avenir Next", size: 12).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer()
                Text(selection.label)
                    .font(.custom("Menlo", size: 11))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            Picker("", selection: $selection) {
                ForEach(RenderMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Color.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

struct TransportControls: View {
    @Binding var isRunning: Bool
    @Binding var restartToken: Int

    var body: some View {
        HStack(spacing: 12) {
            Button {
                isRunning.toggle()
            } label: {
                Label(isRunning ? "Pause" : "Play", systemImage: isRunning ? "pause.fill" : "play.fill")
                    .font(.custom("Avenir Next", size: 12).weight(.semibold))
                    .foregroundStyle(Color.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.9, green: 0.6, blue: 0.2))
                    )
            }
            .buttonStyle(.plain)

            Button {
                restartToken += 1
            } label: {
                Label("Restart", systemImage: "gobackward")
                    .font(.custom("Avenir Next", size: 12).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

struct InfoPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.custom("Avenir Next", size: 9).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1.2)
            Text(value)
                .font(.custom("Menlo", size: 12))
                .foregroundStyle(Color.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}
