import SwiftUI
import z80

struct Hexboard: View {
    @EnvironmentObject var circuitIO: CircuitIO

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private static let spacing: CGFloat = 2

    var body: some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact
        let keySize: CGFloat = isCompact ? 56 : 96

        VStack(spacing: Hexboard.spacing) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: Hexboard.spacing) {
                    ForEach(0..<6, id: \.self) { col in
                        let keyConfiguration = Hexboard.layout[row * 6 + col]

                        Button(keyConfiguration.title) { // closure on button release
                            switch keyConfiguration.code {
                            case 0xFF: // RESET
                                circuitIO.reset()
                            case 0xFE: // VECT INTR
                                i8155.data = 0xFF
                                i8155.INT = true // RST 7
                            default:
                                i8279.RL07.enqueue(keyConfiguration.code)
                                i8155.data = 0xEF
                                i8155.INT = true // RST 5
                            }
                            Sound.play(soundfile: "sdk85-keyprease.mp3")
                        }
                        .buttonStyle(Key(
                            keySize: keySize,
                            subtitle1st: keyConfiguration.subtitle1st,
                            subtitle2nd: keyConfiguration.subtitle2nd))
                        .frame(maxWidth: keySize, maxHeight: keySize)
                        .rotationEffect(Angle(degrees: Hexboard.wiggles[row * col]))
                        /*
                        // different sounds are difficult to distinguish if
                        // pressing and releasing follow each other quickly
                        .pressAction {
                            Sound.play(soundfile: "sdk85-keypress.mp3")
                        } onRelease: {
                            Sound.play(soundfile: "sdk85-keyrelease.mp3")
                        }
                        */
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

    private static let layout: [KeyConfiguration] = [
        ("", "RESET", nil, 0xFF), ("", "VECT", "INTR", 0xFE), ("C", nil, nil, 0x0C), ("D", nil, nil, 0x0D), ("E", nil, nil, 0x0E), ("F", nil, nil, 0x0F),
        ("", "SINGLE", "STEP", 0x15), ("", "GO", nil, 0x12), ("8", "H", nil, 0x08), ("9", "L", nil, 0x09), ("A", nil, nil, 0x0A), ("B", nil, nil, 0x0B),
        ("", "SUBST", "MEM", 0x13), ("", "EXAM", "REG", 0x14), ("4", "SPH", nil, 0x04), ("5", "SPL", nil, 0x05), ("6", "PCH", nil, 0x06), ("7", "PCL", nil, 0x07),
        ("", "NEXT", ",", 0x11), ("", "EXEC", ".", 0x10), ("0", nil, nil, 0x00), ("1", nil, nil, 0x01), ("2", nil, nil, 0x02), ("3", "I", nil, 0x03)
    ]

    private static let wiggles: [CGFloat] = {
        var wiggles = [CGFloat]()
        for _ in 1...layout.count {
            wiggles.append(drand48() * spacing - spacing / 2)
        }
        return wiggles
    }()
}

private struct Key: ButtonStyle {
    let keySize: CGFloat!
    let subtitle1st: String?
    let subtitle2nd: String?

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            TriangledRectangle()
                .border(.white)
            
            BarreledRectangle(barrelness: 0.12)
                .fill(.white)
                .scaleEffect(0.72)
            
            VStack {
                configuration.label
                    .font(.system(size: keySize * 0.5))
                    .foregroundColor(Color(white: 0.24))
                
                if let subtitle = subtitle1st {
                    Text(subtitle)
                        .font(.system(size: keySize * 0.15))
                        .offset(y: -keySize * 0.08)
                }
                
                if let subtitle = subtitle2nd {
                    Text(subtitle)
                        .font(.system(size: keySize * 0.15))
                        .offset(y: -keySize * 0.08)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}
