import SwiftUI

struct TriangledRectangle: View {
    var body: some View {
        Group {
            Rectangle()
                .overlay(alignment: .bottom) {
                    IsoscelesTriangle()
                        .fill(LinearGradient(
                            colors: [Color(white: 0.86), .white],
                            startPoint: .center, endPoint: .bottom))
                    }
                .overlay(alignment: .top) {
                    IsoscelesTriangle(apexDirection: .bottom)
                        .fill(LinearGradient(
                            colors: [Color(white: 0.92), .white],
                            startPoint: .top, endPoint: .center))
                }
                .overlay(alignment: .trailing) {
                    IsoscelesTriangle(apexDirection: .leading)
                        .fill(LinearGradient(
                            colors: [Color(white: 0.86), .white], 
                            startPoint: .leading, endPoint: .trailing))
                }
                .overlay(alignment: .leading) {
                    IsoscelesTriangle(apexDirection: .trailing)
                        .fill(LinearGradient(
                            colors: [Color(white: 0.86), .white],
                            startPoint: .leading, endPoint: .center))
                }
        }
    }
}

struct IsoscelesTriangle: Shape {
    var apexDirection: Alignment = .top

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch apexDirection {
        case .top:
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        case .bottom:
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        case .leading:
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        case .trailing:
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        default: // .top
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        }

        return path
    }
}
