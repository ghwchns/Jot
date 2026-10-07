import SwiftUI

struct MerkabaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) * 0.42

        // Upward triangle
        for i in 0..<3 {
            let a = CGFloat(i) * 2.0 * .pi / 3.0 - .pi / 2.0
            let pt = CGPoint(x: cx + r * CoreGraphics.cos(a), y: cy + r * CoreGraphics.sin(a))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        // Downward triangle
        for i in 0..<3 {
            let a = CGFloat(i) * 2.0 * .pi / 3.0 + .pi / 2.0
            let pt = CGPoint(x: cx + r * CoreGraphics.cos(a), y: cy + r * CoreGraphics.sin(a))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        // Inner hexagon
        let ir = r * 0.5
        for i in 0..<6 {
            let a = CGFloat(i) * .pi / 3.0
            let pt = CGPoint(x: cx + ir * CoreGraphics.cos(a), y: cy + ir * CoreGraphics.sin(a))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        // Outer circle
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))

        return path
    }
}
