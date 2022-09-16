import SwiftUI

struct BarreledRectangle: Shape {
    var barrelness: CGFloat // 0...1 yields (almost) straight lines...semicircles
    
    func path(in rect: CGRect) -> Path {
        let epsilon = 10e-12 // math below doesn't work with 0
        let barrelness = self.barrelness.clamped(to: epsilon...1)
        
        let xChord = rect.width // s
        let yChord = rect.height
        let xHeight = xChord/2*(rect.isLandscape ? barrelness : barrelness/rect.aspectRatio) // a
        let yHeight = yChord/2*(rect.isLandscape ? barrelness*rect.aspectRatio : barrelness)
        
        let xRadius = (4*pow(xHeight, 2.0)+pow(xChord, 2.0))/(8*xHeight) // r
        let yRadius = (4*pow(yHeight, 2.0)+pow(yChord, 2.0))/(8*yHeight)
        let xAlpha = asin(xChord/(2*xRadius)) // alpha
        let yAlpha = asin(yChord/(2*yRadius))
        
        return Path { path in
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.minY-xHeight+xRadius),
                radius: xRadius,
                startAngle: .radians(-xAlpha-Double.pi/2),
                endAngle: .radians(xAlpha-Double.pi/2),
                clockwise: false)
            path.addArc(
                center: CGPoint(x: rect.maxX+yHeight-yRadius, y: rect.midY),
                radius: yRadius,
                startAngle: .radians(-yAlpha),
                endAngle: .radians(yAlpha),
                clockwise: false)
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.maxY+xHeight-xRadius),
                radius: xRadius,
                startAngle: .radians(-xAlpha+Double.pi/2),
                endAngle: .radians(xAlpha+Double.pi/2),
                clockwise: false)
            path.addArc(
                center: CGPoint(x: rect.minX-yHeight+yRadius, y: rect.midY),
                radius: yRadius,
                startAngle: .radians(-yAlpha-Double.pi),
                endAngle: .radians(yAlpha-Double.pi),
                clockwise: false)
        }
    }
}

extension CGRect {
    var aspectRatio: CGFloat {
        get { width/height }
    }
    var isLandscape: Bool {
        get { aspectRatio>1}
    }
    var isPortrait: Bool {
        get { !isLandscape }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
