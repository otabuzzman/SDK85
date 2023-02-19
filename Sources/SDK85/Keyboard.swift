import SwiftUI
import z80

struct Keyboard: View {
    @ObservedObject var intIO: IntIO

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private static let spacing: CGFloat = 2

    var body: some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact

        VStack(spacing: Keyboard.spacing) {
            ForEach(0..<Keyboard.layout.count, id: \.self) { row in
                HStack(spacing: Keyboard.spacing) {
                    ForEach(0..<Keyboard.layout[row].count, id: \.self) { col in
                        let keyConfiguration = Keyboard.layout[row][col]

                        Button(keyConfiguration.title) { // closure on button release
                            intIO.SID = keyConfiguration.code
                        }
                        .buttonStyle(Key(
                            subtitle1st: keyConfiguration.subtitle1st,
                            subtitle2nd: keyConfiguration.subtitle2nd))
                        .frame(maxWidth: isCompact ? 56 : 48, maxHeight: isCompact ? 56 : 48)
                        .rotationEffect(Angle(degrees: Keyboard.wiggles[row][col]))
                    }
                }
            }
        }
    }

    private typealias KeyConfiguration = (
        title: String, 
        subtitle1st: String?, 
        subtitle2nd: String?,
        code: Byte)

    private static let layout: [[KeyConfiguration]] = [
        [
            ("", "ESC", nil, 0x1B),
            ("", "!", "1", 0x31),
            ("", "@", "2", 0x32),
            ("", "#", "3", 0x33),
            ("", "$", "4", 0x34),
            ("", "%", "5", 0x35),
            ("", "^", "6", 0x36),
            ("", "&", "7", 0x37),
            ("", "*", "8", 0x38),
            ("", "(", "9", 0x39),
            ("", ")", "0", 0x30),
            ("", "_", "-", 0x2F),
            ("", "+", "=", 0x3D),
            ("", "~", "`", 0x60),
            ("", "BACK", "SPACE", 0x08)
        ],
        [
            ("", "TAB", nil, 0x09),
            ("Q", nil, nil, 0x51),
            ("W", nil, nil, 0x57),
            ("E", nil, nil, 0x45),
            ("R", nil, nil, 0x52),
            ("T", nil, nil, 0x54),
            ("Y", nil, nil, 0x59),
            ("U", nil, nil, 0x55),
            ("I", nil, nil, 0x49),
            ("O", nil, nil, 0x4F),
            ("P", nil, nil, 0x50),
            ("", "{", "[", 0x5B),
            ("", "}", "]", 0x5D)
        ],
        [
            ("", "CTRL", nil, 0xFF),
            ("", "CAPS", "LOCK", 0xFF),
            ("A", nil, nil, 0x41),
            ("S", nil, nil, 0x53),
            ("D", nil, nil, 0x44),
            ("F", nil, nil, 0x46),
            ("G", "BELL", nil, 0x47),
            ("H", nil, nil, 0x48),
            ("J", nil, nil, 0x4A),
            ("K", nil, nil, 0x4B),
            ("L", nil, nil, 0x4C),
            ("", ":", "\"", 0x5C),
            ("", "}", "'", 0x27),
            ("", "RETURN", nil, 0x0D),
            ("", "|", "\\", 0x5C)
        ],
        [
            ("", "SHIFT", nil, 0xFF),
            ("Z", nil, nil, 0x5A),
            ("X", nil, nil, 0x58),
            ("C", nil, nil, 0x43),
            ("V", nil, nil, 0x56),
            ("B", nil, nil, 0x42),
            ("", nil, nil, 0x20),
            ("N", nil, nil, 0x4E),
            ("M", nil, nil, 0x4D),
            ("", "<", ",", 0x2C),
            ("", ">", ".", 0x2E),
            ("", "?", "/", 0x2F),
            ("", "SHIFT", nil, 0xFF)
        ]
    ]

    private static let wiggles: [[CGFloat]] = {
        var wiggles = [[CGFloat]]()
        for row in 0..<layout.count {
            wiggles.append([CGFloat]())
            for _ in 0..<layout[row].count {
                wiggles[row].append(drand48() * spacing - spacing / 2)
            }
        }
        return wiggles
    }()
}

private struct Key: ButtonStyle {
    let subtitle1st: String?
    let subtitle2nd: String?

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            let buttonSize = min(geometry.size.width, geometry.size.height)

            ZStack {
                TriangledRectangle()
                    .border(.white)

                BarreledRectangle(barrelness: 0.12)
                    .fill(.white)
                    .scaleEffect(0.72)

                VStack {
                    configuration.label
                        .font(.system(size: buttonSize * 0.5))
                        .foregroundColor(Color(white: 0.24))

                    if let subtitle = subtitle1st {
                        Text(subtitle)
                            .font(.system(size: buttonSize * 0.15))
                            .offset(y: -buttonSize * 0.08)
                    }

                    if let subtitle = subtitle2nd {
                        Text(subtitle)
                            .font(.system(size: buttonSize * 0.15))
                            .offset(y: -buttonSize * 0.08)
                    }
                }
            }
            // https://swiftui-lab.com/geometryreader-bug/ (FB7971927)
            .frame(width: buttonSize, height: buttonSize, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
        }
    }
}
