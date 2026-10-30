import SwiftUI

// MARK: - 颜色

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    init(light: String, dark: String) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

// MARK: - 间距 / 圆角

enum Metrics {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let minTap: CGFloat = 44

    static let radiusS: CGFloat = 10
    static let radiusM: CGFloat = 16
    static let radiusL: CGFloat = 22
    static let radiusXL: CGFloat = 28

    /// 悬浮 Tab 栏下方的滚动留白，避免最后一张卡片被盖住。
    static let tabBarClearance: CGFloat = 96
}

// MARK: - 字体（只用系统文本样式，Dynamic Type 自动生效）

extension Font {
    /// 大号数字：等宽，避免跳动
    static func metric(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .rounded).monospacedDigit().bold()
    }

    static func metricSmall() -> Font {
        .system(.title2, design: .rounded).monospacedDigit().bold()
    }

    /// 小标签：系统 caption + 轻字距
    static var tag: Font { .caption.weight(.medium) }
}

// MARK: - 玻璃容器（iOS 26 Liquid Glass；iOS 16-25 用等效材质回退）

extension View {
    /// 常规玻璃卡片：用于内容分组。
    func glassCard(padding: CGFloat = Metrics.m, cornerRadius: CGFloat = Metrics.radiusL) -> some View {
        self
            .padding(padding)
            .glassSurface(cornerRadius: cornerRadius, tint: nil, interactive: false, shape: .rect)
    }

    /// 可交互玻璃（按钮组、控件）：带高亮响应。
    func glassInteractive(cornerRadius: CGFloat = Metrics.radiusM) -> some View {
        self.glassSurface(cornerRadius: cornerRadius, tint: nil, interactive: true, shape: .rect)
    }
}

/// 玻璃形状：圆角矩形 / 胶囊。低版本回退也认这一套。
enum GlassShapeKind {
    case rect
    case capsule
}

extension View {
    /// 统一玻璃表面。iOS 26 走原生 Liquid Glass，低版本用 ultraThinMaterial + 描边近似。
    ///
    /// 之所以不用 `AnyShape` 抹平形状差异：`glassEffect(_:in:)` 的泛型参数 `S: Shape`
    /// 在 iOS 26 上是独立重载，`AnyShape` 会丢类型信息导致无法匹配。两个分支各写一份最稳。
    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat,
                      tint: Color?,
                      interactive: Bool,
                      shape: GlassShapeKind = .rect) -> some View {
        if #available(iOS 26.0, *) {
            switch shape {
            case .rect:
                glassEffect(Glass.regular.applying(tint: tint, interactive: interactive),
                            in: .rect(cornerRadius: cornerRadius))
            case .capsule:
                glassEffect(Glass.regular.applying(tint: tint, interactive: interactive),
                            in: .capsule)
            }
        } else {
            let fallback: AnyShape = shape == .capsule
                ? AnyShape(Capsule())
                : AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            background(.ultraThinMaterial, in: fallback)
                .overlay(fallback.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                .clipShape(fallback)
        }
    }
}

@available(iOS 26.0, *)
private extension Glass {
    /// 按需叠加 tint / interactive；顺序与原生语义一致（先 interactive 再 tint）。
    func applying(tint: Color?, interactive: Bool) -> Glass {
        var style = self
        if interactive { style = style.interactive() }
        if let tint { style = style.tint(tint) }
        return style
    }
}
