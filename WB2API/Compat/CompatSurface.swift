import SwiftUI

// MARK: - 扁平卡片（iOS 16 兜底，替代 iOS 26 Liquid Glass）

/// 卡片表面配色：跟随系统深浅色，与 `.background(.background)` 保持层次差。
enum GCSurface {
    /// 卡片填充：浅色下比页面底色略深，深色下比页面底色略浅。
    static var card: Color { Color(uiColor: .secondarySystemBackground) }
    /// 发丝描边：用系统分隔线色，深浅色自动适配。
    static var stroke: Color { Color(uiColor: .separator).opacity(0.6) }
}

/// 与 iOS 26 `Glass` 同构的链式样式（只保留本项目用到的字段）。
struct GCGlassStyle {
    var tintColor: Color?
    var isInteractive = false

    static var regular: GCGlassStyle { GCGlassStyle() }

    func tint(_ color: Color) -> GCGlassStyle {
        var copy = self
        copy.tintColor = color
        return copy
    }

    func interactive() -> GCGlassStyle {
        var copy = self
        copy.isInteractive = true
        return copy
    }
}

/// 与 iOS 26 `GlassShape` 同构的形状描述。
enum GCGlassShape {
    case rect(CGFloat)
    case capsule

    var anyShape: AnyShape {
        switch self {
        case .capsule:
            return AnyShape(Capsule(style: .continuous))
        case .rect(let radius):
            return AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }
}

private struct GCGlassModifier: ViewModifier {
    let style: GCGlassStyle
    let shape: GCGlassShape

    func body(content: Content) -> some View {
        let resolved = shape.anyShape
        content
            .background(GCSurface.card, in: resolved)
            .background(style.tintColor ?? Color.clear, in: resolved)
            .overlay(resolved.stroke(GCSurface.stroke, lineWidth: 0.6))
            .contentShape(resolved)
    }
}

extension View {
    /// iOS 26 `glassEffect(_:in:)` 的等价实现：扁平卡片 + 发丝描边。
    func gcGlass(_ style: GCGlassStyle = .regular, in shape: GCGlassShape = .capsule) -> some View {
        modifier(GCGlassModifier(style: style, shape: shape))
    }
}

// MARK: - 按钮样式（替代 iOS 26 的 .glass / .glassProminent）

struct GCGlassButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(prominent ? .semibold : .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background {
                if prominent {
                    // 用系统强调色渐变：随 .tint(theme.primary) 生效，ButtonStyle 内拿不到 @Environment(\.appTheme)。
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                } else {
                    Capsule(style: .continuous)
                        .fill(GCSurface.card)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(GCSurface.stroke, lineWidth: 0.6)
                        )
                }
            }
            .contentShape(Capsule(style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.gentle, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GCGlassButtonStyle {
    /// 次级按钮：卡片底色胶囊。
    static var gcGlass: GCGlassButtonStyle { GCGlassButtonStyle() }
    /// 主按钮：强调色渐变胶囊。
    static var gcGlassProminent: GCGlassButtonStyle { GCGlassButtonStyle(prominent: true) }
}

// MARK: - 空状态（替代 iOS 17 的 ContentUnavailableView）

/// 与 `ContentUnavailableView` 同形的空状态视图，iOS 16 可用。
struct GCContentUnavailableView<L: View, D: View, A: View>: View {
    private let label: L
    private let description: D
    private let actions: A

    init(
        @ViewBuilder label: () -> L,
        @ViewBuilder description: () -> D,
        @ViewBuilder actions: () -> A
    ) {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: Metrics.s) {
            label
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            description
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions
                .padding(.top, Metrics.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.l)
        .padding(.horizontal, Metrics.m)
    }
}

extension GCContentUnavailableView where A == EmptyView {
    init(@ViewBuilder label: () -> L, @ViewBuilder description: () -> D) {
        self.init(label: label, description: description, actions: { EmptyView() })
    }
}

extension GCContentUnavailableView where L == SwiftUI.Label<Text, Image>, D == Text, A == EmptyView {
    init(_ title: LocalizedStringKey, systemImage: String, description: Text) {
        self.init(
            label: { SwiftUI.Label(title, systemImage: systemImage) },
            description: { description },
            actions: { EmptyView() }
        )
    }

    /// 与 `ContentUnavailableView.search` 等价。
    static var search: Self {
        Self(
            label: { SwiftUI.Label("没有结果", systemImage: "magnifyingglass") },
            description: { Text("换个关键词再试") },
            actions: { EmptyView() }
        )
    }

    /// 与 `ContentUnavailableView.search(text:)` 等价。
    static func search(text: String) -> Self {
        Self(
            label: { SwiftUI.Label("没有结果", systemImage: "magnifyingglass") },
            description: { Text("没有与「\(text)」匹配的内容") },
            actions: { EmptyView() }
        )
    }
}
