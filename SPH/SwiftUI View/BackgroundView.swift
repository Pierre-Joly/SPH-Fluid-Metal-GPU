import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.1, blue: 0.12),
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.12, green: 0.06, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.95, green: 0.7, blue: 0.2).opacity(0.18))
                .frame(width: 380, height: 380)
                .blur(radius: 40)
                .offset(x: -180, y: -160)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(Color(red: 0.2, green: 0.6, blue: 0.8).opacity(0.12))
                .frame(width: 420, height: 260)
                .rotationEffect(.degrees(18))
                .blur(radius: 30)
                .offset(x: 220, y: 200)
        }
        .ignoresSafeArea()
    }
}
