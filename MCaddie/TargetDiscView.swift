import SwiftUI
import MCaddieCore

/// 圆盘选择器：中心表示命中，四周表示 Long / Right / Short / Left 的偏离方向
/// 用于 Fairway Hit 和 Green in Regulation
struct TargetDiscView: View {
    @Binding var selection: TargetResult?
    /// 中心显示的文字，如 "FH"、"GIR"
    let centerLabel: String
    var size: CGFloat = 180

    /// 中心圆占整体半径的比例
    private let innerRatio: CGFloat = 0.42

    var body: some View {
        ZStack {
            ForEach(Self.sectors, id: \.result) { sector in
                sectorView(sector)
            }

            Circle()
                .fill(fillColor(for: .hit))
                .frame(width: size * innerRatio, height: size * innerRatio)
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                .overlay(
                    Text(centerLabel)
                        .font(.headline)
                        .foregroundStyle(selection == .hit ? .white : .primary)
                )
                .contentShape(Circle())
                .onTapGesture { toggle(.hit) }
                .accessibilityElement()
                .accessibilityLabel(centerLabel)
                .accessibilityAddTraits(selection == .hit ? [.isButton, .isSelected] : .isButton)
        }
        .frame(width: size, height: size)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func sectorView(_ sector: Sector) -> some View {
        let shape = AnnularSector(startDegrees: sector.startDegrees, innerRatio: innerRatio)
        // 标签放在环形中间
        let labelRadius = size / 2 * (1 + innerRatio) / 2
        let radians = (sector.startDegrees + 45) * .pi / 180

        return ZStack {
            shape
                .fill(fillColor(for: sector.result))
                .overlay(shape.stroke(Color(.systemBackground), lineWidth: 2))
            Text(sector.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selection == sector.result ? .white : .secondary)
                .offset(x: cos(radians) * labelRadius, y: sin(radians) * labelRadius)
        }
        .contentShape(shape)
        .onTapGesture { toggle(sector.result) }
        .accessibilityElement()
        .accessibilityLabel("Miss \(sector.label)")
        .accessibilityAddTraits(selection == sector.result ? [.isButton, .isSelected] : .isButton)
    }

    /// 再次点击已选项可取消选择
    private func toggle(_ result: TargetResult) {
        selection = (selection == result) ? nil : result
    }

    private func fillColor(for result: TargetResult) -> Color {
        guard selection == result else { return Color(.secondarySystemFill) }
        return result == .hit ? .green : .orange
    }

    // MARK: - 扇区定义

    private struct Sector {
        let result: TargetResult
        let label: String
        /// 起始角度（0° 为右侧，顺时针增加），每个扇区跨 90°
        let startDegrees: Double
    }

    private static let sectors: [Sector] = [
        Sector(result: .missRight, label: "Right", startDegrees: -45),
        Sector(result: .missShort, label: "Short", startDegrees: 45),
        Sector(result: .missLeft, label: "Left", startDegrees: 135),
        Sector(result: .missLong, label: "Long", startDegrees: 225),
    ]
}

/// 90° 的环形扇区
private struct AnnularSector: Shape {
    let startDegrees: Double
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let start = Angle(degrees: startDegrees)
        let end = Angle(degrees: startDegrees + 90)

        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

#Preview {
    @Previewable @State var selection: TargetResult? = .missLeft
    TargetDiscView(selection: $selection, centerLabel: "FH")
}
