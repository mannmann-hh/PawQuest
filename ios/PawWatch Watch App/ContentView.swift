import SwiftUI

struct ContentView: View {
    @EnvironmentObject var health: HealthModel

    var body: some View {
        let s = health.state
        ZStack {
            s.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(s.primary)
                        Text(s.city)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(s.text)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)

                    ZStack {
                        Circle().stroke(s.text.opacity(0.12), lineWidth: 11)
                        Circle()
                            .trim(from: 0, to: max(0, min(s.progress, 1)))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [s.accent, s.primary]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)),
                                style: StrokeStyle(lineWidth: 11, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 1) {
                            Text("\(s.steps)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(s.text)
                                .minimumScaleFactor(0.5).lineLimit(1)
                            Text("steps")
                                .font(.system(size: 11))
                                .foregroundColor(s.text.opacity(0.55))
                        }
                        .padding(.horizontal, 22)
                    }
                    .frame(width: 124, height: 124)

                    if !s.nextCity.isEmpty {
                        VStack(spacing: 2) {
                            Text("\(s.remaining) steps to")
                                .font(.system(size: 11))
                                .foregroundColor(s.text.opacity(0.6))
                            Text(s.nextCity)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(s.primary)
                        }
                    } else {
                        Text("All cities unlocked! 🎉")
                            .font(.system(size: 12))
                            .foregroundColor(s.text.opacity(0.7))
                    }

                    // 授权按钮 + 刷新
                    if !s.authorized {
                        Button("Allow Health") { health.start() }
                            .font(.system(size: 13, weight: .semibold))
                            .tint(s.primary)
                            .padding(.top, 4)
                    } else {
                        Button {
                            health.refresh()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 12))
                        }
                        .tint(s.primary)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
        }
        .onAppear { health.refresh() }   // 已授权时进来直接读
    }
}

#Preview {
    let h = HealthModel()
    h.state = WatchState.from(steps: 15000, authorized: true)
    return ContentView().environmentObject(h)
}
