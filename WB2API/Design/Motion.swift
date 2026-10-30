import SwiftUI

/// 动效 token。硬规则：所有动画必须带 `value:`；Reduce Motion 下退化为 opacity。
enum Motion {
    // Animation.snappy / .bouncy / .smooth 都是 iOS 17 预设，16.0 上不存在。
    // 用 spring(response:dampingFraction:) 手工拟合，参数按 Apple 默认曲线取近似值。
    static let spring = Animation.spring(response: 0.28, dampingFraction: 0.78)
    static let snappy = spring  // 别名：部分视图按名字直取
    static let emphasized = Animation.spring(response: 0.45, dampingFraction: 0.65)
    static let numeric = Animation.spring(response: 0.35, dampingFraction: 1.0)
    static let gentle = Animation.easeOut(duration: 0.22)

    /// 错峰入场延迟（索引 × 40ms，封顶 240ms）
    static func stagger(_ index: Int) -> Double {
        min(Double(index) * 0.04, 0.24)
    }
}

/// 尊重「减弱动态效果」的动画选择器。
struct MotionReader<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let content: (Bool) -> Content

    init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }

    var body: some View {
        content(reduceMotion)
    }
}

extension View {
    /// 统一的状态变化动画：Reduce Motion 时只做淡入淡出。
    func motion<V: Equatable>(_ animation: Animation = Motion.spring, value: V) -> some View {
        modifier(MotionModifier(animation: animation, value: value))
    }
}

private struct MotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.gentle : animation, value: value)
    }
}

/// 卡片入场：淡入 + 轻微上移，带错峰。
struct StaggeredAppear: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (shown ? 0 : 10))
            .onAppear {
                withAnimation(Motion.gentle.delay(Motion.stagger(index))) { shown = true }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }
}

// MARK: - iOS 17 API 兼容层（16.0 回退）

/// `onChange(of:) { _, new in }` 双参闭包是 iOS 17 才有的重载。
/// 这里收口成单参语义，两个系统版本都能编。
extension View {
    @ViewBuilder
    func onValueChange<V: Equatable>(of value: V,
                                     perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            onChange(of: value) { _, newValue in action(newValue) }
        } else {
            onChange(of: value, perform: action)
        }
    }
}

/// `sensoryFeedback(_:trigger:)` 是 iOS 17 API；低版本走 UIKit 的 feedback generator。
enum SensoryKind {
    case success
    case selection
    case warning
    case error

    @available(iOS 17.0, *)
    var feedback: SensoryFeedback {
        switch self {
        case .success: return .success
        case .selection: return .selection
        case .warning: return .warning
        case .error: return .error
        }
    }

    func fireLegacy() {
        switch self {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

extension View {
    @ViewBuilder
    func hapticFeedback<V: Equatable>(_ kind: SensoryKind, trigger: V) -> some View {
        if #available(iOS 17.0, *) {
            sensoryFeedback(kind.feedback, trigger: trigger)
        } else {
            onValueChange(of: trigger) { _ in kind.fireLegacy() }
        }
    }
}

/// `contentTransition(.numericText())` 是 iOS 17 API。
/// 低版本保留数字变化的淡入淡出，丢掉滚动效果。
extension View {
    @ViewBuilder
    func numericTransition<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            contentTransition(.numericText()).animation(Motion.numeric, value: value)
        } else {
            animation(Motion.numeric, value: value)
        }
    }
}

/// `symbolEffect(.wiggle)` 是 iOS 17 专属；低版本退化为无动效。
extension View {
    @ViewBuilder
    func wiggleOnChange<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            symbolEffect(.wiggle, value: value)
        } else {
            self
        }
    }
}

