import SwiftUI

// MARK: - 根：两页(主页 / 统计)横向翻页
struct MainView: View {
    @EnvironmentObject var health: HealthModel

    var body: some View {
        TabView {
            HomeView().environmentObject(health)
            StatsView().environmentObject(health)
        }
        .tabViewStyle(.verticalPage)
        .background(Palette.bg.ignoresSafeArea())
    }
}

// 兼容旧引用
struct ContentView: View {
    var body: some View { MainView() }
}

// MARK: - 主页
struct HomeView: View {
    @EnvironmentObject var health: HealthModel

    var body: some View {
        let t = health.travel
        ZStack {
            Palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    // 真实定位(顶部)
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Palette.accent)
                        Text(health.realCity)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Palette.muted)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)

                    // 进度环 + 步数
                    ZStack {
                        Circle().stroke(Palette.ring, lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: max(0, min(t.progress, 1)))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [Palette.accent, Palette.primary]),
                                    center: .center,
                                    startAngle: .degrees(-90), endAngle: .degrees(270)),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(t.steps)")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(Palette.text)
                                .minimumScaleFactor(0.5).lineLimit(1)
                            Text("steps")
                                .font(.system(size: 10))
                                .foregroundColor(Palette.muted)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(width: 118, height: 118)

                    // 旅途城市卡片
                    VStack(spacing: 3) {
                        Text("NOW EXPLORING")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.2)
                            .foregroundColor(Palette.muted)
                        Text(t.city)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Palette.primary)
                        if !t.nextCity.isEmpty {
                            Text("\(t.remaining) steps to \(t.nextCity)")
                                .font(.system(size: 10))
                                .foregroundColor(Palette.muted)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("All cities unlocked 🎉")
                                .font(.system(size: 10))
                                .foregroundColor(Palette.muted)
                        }
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))

                    if !health.authorized {
                        Button("Allow Health") { health.start() }
                            .font(.system(size: 12, weight: .semibold))
                            .tint(Palette.primary)
                    } else {
                        Button { health.refresh() } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 11))
                        }
                        .tint(Palette.primary)
                    }

                    Text("Swipe up for stats")
                        .font(.system(size: 8))
                        .foregroundColor(Palette.muted.opacity(0.6))
                        .padding(.top, 2)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - 统计页
struct StatsView: View {
    @EnvironmentObject var health: HealthModel

    var body: some View {
        let t = health.travel
        ZStack {
            Palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Palette.text)
                        .padding(.top, 6)

                    // 顶部统计数字
                    HStack(spacing: 8) {
                        statBox("\(t.steps)", "steps today")
                        statBox("\(t.unlockedCount)/\(kCities.count)", "cities")
                    }

                    // 城市进度列表
                    VStack(spacing: 0) {
                        ForEach(Array(kCities.enumerated()), id: \.offset) { i, c in
                            let unlocked = t.steps >= c.stepRequired
                            let isCurrent = c.name == t.city
                            HStack(spacing: 8) {
                                Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(unlocked ? Palette.accent : Palette.muted.opacity(0.5))
                                Text(c.name)
                                    .font(.system(size: 13, weight: isCurrent ? .bold : .regular))
                                    .foregroundColor(isCurrent ? Palette.primary : (unlocked ? Palette.text : Palette.muted))
                                Spacer()
                                Text("\(c.stepRequired)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Palette.muted.opacity(0.7))
                            }
                            .padding(.vertical, 6)
                            if i < kCities.count - 1 {
                                Divider().background(Palette.ring)
                            }
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
        }
    }

    private func statBox(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Palette.accent)
                .minimumScaleFactor(0.5).lineLimit(1)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.card))
    }
}

#Preview {
    let h = HealthModel()
    h.travel = TravelState.from(steps: 15000)
    h.authorized = true
    h.realCity = "Milan"
    return MainView().environmentObject(h)
}
