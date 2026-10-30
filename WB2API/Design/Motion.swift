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
