import SwiftUI

struct GradientBackground: View {
    private let detail = 30
    private let speed = 1.29
    private let blurRadius: CGFloat = 24

    private let palette: [SIMD3<Double>] = [
        SIMD3(226.0 / 255.0, 33.0 / 255.0, 223.0 / 255.0),
        SIMD3(204.0 / 255.0, 243.0 / 255.0, 16.0 / 255.0),
        SIMD3(20.0 / 255.0, 223.0 / 255.0, 53.0 / 255.0),
        SIMD3(219.0 / 255.0, 31.0 / 255.0, 195.0 / 255.0)
    ]

    private let baseAnchors: [CGPoint] = [
        CGPoint(x: 0.16, y: 0.18),
        CGPoint(x: 0.84, y: 0.20),
        CGPoint(x: 0.22, y: 0.84),
        CGPoint(x: 0.82, y: 0.80)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0, paused: false)) { timeline in
            Canvas(opaque: true, colorMode: .linear) { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate * speed
                let anchors = animatedAnchors(time: t)

                let columns = detail
                let rows = detail
                let cellWidth = size.width / CGFloat(columns)
                let cellHeight = size.height / CGFloat(rows)

                for row in 0..<rows {
                    let y = (Double(row) + 0.5) / Double(rows)
                    for column in 0..<columns {
                        let x = (Double(column) + 0.5) / Double(columns)
                        let color = color(at: CGPoint(x: x, y: y), anchors: anchors)
                        let cell = CGRect(
                            x: CGFloat(column) * cellWidth,
                            y: CGFloat(row) * cellHeight,
                            width: cellWidth + 1,
                            height: cellHeight + 1
                        )
                        context.fill(Path(cell), with: .color(color))
                    }
                }
            }
            .blur(radius: blurRadius)
            .saturation(1.18)
        }
        .ignoresSafeArea()
        .drawingGroup()
    }

    private func animatedAnchors(time: Double) -> [CGPoint] {
        [
            move(baseAnchors[0], time: time, xScale: 0.10, yScale: 0.08, phase: 0.0),
            move(baseAnchors[1], time: time, xScale: 0.12, yScale: 0.09, phase: 1.2),
            move(baseAnchors[2], time: time, xScale: 0.08, yScale: 0.11, phase: 2.4),
            move(baseAnchors[3], time: time, xScale: 0.10, yScale: 0.10, phase: 3.1)
        ]
    }

    private func move(
        _ point: CGPoint,
        time: Double,
        xScale: Double,
        yScale: Double,
        phase: Double
    ) -> CGPoint {
        let x = point.x + CGFloat(sin(time * 0.45 + phase) * xScale)
        let y = point.y + CGFloat(cos(time * 0.39 + phase * 1.3) * yScale)
        return CGPoint(x: x.clamped(to: 0...1), y: y.clamped(to: 0...1))
    }

    private func color(at point: CGPoint, anchors: [CGPoint]) -> Color {
        var weighted = SIMD3<Double>(0, 0, 0)
        var total = 0.0

        for index in anchors.indices {
            let dx = Double(point.x - anchors[index].x)
            let dy = Double(point.y - anchors[index].y)
            let distance = sqrt(dx * dx + dy * dy)
            let weight = 1.0 / pow(distance + 0.06, 2.2)
            weighted += palette[index] * weight
            total += weight
        }

        let output = weighted / max(total, 0.0001)
        return Color(
            .sRGB,
            red: output.x.clamped(to: 0...1),
            green: output.y.clamped(to: 0...1),
            blue: output.z.clamped(to: 0...1),
            opacity: 1
        )
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
