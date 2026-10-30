import SwiftUI
import UIKit

// MARK: - 符号动效 / 数字滚动 / 触感（iOS 16 兜底）

enum GCSymbolEffect {
    case wiggle
    case bounce
    case pulse
}

enum GCSensoryKind {
    case success
    case warning
    case error
    case impact
}

extension View {
    /// 等价于 iOS 17 的 `.symbolEffect(_:value:)`；iOS 16 上静默不生效。
    /// 注意：`.wiggle` 实际是 iOS 18 才引入，必须再套一层 18.0 判断。
    @ViewBuilder
    func gcSymbolEffect<V: Equatable>(_ effect: GCSymbolEffect, value: V) -> some View {
        if #available(iOS 17.0, *) {
            switch effect {
            case .wiggle:
                if #available(iOS 18.0, *) {
                    self.symbolEffect(.wiggle, value: value)
                } else {
                    self.symbolEffect(.bounce, value: value)
                }
            case .bounce:
                self.symbolEffect(.bounce, value: value)
            case .pulse:
                self.symbolEffect(.pulse, value: value)
            }
        } else {
            self
        }
    }

    /// 等价于 `.symbolEffect(.pulse, options: .repeating, isActive:)`。
    @ViewBuilder
    func gcPulseSymbol(isActive: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.pulse, options: .repeating, isActive: isActive)
        } else {
            self.modifier(GCPulseFallback(active: isActive))
        }
    }

    /// 等价于 iOS 17 的 `.contentTransition(.numericText())`。
    @ViewBuilder
    func gcNumericText() -> some View {
        if #available(iOS 17.0, *) {
            self.contentTransition(.numericText())
        } else {
            self
        }
    }

    /// 等价于 iOS 17 的 `.sensoryFeedback(_:trigger:)`。
    func gcSensoryFeedback<T: Equatable>(_ kind: GCSensoryKind, trigger: T) -> some View {
        modifier(GCSensoryModifier(kind: kind, trigger: trigger))
    }
}

extension View {
    /// 等价于 iOS 17 的 `.scrollTransition(.interactive, axis:)` 淡入淡出。
    /// iOS 16 上滚动过渡 API 不存在，直接返回原视图（不影响布局与命中）。
    @ViewBuilder
    func gcScrollFade(
        axis: Axis = .vertical,
        minOpacity: Double = 0.6,
        minScale: CGFloat = 0.98
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTransition(.interactive, axis: axis) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : minOpacity)
                    .scaleEffect(phase.isIdentity ? 1 : minScale)
            }
        } else {
            self
        }
    }
}

/// iOS 16 上没有 symbolEffect，用透明度呼吸近似 pulse。
private struct GCPulseFallback: ViewModifier {
    let active: Bool
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(active && pulsing ? 0.45 : 1)
            .animation(
                active
                    ? Animation.easeInOut(duration: 0.85).repeatForever(autoreverses: true)
                    : Animation.default,
                value: pulsing
            )
            .onAppear { pulsing = active }
            .onChange(of: active) { newValue in pulsing = newValue }
    }
}

private struct GCSensoryModifier<T: Equatable>: ViewModifier {
    let kind: GCSensoryKind
    let trigger: T

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.sensoryFeedback(kind.feedback, trigger: trigger)
        } else {
            content.onChange(of: trigger) { _ in
                GCSensoryModifier.play(kind)
            }
        }
    }

    @MainActor
    static func play(_ kind: GCSensoryKind) {
        switch kind {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .impact:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

private extension GCSensoryKind {
    @available(iOS 17.0, *)
    var feedback: SensoryFeedback {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        case .impact: return .impact(weight: .medium)
        }
    }
}
