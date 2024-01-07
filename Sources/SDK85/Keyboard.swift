import SwiftUI
import z80

struct Keyboard: View {
    @EnvironmentObject var circuitIO: CircuitIO
    
    var ttyColor: Color
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State private var input = ""
    @FocusState private var focus: Bool
    
    var body: some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact
        
        if !focus {
            Button() {
                focus = true
            } label: {
                Image(systemName: "keyboard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isCompact ? 56 : 96)
                    .foregroundColor(ttyColor)
                    .brightness(-0.2)
            }
        }
        
        TextField("", text: Binding<String>( // https://stackoverflow.com/a/60969666
            get: { self.input },
            set: { value in self.input = value.uppercased() }))
        .focused($focus)
        .onChange(of: input, perform: { value in
            if value.isEmpty { return }
            i8155.SID = input.last!.asciiValue!
        })
        .onSubmit {
            i8155.SID = 0x0D
            input = ""
            focus = true
        }
        .accentColor(.clear)
        .autocorrectionDisabled(true)
        // https://stackoverflow.com/questions/60967877
        .textInputAutocapitalization(.characters) // not working
    }
}

private struct Key: ButtonStyle {
    var angle: Double = 0
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            let x = (45 - angle) / 90 * 0.4
            RoundedRectangle(cornerRadius: 4)
                .fill(EllipticalGradient(colors: [.gray, .black], center: .center, startRadiusFraction: 0, endRadiusFraction: 1))
            BezierRectangle()
                .fill(RadialGradient(colors: [.init( white: 0.9, opacity: 1), .init( white: 0.4, opacity: 1)], center: .init(x: 0.3 + x, y: 0.7), startRadius: 0, endRadius: 124))
                .shadow(using: BezierRectangle(), angle: .degrees(angle), color: .gray)
        }
        .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

struct BezierRectangle: Shape {
    func path(in rect: CGRect) -> Path {
        let a = min(rect.width, rect.height) * 0.164
        let b = a * 0.32
        let c = rect.width - a
        let d = rect.height - a
        
        return Path { path in
            path.move(to: .init(x: a, y: a))
            
            path.addCurve(to: .init(x: c, y: a),
                          control1: .init(x: a + b, y: a - b),
                          control2: .init(x: c - b, y: a - b))
            path.addCurve(to: .init(x: c, y: d),
                          control1: .init(x: c + b, y: a + b),
                          control2: .init(x: c + b, y: d - b))
            path.addCurve(to: .init(x: a, y: d),
                          control1: .init(x: c - b, y: d + b),
                          control2: .init(x: a + b, y: d + b))
            path.addCurve(to: .init(x: a, y: a),
                          control1: .init(x: a - b, y: d - b),
                          control2: .init(x: a - b, y: a + b))
        }
    }
}

extension View {
    // https://www.hackingwithswift.com/plus/swiftui-special-effects/shadows-and-glows
    func shadow<S: Shape>(using shape: S, angle: Angle = .degrees(0), color: Color = .black, width: CGFloat = 4, blur: CGFloat = 6) -> some View {
        let x = CGFloat(cos(angle.radians - .pi / 2))
        let y = CGFloat(sin(angle.radians - .pi / 2))
        
        return self
            .overlay(shape
                .stroke(color, lineWidth: width)
                .offset(x: x * width * 0.6, y: y * width * 0.6)
                .blur(radius: blur)
                .mask(shape)
            )
    }
}
